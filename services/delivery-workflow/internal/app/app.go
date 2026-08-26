package app

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	"github.com/cirius/delivery-workflow/internal/artifact"
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
	acceptedState, err := choose("Accepted")
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
		GitHub: config.GitHub{Repository: repository, Classification: config.Classification{Requirement: "Requirement", Specification: "Specification", Decision: "Decision", Task: "Task"}, Project: config.Project{
			Owner: owner, OwnerType: ownerType, Number: projectNumber, ID: projectID, StatusFieldID: fieldID, StatusField: statusField,
		}},
		States: config.States{Draft: draft, Accepted: acceptedState, Ready: ready, InProgress: inProgress, Archived: archived, ImplementationAccepted: accepted},
		Phase4: config.Phase4{AutoTransition: true},
	}
	if err := config.Save(path, cfg); err != nil {
		return err
	}
	fmt.Fprintf(output, "Wrote %s\n", path)
	return nil
}

func (a App) Draft(ctx context.Context, classification workflow.Classification, title, description string, artifacts, assignees []string) (int, error) {
	if classification != workflow.RequirementClassification {
		return 0, errors.New("dw draft supports only the requirement classification")
	}
	if len(artifacts) == 0 {
		return 0, errors.New("at least one artifact path is required")
	}
	assignees, err := requiredAssignees(assignees)
	if err != nil {
		return 0, err
	}
	if err := a.validateAssignees(ctx, assignees); err != nil {
		return 0, err
	}
	ticketURL, ticketNumber, found, _, err := a.artifactTicket(artifacts)
	if err != nil {
		return 0, err
	}
	if found {
		_, issueErr := a.GitHub.GetIssue(ctx, a.Config.GitHub.Repository, ticketNumber)
		if issueErr != nil {
			return 0, issueErr
		}
		if err := a.ensureAssignees(ctx, ticketNumber, ticketURL, assignees); err != nil {
			return 0, err
		}
		if err := a.writeArtifactTickets(artifacts, ticketURL); err != nil {
			return 0, err
		}
		return ticketNumber, nil
	}
	if title == "" {
		return 0, errors.New("issue title is required when creating a ticket")
	}
	number, ticketURL, err := a.createDraftTicket(ctx, title, description, artifacts, classification, assignees)
	if err != nil {
		return 0, err
	}
	if err := a.writeArtifactTickets(artifacts, ticketURL); err != nil {
		return 0, err
	}
	return number, nil
}

func (a App) Assignees(ctx context.Context) ([]string, error) {
	return a.GitHub.ListAssignees(ctx, a.Config.GitHub.Repository)
}

// Handoff creates or safely reuses the next documentation-phase ticket.
func (a App) Handoff(ctx context.Context, predecessor int, classification workflow.Classification, title, description string, artifacts, assignees []string) (int, error) {
	if predecessor < 1 {
		return 0, errors.New("root requirement issue is required")
	}
	phase := workflow.SpecsADRs
	if classification == workflow.TaskClassification {
		phase = workflow.TasksPlan
	}
	if classification != workflow.SpecificationClassification && classification != workflow.DecisionClassification && classification != workflow.TaskClassification {
		return 0, errors.New("dw handoff classification must be specification, decision, or task")
	}
	if phase != workflow.SpecsADRs && phase != workflow.TasksPlan {
		return 0, errors.New("dw handoff supports requirement-to-specs-adrs and specs-adrs-to-tasks-plan only")
	} else if len(artifacts) == 0 {
		return 0, errors.New("at least one artifact path is required")
	} else {
		assignees, err := requiredAssignees(assignees)
		if err != nil {
			return 0, err
		}
		if err := a.validateAssignees(ctx, assignees); err != nil {
			return 0, err
		}
		parent, err := a.GitHub.GetIssue(ctx, a.Config.GitHub.Repository, predecessor)
		if err != nil {
			return 0, err
		}
		if err := a.requireAccepted(ctx, predecessor, parent); err != nil {
			return 0, err
		}
		_, foundNumber, found, _, err := a.artifactTicket(artifacts)
		if err != nil {
			return 0, err
		}
		var child *github.Issue
		if found {
			issue, issueErr := a.GitHub.GetIssue(ctx, a.Config.GitHub.Repository, foundNumber)
			if issueErr != nil {
				return 0, issueErr
			}
			if child != nil && child.Number != foundNumber {
				return 0, fmt.Errorf("predecessor ticket #%d already links to ticket #%d", predecessor, child.Number)
			}
			actualParent, parentErr := a.GitHub.ParentIssueNumber(ctx, a.Config.GitHub.Repository, foundNumber)
			if parentErr != nil || actualParent != predecessor {
				return 0, fmt.Errorf("ticket #%d is not a native direct sub-issue of Requirement #%d", foundNumber, predecessor)
			}
			child = &issue
		}
		if child != nil {
			childURL, urlErr := a.canonicalTicketURL(child.Number)
			if urlErr != nil {
				return 0, urlErr
			}
			if err := a.ensureAssignees(ctx, child.Number, childURL, assignees); err != nil {
				return 0, err
			}
			if err := a.writeArtifactTickets(artifacts, childURL); err != nil {
				return 0, err
			}
			return child.Number, nil
		}
		if title == "" {
			return 0, errors.New("issue title is required when creating a handoff ticket")
		}
		number, ticketURL, err := a.createDraftTicket(ctx, title, description, artifacts, classification, assignees)
		if err != nil {
			return 0, err
		}
		parentID := parent.NodeID
		childID, err := a.GitHub.IssueNodeID(ctx, a.Config.GitHub.Repository, number)
		if err != nil {
			return 0, err
		}
		if err := a.GitHub.SetParentIssue(ctx, parentID, childID); err != nil {
			return 0, err
		}
		if err := a.writeArtifactTickets(artifacts, ticketURL); err != nil {
			return 0, err
		}
		return number, nil
	}
}

func requiredAssignees(values []string) ([]string, error) {
	if len(values) == 0 {
		return nil, errors.New("one to ten --assignee values are required")
	}
	assignees := make([]string, 0, len(values))
	seen := map[string]bool{}
	for _, value := range values {
		login := strings.TrimSpace(value)
		if login == "" {
			return nil, errors.New("--assignee must be a non-empty GitHub username")
		}
		key := strings.ToLower(login)
		if seen[key] {
			return nil, fmt.Errorf("--assignee contains duplicate GitHub username %q", login)
		}
		seen[key] = true
		assignees = append(assignees, login)
	}
	if len(assignees) > 10 {
		return nil, errors.New("GitHub supports at most 10 Issue assignees")
	}
	return assignees, nil
}

func (a App) validateAssignees(ctx context.Context, assignees []string) error {
	available, err := a.GitHub.ListAssignees(ctx, a.Config.GitHub.Repository)
	if err != nil {
		return err
	}
	if invalid := unavailableAssignees(assignees, available); len(invalid) != 0 {
		return fmt.Errorf("GitHub users cannot be assigned to this repository: %s", strings.Join(invalid, ", "))
	}
	return nil
}

func (a App) ensureAssignees(ctx context.Context, number int, ticketURL string, assignees []string) error {
	actual, err := a.GitHub.AddAssignees(ctx, a.Config.GitHub.Repository, number, assignees)
	if err != nil {
		return err
	}
	if missing := unavailableAssignees(assignees, actual); len(missing) != 0 {
		return fmt.Errorf("GitHub did not assign requested users to ticket %s: %s", ticketURL, strings.Join(missing, ", "))
	}
	return nil
}

func (a App) createDraftTicket(ctx context.Context, title, description string, artifacts []string, classification workflow.Classification, assignees []string) (int, string, error) {
	body, err := workflow.TicketBody(description, artifacts)
	if err != nil {
		return 0, "", err
	}
	var labels []string
	if a.Config.GitHub.Project.OwnerKind() == "user" {
		labels = []string{a.classificationName(classification)}
	}
	number, ticketURL, actualAssignees, err := a.GitHub.CreateIssue(ctx, a.Config.GitHub.Repository, title, body, assignees, labels)
	if err != nil {
		return 0, "", err
	}
	if missing := unavailableAssignees(assignees, actualAssignees); len(missing) != 0 {
		return 0, "", fmt.Errorf("GitHub did not assign requested users to ticket %s: %s", ticketURL, strings.Join(missing, ", "))
	}
	returnedTicketNumber, err := a.ticketNumber(ticketURL)
	if err != nil {
		return 0, "", fmt.Errorf("GitHub returned an invalid ticket URL: %w", err)
	}
	if returnedTicketNumber != number {
		return 0, "", errors.New("GitHub returned a ticket URL for a different issue")
	}
	nodeID, err := a.GitHub.IssueNodeID(ctx, a.Config.GitHub.Repository, number)
	if err != nil {
		return 0, "", err
	}
	itemID, err := a.GitHub.AddProjectItem(ctx, a.Config.GitHub.Project.ID, nodeID)
	if err != nil {
		return 0, "", err
	}
	if err := a.GitHub.UpdateStatus(ctx, a.Config, itemID, a.Config.States.Draft.ID); err != nil {
		return 0, "", err
	}
	if err := a.audit(ctx, number, workflow.AuditMarker(0, "draft")+"\nDraft ticket synchronized."); err != nil {
		return 0, "", err
	}
	return number, ticketURL, nil
}

func (a App) classificationName(value workflow.Classification) string {
	switch value {
	case workflow.RequirementClassification:
		return a.Config.GitHub.Classification.Requirement
	case workflow.SpecificationClassification:
		return a.Config.GitHub.Classification.Specification
	case workflow.DecisionClassification:
		return a.Config.GitHub.Classification.Decision
	case workflow.TaskClassification:
		return a.Config.GitHub.Classification.Task
	default:
		return ""
	}
}

func (a App) requireAccepted(ctx context.Context, number int, issue github.Issue) error {
	if issue.NodeID == "" {
		return fmt.Errorf("ticket #%d has no GitHub node ID", number)
	}
	item, err := a.GitHub.FindProjectItem(ctx, a.Config, issue.NodeID)
	if err != nil {
		return err
	}
	if item.StatusID != a.Config.States.Accepted.ID {
		return fmt.Errorf("requirement ticket #%d is not Accepted", number)
	}
	return nil
}

func unavailableAssignees(requested, available []string) []string {
	availableSet := map[string]bool{}
	for _, login := range available {
		availableSet[strings.ToLower(login)] = true
	}
	var missing []string
	for _, login := range requested {
		if !availableSet[strings.ToLower(login)] {
			missing = append(missing, login)
		}
	}
	return missing
}

func (a App) Start(ctx context.Context, issue int) error {
	ticket, err := a.GitHub.GetIssue(ctx, a.Config.GitHub.Repository, issue)
	if err != nil {
		return err
	}
	if len(github.IssueAssignees(ticket)) == 0 {
		return fmt.Errorf("ticket #%d has no builder assignee", issue)
	}
	if _, err := a.GitHub.ParentIssueNumber(ctx, a.Config.GitHub.Repository, issue); err != nil {
		return fmt.Errorf("task ticket #%d must be a native sub-issue of its Requirement: %w", issue, err)
	}
	if err := a.requireReady(ctx, issue, ticket); err != nil {
		return err
	}
	return a.moveIssue(ctx, issue, a.Config.States.Ready.Sources, a.Config.States.InProgress.ID, "start", 0)
}

func (a App) requireReady(ctx context.Context, number int, issue github.Issue) error {
	if issue.NodeID == "" {
		return fmt.Errorf("ticket #%d has no GitHub node ID", number)
	}
	item, err := a.GitHub.FindProjectItem(ctx, a.Config, issue.NodeID)
	if err != nil {
		return err
	}
	if item.StatusID != a.Config.States.Ready.ID {
		return fmt.Errorf("ticket #%d is not Ready", number)
	}
	return nil
}

func (a App) canonicalTicketURL(number int) (string, error) {
	owner, repository, err := a.Config.RepositoryParts()
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("https://github.com/%s/%s/issues/%d", owner, repository, number), nil
}

func (a App) Register(ctx context.Context, prNumber, issue int, phase workflow.Phase, artifacts []string) error {
	if !phase.Valid() {
		return fmt.Errorf("unknown workflow phase %q", phase)
	}
	if phase.Documentation() && len(artifacts) == 0 {
		return errors.New("artifact paths are required for phases 1-3")
	}
	var groups []workflow.TicketGroup
	requirement := issue
	if phase.Documentation() {
		byTicket := map[string][]string{}
		for _, path := range artifacts {
			ticket, found, err := artifact.Ticket(path)
			if err != nil {
				return err
			}
			if !found {
				return fmt.Errorf("artifact %q has no delivery.ticket", path)
			}
			byTicket[ticket] = append(byTicket[ticket], path)
		}
		for ticket, paths := range byTicket {
			number, err := a.ticketNumber(ticket)
			if err != nil {
				return err
			}
			classification := classificationForArtifact(paths[0])
			if phase == workflow.Requirement {
				requirement = number
				classification = workflow.RequirementClassification
			} else {
				parent, err := a.GitHub.ParentIssueNumber(ctx, a.Config.GitHub.Repository, number)
				if err != nil {
					return err
				}
				if requirement == 0 {
					requirement = parent
				}
				if parent != requirement {
					return errors.New("phase tickets do not share the same root Requirement")
				}
			}
			groups = append(groups, workflow.TicketGroup{TicketURL: ticket, TicketNumber: number, Classification: classification, Artifacts: paths})
		}
		sort.Slice(groups, func(i, j int) bool { return groups[i].TicketNumber < groups[j].TicketNumber })
	} else {
		if issue < 1 {
			return errors.New("--issue is required for implementation")
		}
		parent, err := a.GitHub.ParentIssueNumber(ctx, a.Config.GitHub.Repository, issue)
		if err != nil {
			return err
		}
		requirement = parent
		ticket, _ := a.canonicalTicketURL(issue)
		groups = []workflow.TicketGroup{{TicketURL: ticket, TicketNumber: issue, Classification: workflow.TaskClassification}}
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
		Version:           2,
		RequirementURL:    fmt.Sprintf("https://github.com/%s/%s/issues/%d", owner, repository, requirement),
		RequirementNumber: requirement,
		Phase:             phase,
		Groups:            groups,
		AcceptanceBranch:  a.Config.AcceptanceBranch,
	}
	body, err := workflow.Upsert(pr.Body, review)
	if err != nil {
		return err
	}
	if err := a.GitHub.UpdatePullRequestBody(ctx, a.Config.GitHub.Repository, prNumber, body); err != nil {
		return err
	}
	return a.audit(ctx, requirement, workflow.AuditMarker(prNumber, "registered")+fmt.Sprintf("\nPhase review set registered for PR #%d.", prNumber))
}

func classificationForArtifact(path string) workflow.Classification {
	path = filepath.ToSlash(path)
	switch {
	case strings.Contains(path, "/specifications/"):
		return workflow.SpecificationClassification
	case strings.Contains(path, "/decisions/"):
		return workflow.DecisionClassification
	case strings.Contains(path, "/tasks/") || strings.Contains(path, "/implementation-plan/"):
		return workflow.TaskClassification
	default:
		return workflow.RequirementClassification
	}
}

func (a App) artifactTicket(paths []string) (ticketURL string, ticketNumber int, found, complete bool, err error) {
	complete = true
	for _, path := range paths {
		url, present, readErr := artifact.Ticket(path)
		if readErr != nil {
			return "", 0, false, false, readErr
		}
		if !present {
			complete = false
			continue
		}
		number, parseErr := a.ticketNumber(url)
		if parseErr != nil {
			return "", 0, false, false, fmt.Errorf("artifact %q: %w", path, parseErr)
		}
		if found && url != ticketURL {
			return "", 0, false, false, errors.New("review artifacts use different delivery.ticket URLs")
		}
		ticketURL, ticketNumber, found = url, number, true
	}
	return ticketURL, ticketNumber, found, complete, nil
}

func (a App) writeArtifactTickets(paths []string, ticketURL string) error {
	for _, path := range paths {
		if err := artifact.WriteTicket(path, ticketURL); err != nil {
			return err
		}
	}
	return nil
}

func (a App) ticketNumber(ticketURL string) (int, error) {
	parsed, err := url.Parse(ticketURL)
	if err != nil {
		return 0, fmt.Errorf("parse delivery.ticket URL: %w", err)
	}
	if parsed.Scheme != "https" || parsed.Host != "github.com" || parsed.RawQuery != "" || parsed.Fragment != "" {
		return 0, errors.New("delivery.ticket must be a canonical GitHub issue URL")
	}
	owner, repository, err := a.Config.RepositoryParts()
	if err != nil {
		return 0, err
	}
	prefix := "/" + owner + "/" + repository + "/issues/"
	if !strings.HasPrefix(parsed.Path, prefix) || strings.Contains(strings.TrimPrefix(parsed.Path, prefix), "/") {
		return 0, errors.New("delivery.ticket does not identify an issue in the configured repository")
	}
	number, err := strconv.Atoi(strings.TrimPrefix(parsed.Path, prefix))
	if err != nil || number < 1 {
		return 0, errors.New("delivery.ticket must end with a positive issue number")
	}
	return number, nil
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
		target := a.Config.States.Accepted.ID
		if review.Phase == workflow.TasksPlan {
			target = a.Config.States.Ready.ID
		}
		for _, group := range review.Groups {
			if err := a.moveIssue(ctx, group.TicketNumber, a.Config.States.Draft.Sources, target, "accepted", prNumber); err != nil {
				return err
			}
		}
		var evidence strings.Builder
		fmt.Fprintf(&evidence, "%s\nPhase: %s\nAccepted PR: #%d\n", workflow.AuditMarker(prNumber, "phase-accepted"), review.Phase, prNumber)
		for _, group := range review.Groups {
			fmt.Fprintf(&evidence, "- Ticket #%d (%s): %s\n", group.TicketNumber, group.Classification, strings.Join(group.Artifacts, ", "))
		}
		return a.audit(ctx, review.RequirementNumber, strings.TrimRight(evidence.String(), "\n"))
	}
	if !a.Config.Phase4.AutoTransition {
		return nil
	}
	return a.moveIssue(ctx, review.Groups[0].TicketNumber, a.Config.States.InProgress.Sources, a.Config.States.ImplementationAccepted.ID, "implementation-accepted", prNumber)
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
	for _, group := range review.Groups {
		if err := a.moveIssue(ctx, group.TicketNumber, a.Config.States.Draft.Sources, a.Config.States.Archived.ID, "rejected", prNumber, "\nReason: "+reason); err != nil {
			return err
		}
	}
	return nil
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
