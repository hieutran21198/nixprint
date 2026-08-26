package github

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"sort"
	"strings"

	"github.com/cirius/delivery-workflow/internal/config"
)

type Client struct {
	baseURL string
	token   string
	http    *http.Client
}

type StatusOption struct {
	ID   string
	Name string
}

type PullRequest struct {
	Number int    `json:"number"`
	Body   string `json:"body"`
	Merged bool   `json:"merged"`
	Base   struct {
		Ref string `json:"ref"`
	} `json:"base"`
}

type ProjectItem struct {
	ID       string
	StatusID string
}

// Issue contains the GitHub Issue fields used by the delivery workflow.
type Issue struct {
	Number    int    `json:"number"`
	NodeID    string `json:"node_id"`
	HTMLURL   string `json:"html_url"`
	Body      string `json:"body"`
	Assignees []struct {
		Login string `json:"login"`
	} `json:"assignees"`
}

func New(token string) (*Client, error) {
	if token == "" {
		var err error
		token, err = TokenFromEnvironment()
		if err != nil {
			return nil, err
		}
	}
	baseURL := os.Getenv("GITHUB_API_URL")
	if baseURL == "" {
		baseURL = "https://api.github.com"
	}
	return NewWithBaseURL(token, baseURL, http.DefaultClient), nil
}

// NewWithBaseURL creates a client for a GitHub API endpoint. It supports
// GitHub Enterprise Server and local contract tests.
func NewWithBaseURL(token, baseURL string, httpClient *http.Client) *Client {
	if httpClient == nil {
		httpClient = http.DefaultClient
	}
	return &Client{baseURL: strings.TrimRight(baseURL, "/"), token: token, http: httpClient}
}

func TokenFromEnvironment() (string, error) {
	for _, key := range []string{"DW_GITHUB_TOKEN", "GH_TOKEN", "GITHUB_TOKEN"} {
		if token := strings.TrimSpace(os.Getenv(key)); token != "" {
			return token, nil
		}
	}
	output, err := exec.Command("gh", "auth", "token").Output()
	if err != nil {
		return "", fmt.Errorf("set DW_GITHUB_TOKEN or authenticate with gh: %w", err)
	}
	if token := strings.TrimSpace(string(output)); token != "" {
		return token, nil
	}
	return "", fmt.Errorf("GitHub token is empty")
}

func (c *Client) request(ctx context.Context, method, path string, input, output any) error {
	var body io.Reader
	if input != nil {
		data, err := json.Marshal(input)
		if err != nil {
			return err
		}
		body = bytes.NewReader(data)
	}
	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, body)
	if err != nil {
		return err
	}
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("Authorization", "Bearer "+c.token)
	req.Header.Set("X-GitHub-Api-Version", "2022-11-28")
	if input != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	response, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode > 299 {
		data, _ := io.ReadAll(io.LimitReader(response.Body, 4096))
		return fmt.Errorf("GitHub %s %s: %s: %s", method, path, response.Status, strings.TrimSpace(string(data)))
	}
	if output == nil {
		return nil
	}
	return json.NewDecoder(response.Body).Decode(output)
}

func (c *Client) graphql(ctx context.Context, query string, variables map[string]any, output any) error {
	var response struct {
		Data   json.RawMessage `json:"data"`
		Errors []struct {
			Message string `json:"message"`
		} `json:"errors"`
	}
	if err := c.request(ctx, http.MethodPost, "/graphql", map[string]any{"query": query, "variables": variables}, &response); err != nil {
		return err
	}
	if len(response.Errors) != 0 {
		return fmt.Errorf("GitHub GraphQL: %s", response.Errors[0].Message)
	}
	if err := json.Unmarshal(response.Data, output); err != nil {
		return fmt.Errorf("decode GitHub GraphQL response: %w", err)
	}
	return nil
}

func (c *Client) DiscoverProject(ctx context.Context, ownerType, owner string, number int, statusField string) (string, string, []StatusOption, error) {
	root := "organization"
	if ownerType == "user" {
		root = "user"
	} else if ownerType != "organization" {
		return "", "", nil, fmt.Errorf("GitHub Project owner type %q is not supported", ownerType)
	}
	query := fmt.Sprintf(`query($owner: String!, $number: Int!) {
  owner: %s(login: $owner) { projectV2(number: $number) { id fields(first: 100) {
    nodes { ... on ProjectV2SingleSelectField { id name options { id name } } }
  } } }
}`, root)
	var result struct {
		Owner struct {
			Project struct {
				ID     string `json:"id"`
				Fields struct {
					Nodes []struct {
						ID      string         `json:"id"`
						Name    string         `json:"name"`
						Options []StatusOption `json:"options"`
					} `json:"nodes"`
				} `json:"fields"`
			} `json:"projectV2"`
		} `json:"owner"`
	}
	if err := c.graphql(ctx, query, map[string]any{"owner": owner, "number": number}, &result); err != nil {
		return "", "", nil, err
	}
	if result.Owner.Project.ID == "" {
		return "", "", nil, fmt.Errorf("GitHub %s Project %s/%d was not found", ownerType, owner, number)
	}
	for _, field := range result.Owner.Project.Fields.Nodes {
		if field.Name == statusField {
			return result.Owner.Project.ID, field.ID, field.Options, nil
		}
	}
	return "", "", nil, fmt.Errorf("Project status field %q was not found", statusField)
}

func (c *Client) CreateIssue(ctx context.Context, repository, title, body string, assignees, labels []string) (int, string, []string, error) {
	input := map[string]any{"title": title, "body": body}
	if len(assignees) != 0 {
		input["assignees"] = assignees
	}
	if len(labels) != 0 {
		input["labels"] = labels
	}
	var result Issue
	if err := c.request(ctx, http.MethodPost, "/repos/"+repository+"/issues", input, &result); err != nil {
		return 0, "", nil, err
	}
	return result.Number, result.HTMLURL, IssueAssignees(result), nil
}

// GetIssue reads a ticket and its GitHub Issue collaborators.
func (c *Client) GetIssue(ctx context.Context, repository string, number int) (Issue, error) {
	var result Issue
	path := fmt.Sprintf("/repos/%s/issues/%d", repository, number)
	if err := c.request(ctx, http.MethodGet, path, nil, &result); err != nil {
		return Issue{}, err
	}
	return result, nil
}

// ListIssues reads all repository Issues. GitHub pull-request items are also
// returned by this endpoint; callers must ignore records that do not contain a
// delivery ticket record.
func (c *Client) ListIssues(ctx context.Context, repository string) ([]Issue, error) {
	var issues []Issue
	for page := 1; ; page++ {
		var results []Issue
		path := fmt.Sprintf("/repos/%s/issues?state=all&per_page=100&page=%d", repository, page)
		if err := c.request(ctx, http.MethodGet, path, nil, &results); err != nil {
			return nil, err
		}
		issues = append(issues, results...)
		if len(results) < 100 {
			return issues, nil
		}
	}
}

// ListAssignees returns every GitHub user that can be assigned to an Issue in
// the configured repository.
func (c *Client) ListAssignees(ctx context.Context, repository string) ([]string, error) {
	assignees := map[string]string{}
	for page := 1; ; page++ {
		var results []struct {
			Login string `json:"login"`
		}
		path := fmt.Sprintf("/repos/%s/assignees?per_page=100&page=%d", repository, page)
		if err := c.request(ctx, http.MethodGet, path, nil, &results); err != nil {
			return nil, err
		}
		for _, result := range results {
			if result.Login != "" {
				assignees[strings.ToLower(result.Login)] = result.Login
			}
		}
		if len(results) < 100 {
			break
		}
	}
	values := make([]string, 0, len(assignees))
	for _, login := range assignees {
		values = append(values, login)
	}
	sort.Slice(values, func(left, right int) bool {
		return strings.ToLower(values[left]) < strings.ToLower(values[right])
	})
	return values, nil
}

// AddAssignees adds users to an Issue without removing existing assignees.
func (c *Client) AddAssignees(ctx context.Context, repository string, number int, assignees []string) ([]string, error) {
	var result Issue
	path := fmt.Sprintf("/repos/%s/issues/%d/assignees", repository, number)
	if err := c.request(ctx, http.MethodPost, path, map[string]any{"assignees": assignees}, &result); err != nil {
		return nil, err
	}
	return IssueAssignees(result), nil
}

func IssueAssignees(value Issue) []string {
	assignees := make([]string, 0, len(value.Assignees))
	for _, assignee := range value.Assignees {
		if assignee.Login != "" {
			assignees = append(assignees, assignee.Login)
		}
	}
	return assignees
}

func (c *Client) IssueNodeID(ctx context.Context, repository string, number int) (string, error) {
	issue, err := c.GetIssue(ctx, repository, number)
	if err != nil {
		return "", err
	}
	return issue.NodeID, nil
}

func (c *Client) GetPullRequest(ctx context.Context, repository string, number int) (PullRequest, error) {
	var pr PullRequest
	if err := c.request(ctx, http.MethodGet, fmt.Sprintf("/repos/%s/pulls/%d", repository, number), nil, &pr); err != nil {
		return PullRequest{}, err
	}
	return pr, nil
}

func (c *Client) UpdatePullRequestBody(ctx context.Context, repository string, number int, body string) error {
	return c.request(ctx, http.MethodPatch, fmt.Sprintf("/repos/%s/pulls/%d", repository, number), map[string]string{"body": body}, nil)
}

func (c *Client) AddIssueComment(ctx context.Context, repository string, number int, body string) error {
	return c.request(ctx, http.MethodPost, fmt.Sprintf("/repos/%s/issues/%d/comments", repository, number), map[string]string{"body": body}, nil)
}

// ParentIssueNumber returns the native direct parent of an Issue.
func (c *Client) ParentIssueNumber(ctx context.Context, repository string, number int) (int, error) {
	owner, name, ok := strings.Cut(repository, "/")
	if !ok {
		return 0, fmt.Errorf("repository must be owner/repository")
	}
	query := `query($owner:String!,$name:String!,$number:Int!){repository(owner:$owner,name:$name){issue(number:$number){parent{number}}}}`
	var result struct {
		Repository struct {
			Issue struct {
				Parent *struct {
					Number int `json:"number"`
				} `json:"parent"`
			} `json:"issue"`
		} `json:"repository"`
	}
	if err := c.graphql(ctx, query, map[string]any{"owner": owner, "name": name, "number": number}, &result); err != nil {
		return 0, err
	}
	if result.Repository.Issue.Parent == nil {
		return 0, fmt.Errorf("ticket #%d has no native parent Issue", number)
	}
	return result.Repository.Issue.Parent.Number, nil
}

// SetParentIssue creates the native direct sub-issue relationship.
func (c *Client) SetParentIssue(ctx context.Context, parentID, childID string) error {
	query := `mutation($parent:ID!,$child:ID!){addSubIssue(input:{issueId:$parent,subIssueId:$child}){issue{id}}}`
	var result any
	return c.graphql(ctx, query, map[string]any{"parent": parentID, "child": childID}, &result)
}

func (c *Client) AddProjectItem(ctx context.Context, projectID, contentID string) (string, error) {
	const query = `mutation($project: ID!, $content: ID!) { addProjectV2ItemById(input: {projectId: $project contentId: $content}) { item { id } } }`
	var result struct {
		Add struct {
			Item struct {
				ID string `json:"id"`
			} `json:"item"`
		} `json:"addProjectV2ItemById"`
	}
	if err := c.graphql(ctx, query, map[string]any{"project": projectID, "content": contentID}, &result); err != nil {
		return "", err
	}
	return result.Add.Item.ID, nil
}

func (c *Client) FindProjectItem(ctx context.Context, cfg config.Config, issueNodeID string) (ProjectItem, error) {
	const query = `query($project: ID!, $cursor: String) { node(id: $project) { ... on ProjectV2 { items(first: 100, after: $cursor) { nodes { id content { ... on Issue { id } } fieldValues(first: 100) { nodes { ... on ProjectV2ItemFieldSingleSelectValue { optionId field { ... on ProjectV2FieldCommon { id } } } } } } pageInfo { hasNextPage endCursor } } } } }`
	cursor := any(nil)
	for {
		var result struct {
			Node struct {
				Items struct {
					Nodes []struct {
						ID      string `json:"id"`
						Content struct {
							ID string `json:"id"`
						} `json:"content"`
						FieldValues struct {
							Nodes []struct {
								OptionID string `json:"optionId"`
								Field    struct {
									ID string `json:"id"`
								} `json:"field"`
							} `json:"nodes"`
						} `json:"fieldValues"`
					} `json:"nodes"`
					PageInfo struct {
						HasNextPage bool   `json:"hasNextPage"`
						EndCursor   string `json:"endCursor"`
					} `json:"pageInfo"`
				} `json:"items"`
			} `json:"node"`
		}
		if err := c.graphql(ctx, query, map[string]any{"project": cfg.GitHub.Project.ID, "cursor": cursor}, &result); err != nil {
			return ProjectItem{}, err
		}
		for _, item := range result.Node.Items.Nodes {
			if item.Content.ID != issueNodeID {
				continue
			}
			for _, value := range item.FieldValues.Nodes {
				if value.Field.ID == cfg.GitHub.Project.StatusFieldID {
					return ProjectItem{ID: item.ID, StatusID: value.OptionID}, nil
				}
			}
			return ProjectItem{ID: item.ID}, nil
		}
		if !result.Node.Items.PageInfo.HasNextPage {
			break
		}
		cursor = result.Node.Items.PageInfo.EndCursor
	}
	return ProjectItem{}, fmt.Errorf("issue is not in configured GitHub Project")
}

func (c *Client) UpdateStatus(ctx context.Context, cfg config.Config, itemID, optionID string) error {
	const query = `mutation($project: ID!, $item: ID!, $field: ID!, $option: String!) { updateProjectV2ItemFieldValue(input: { projectId: $project itemId: $item fieldId: $field value: { singleSelectOptionId: $option } }) { projectV2Item { id } } }`
	return c.graphql(ctx, query, map[string]any{"project": cfg.GitHub.Project.ID, "item": itemID, "field": cfg.GitHub.Project.StatusFieldID, "option": optionID}, &struct{}{})
}

func (c *Client) CurrentUser(ctx context.Context) (string, error) {
	var user struct {
		Login string `json:"login"`
	}
	if err := c.request(ctx, http.MethodGet, "/user", nil, &user); err != nil {
		return "", err
	}
	return user.Login, nil
}

func (c *Client) IsTeamMember(ctx context.Context, organization, team, user string) (bool, error) {
	path := fmt.Sprintf("/orgs/%s/teams/%s/memberships/%s", url.PathEscape(organization), url.PathEscape(team), url.PathEscape(user))
	var membership struct {
		State string `json:"state"`
	}
	err := c.request(ctx, http.MethodGet, path, nil, &membership)
	if err != nil {
		if strings.Contains(err.Error(), "404") {
			return false, nil
		}
		return false, err
	}
	return membership.State == "active", nil
}

func (c *Client) ListPullRequests(ctx context.Context, repository, branch string) ([]PullRequest, error) {
	path := "/repos/" + repository + "/pulls?state=closed&base=" + url.QueryEscape(branch) + "&per_page=100"
	var prs []PullRequest
	if err := c.request(ctx, http.MethodGet, path, nil, &prs); err != nil {
		return nil, err
	}
	return prs, nil
}
