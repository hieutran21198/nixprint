package app

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"sort"
	"strconv"
	"strings"

	"github.com/cirius/delivery-workflow/internal/config"
	"github.com/cirius/delivery-workflow/internal/github"
	"github.com/cirius/delivery-workflow/internal/workflow"
)

type App struct {
	Config config.Config
	GitHub *github.Client
}

func Init(ctx context.Context, client *github.Client, path, repository, ownerType, owner string, projectNumber int, branch, statusField string, input io.Reader, output io.Writer) error {
	projectID, fieldID, options, err := client.DiscoverProject(ctx, ownerType, owner, projectNumber, statusField)
	if err != nil {
		return err
	}
	if len(options) == 0 {
		return errors.New("GitHub Project status field has no options")
	}
	fmt.Fprintln(output, "GitHub Project status options:")
	for index, option := range options {
		fmt.Fprintf(output, "  %d. %s\n", index+1, option.Name)
	}
	reader := bufio.NewReader(input)
	choose := func(semantic string) (config.State, error) {
		fmt.Fprintf(output, "Select the Project status for %s: ", semantic)
		line, readErr := reader.ReadString('\n')
		if readErr != nil && !errors.Is(readErr, io.EOF) {
			return config.State{}, readErr
		}
		index, parseErr := strconv.Atoi(strings.TrimSpace(line))
		if parseErr != nil || index < 1 || index > len(options) {
			return config.State{}, fmt.Errorf("select a number from 1 to %d", len(options))
		}
		option := options[index-1]
		return config.State{ID: option.ID, Name: option.Name, Sources: []string{option.ID}}, nil
	}
	draft, err := choose("Draft")
	if err != nil {
		return err
	}
	ready, err := choose("Ready")
	if err != nil {
		return err
	}
	inProgress, err := choose("In Progress")
	if err != nil {
		return err
	}
	archived, err := choose("Archived")
	if err != nil {
		return err
	}
	accepted, err := choose("implementation acceptance")
	if err != nil {
		return err
	}
	cfg := config.Config{
		Version:          config.Version,
		AcceptanceBranch: branch,
		GitHub: config.GitHub{Repository: repository, Project: config.Project{
			Owner: owner, OwnerType: ownerType, Number: projectNumber, ID: projectID, StatusFieldID: fieldID, StatusField: statusField,
		}},
		States: config.States{Draft: draft, Ready: ready, InProgress: inProgress, Archived: archived, ImplementationAccepted: accepted},
	}
	if err := config.Save(path, cfg); err != nil {
		return err
	}
	fmt.Fprintf(output, "Wrote %s\n", path)
	return nil
}

func (a App) Draft(ctx context.Context, phase workflow.Phase, title string, artifacts []string) (int, error) {
	if !phase.Documentation() {
		return 0, errors.New("dw draft supports phases 1-3 only")
	}
	if title == "" {
		return 0, errors.New("issue title is required")
	}
	if len(artifacts) == 0 {
		return 0, errors.New("at least one artifact path is required")
	}
	body := fmt.Sprintf("<!-- dw:ticket\nversion: 1\nphase: %s\nartifacts:\n", phase)
	for _, artifact := range artifacts {
		body += "  - " + artifact + "\n"
	}
	body += "-->\n\nThis ticket tracks an Artifact-Driven Development review unit."
	number, _, err := a.GitHub.CreateIssue(ctx, a.Config.GitHub.Repository, title, body)
	if err != nil {
		return 0, err
	}
	nodeID, err := a.GitHub.IssueNodeID(ctx, a.Config.GitHub.Repository, number)
	if err != nil {
		return 0, err
	}
	itemID, err := a.GitHub.AddProjectItem(ctx, a.Config.GitHub.Project.ID, nodeID)
	if err != nil {
		return 0, err
	}
	if err := a.GitHub.UpdateStatus(ctx, a.Config, itemID, a.Config.States.Draft.ID); err != nil {
		return 0, err
	}
	if err := a.audit(ctx, number, workflow.AuditMarker(0, "draft")+"\nDraft ticket synchronized."); err != nil {
		return 0, err
	}
	return number, nil
}

func (a App) Start(ctx context.Context, issue int) error {
	return a.moveIssue(ctx, issue, a.Config.States.Ready.Sources, a.Config.States.InProgress.ID, "start", 0)
}

func (a App) Register(ctx context.Context, prNumber, issue int, phase workflow.Phase, artifacts []string) error {
	if !phase.Valid() {
		return fmt.Errorf("unknown workflow phase %q", phase)
	}
	if phase.Documentation() && len(artifacts) == 0 {
		return errors.New("artifact paths are required for phases 1-3")
	}
	pr, err := a.GitHub.GetPullRequest(ctx, a.Config.GitHub.Repository, prNumber)
	if err != nil {
		return err
	}
	if pr.Base.Ref != a.Config.AcceptanceBranch {
		return fmt.Errorf("PR base branch %q is not acceptance branch %q", pr.Base.Ref, a.Config.AcceptanceBranch)
	}
	owner, repository, err := a.Config.RepositoryParts()
	if err != nil {
		return err
	}
	review := workflow.ReviewUnit{
		Version:          1,
		TicketURL:        fmt.Sprintf("https://github.com/%s/%s/issues/%d", owner, repository, issue),
		TicketNumber:     issue,
		Phase:            phase,
		Artifacts:        artifacts,
		AcceptanceBranch: a.Config.AcceptanceBranch,
	}
	body, err := workflow.Upsert(pr.Body, review)
	if err != nil {
		return err
	}
	if err := a.GitHub.UpdatePullRequestBody(ctx, a.Config.GitHub.Repository, prNumber, body); err != nil {
		return err
	}
	return a.audit(ctx, issue, workflow.AuditMarker(prNumber, "registered")+fmt.Sprintf("\nReview unit registered for PR #%d.", prNumber))
}

func (a App) Validate(ctx context.Context, prNumber int) error {
	pr, err := a.GitHub.GetPullRequest(ctx, a.Config.GitHub.Repository, prNumber)
	if err != nil {
		return err
	}
	review, err := workflow.Parse(pr.Body)
	if err != nil {
		return err
	}
	if review.AcceptanceBranch != a.Config.AcceptanceBranch || pr.Base.Ref != a.Config.AcceptanceBranch {
		return fmt.Errorf("review unit does not target configured acceptance branch %q", a.Config.AcceptanceBranch)
	}
	return nil
}

func (a App) Transition(ctx context.Context, prNumber int) error {
	pr, err := a.GitHub.GetPullRequest(ctx, a.Config.GitHub.Repository, prNumber)
	if err != nil {
		return err
	}
	if !pr.Merged || pr.Base.Ref != a.Config.AcceptanceBranch {
		return nil
	}
	review, err := workflow.Parse(pr.Body)
	if err != nil {
		return err
	}
	if review.AcceptanceBranch != a.Config.AcceptanceBranch {
		return fmt.Errorf("review unit targets %q, not configured acceptance branch", review.AcceptanceBranch)
	}
	if review.Phase.Documentation() {
		return a.moveIssue(ctx, review.TicketNumber, a.Config.States.Draft.Sources, a.Config.States.Ready.ID, "accepted", prNumber)
	}
	return a.moveIssue(ctx, review.TicketNumber, a.Config.States.InProgress.Sources, a.Config.States.ImplementationAccepted.ID, "implementation-accepted", prNumber)
}

func (a App) Reject(ctx context.Context, prNumber int, reason string) error {
	if len(a.Config.AuthorizerTeams) == 0 && len(a.Config.AuthorizerUsers) == 0 {
		return errors.New("authorizer_teams or authorizer_users must contain an authorized actor")
	}
	pr, err := a.GitHub.GetPullRequest(ctx, a.Config.GitHub.Repository, prNumber)
	if err != nil {
		return err
	}
	review, err := workflow.Parse(pr.Body)
	if err != nil {
		return err
	}
	if !review.Phase.Documentation() {
		return errors.New("an implementation PR remains In Progress; it cannot be archived")
	}
	user, err := a.GitHub.CurrentUser(ctx)
	if err != nil {
		return err
	}
	authorized := contains(a.Config.AuthorizerUsers, user)
	if a.Config.GitHub.Project.OwnerKind() == "organization" {
		for _, team := range a.Config.AuthorizerTeams {
			member, memberErr := a.GitHub.IsTeamMember(ctx, a.Config.GitHub.Project.Owner, team, user)
			if memberErr != nil {
				return memberErr
			}
			authorized = authorized || member
		}
	}
	if !authorized {
		return fmt.Errorf("GitHub user %q is not in an authorized rejection team", user)
	}
	if strings.TrimSpace(reason) == "" {
		return errors.New("rejection reason is required")
	}
	return a.moveIssue(ctx, review.TicketNumber, a.Config.States.Draft.Sources, a.Config.States.Archived.ID, "rejected", prNumber, "\nReason: "+reason)
}

func (a App) Reconcile(ctx context.Context) error {
	prs, err := a.GitHub.ListPullRequests(ctx, a.Config.GitHub.Repository, a.Config.AcceptanceBranch)
	if err != nil {
		return err
	}
	var failures []string
	for _, pr := range prs {
		if !pr.Merged {
			continue
		}
		if _, parseErr := workflow.Parse(pr.Body); parseErr != nil {
			continue
		}
		if transitionErr := a.Transition(ctx, pr.Number); transitionErr != nil {
			failures = append(failures, fmt.Sprintf("PR #%d: %v", pr.Number, transitionErr))
		}
	}
	if len(failures) != 0 {
		sort.Strings(failures)
		return errors.New(strings.Join(failures, "; "))
	}
	return nil
}

func (a App) TransitionEvent(ctx context.Context, eventPath string) error {
	data, err := os.ReadFile(eventPath)
	if err != nil {
		return err
	}
	var event struct {
		PullRequest struct {
			Number int `json:"number"`
		} `json:"pull_request"`
	}
	if err := json.Unmarshal(data, &event); err != nil {
		return fmt.Errorf("parse GitHub event: %w", err)
	}
	if event.PullRequest.Number < 1 {
		return errors.New("GitHub event has no pull request number")
	}
	return a.Transition(ctx, event.PullRequest.Number)
}

func (a App) moveIssue(ctx context.Context, issue int, sources []string, target, outcome string, prNumber int, suffix ...string) error {
	nodeID, err := a.GitHub.IssueNodeID(ctx, a.Config.GitHub.Repository, issue)
	if err != nil {
		return err
	}
	item, err := a.GitHub.FindProjectItem(ctx, a.Config, nodeID)
	if err != nil {
		return err
	}
	if item.StatusID == target {
		return nil
	}
	if !contains(sources, item.StatusID) {
		return fmt.Errorf("ticket #%d has unexpected Project status", issue)
	}
	if err := a.GitHub.UpdateStatus(ctx, a.Config, item.ID, target); err != nil {
		return err
	}
	body := workflow.AuditMarker(prNumber, outcome) + "\nTicket transition applied."
	if len(suffix) != 0 {
		body += suffix[0]
	}
	return a.audit(ctx, issue, body)
}

func (a App) audit(ctx context.Context, issue int, body string) error {
	return a.GitHub.AddIssueComment(ctx, a.Config.GitHub.Repository, issue, body)
}

func contains(values []string, value string) bool {
	for _, candidate := range values {
		if candidate == value {
			return true
		}
	}
	return false
}
