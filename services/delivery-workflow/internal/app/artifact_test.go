package app

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/cirius/delivery-workflow/internal/artifact"
	"github.com/cirius/delivery-workflow/internal/config"
	"github.com/cirius/delivery-workflow/internal/github"
	"github.com/cirius/delivery-workflow/internal/workflow"
)

func TestArtifactTicketRequiresOneConfiguredRepositoryTicket(t *testing.T) {
	directory := t.TempDir()
	first := filepath.Join(directory, "first.md")
	second := filepath.Join(directory, "second.md")
	for _, path := range []string{first, second} {
		if err := os.WriteFile(path, []byte("# Artifact\n"), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	url := "https://github.com/example/repository/issues/17"
	if err := artifact.WriteTicket(first, url); err != nil {
		t.Fatal(err)
	}
	service := App{Config: config.Config{GitHub: config.GitHub{Repository: "example/repository"}}}
	ticket, number, found, complete, err := service.artifactTicket([]string{first, second})
	if err != nil {
		t.Fatal(err)
	}
	if ticket != url || number != 17 || !found || complete {
		t.Fatalf("artifactTicket() = %q, %d, %t, %t", ticket, number, found, complete)
	}
	if err := artifact.WriteTicket(second, url); err != nil {
		t.Fatal(err)
	}
	_, _, _, complete, err = service.artifactTicket([]string{first, second})
	if err != nil || !complete {
		t.Fatalf("artifactTicket() complete = %t, err = %v", complete, err)
	}
}

func TestDraftReusesArtifactTicketAndCompletesCorrelation(t *testing.T) {
	directory := t.TempDir()
	first := filepath.Join(directory, "first.md")
	second := filepath.Join(directory, "second.md")
	for _, path := range []string{first, second} {
		if err := os.WriteFile(path, []byte("# Artifact\n"), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	url := "https://github.com/example/repository/issues/17"
	if err := artifact.WriteTicket(first, url); err != nil {
		t.Fatal(err)
	}
	body, err := workflow.TicketBody("Define the requirement.", []string{first, second})
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		switch request.URL.Path {
		case "/repos/example/repository/assignees":
			_ = json.NewEncoder(writer).Encode([]map[string]string{{"login": "owner"}})
		case "/repos/example/repository/issues/17":
			_ = json.NewEncoder(writer).Encode(map[string]any{"body": body})
		case "/repos/example/repository/issues/17/assignees":
			_ = json.NewEncoder(writer).Encode(map[string]any{"assignees": []map[string]string{{"login": "owner"}}})
		default:
			t.Fatalf("unexpected request: %s %s", request.Method, request.URL.Path)
		}
	}))
	defer server.Close()
	service := App{Config: config.Config{GitHub: config.GitHub{Repository: "example/repository"}}, GitHub: github.NewWithBaseURL("token", server.URL, server.Client())}
	number, err := service.Draft(context.Background(), workflow.RequirementClassification, "", "Description.", []string{first, second}, []string{"owner"})
	if err != nil {
		t.Fatal(err)
	}
	if number != 17 {
		t.Fatalf("Draft() = %d, want 17", number)
	}
	secondTicket, found, err := artifact.Ticket(second)
	if err != nil || !found || secondTicket != url {
		t.Fatalf("second ticket = %q, %t, %v", secondTicket, found, err)
	}
}

func TestDraftCreatesRootRequirementTicketWithAssignees(t *testing.T) {
	path := filepath.Join(t.TempDir(), "requirement.md")
	if err := os.WriteFile(path, []byte("# Specification\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	var createdAssignees []string
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		switch request.URL.Path {
		case "/repos/example/repository/assignees":
			_ = json.NewEncoder(writer).Encode([]map[string]string{{"login": "alice"}, {"login": "bob"}})
		case "/repos/example/repository/issues":
			if request.Method != http.MethodPost {
				t.Fatalf("issue request method = %s", request.Method)
			}
			var input struct {
				Assignees []string `json:"assignees"`
			}
			if err := json.NewDecoder(request.Body).Decode(&input); err != nil {
				t.Fatal(err)
			}
			createdAssignees = input.Assignees
			_ = json.NewEncoder(writer).Encode(map[string]any{
				"number":    17,
				"html_url":  "https://github.com/example/repository/issues/17",
				"assignees": []map[string]string{{"login": "alice"}, {"login": "bob"}},
			})
		case "/repos/example/repository/issues/17":
			_ = json.NewEncoder(writer).Encode(map[string]string{"node_id": "issue-node"})
		case "/repos/example/repository/issues/17/comments":
			writer.WriteHeader(http.StatusCreated)
		case "/graphql":
			data, _ := io.ReadAll(request.Body)
			var payload struct {
				Query string `json:"query"`
			}
			_ = json.Unmarshal(data, &payload)
			switch {
			case strings.Contains(payload.Query, "addProjectV2ItemById"):
				_ = json.NewEncoder(writer).Encode(map[string]any{"data": map[string]any{"addProjectV2ItemById": map[string]any{"item": map[string]string{"id": "item-node"}}}})
			case strings.Contains(payload.Query, "updateProjectV2ItemFieldValue"):
				_ = json.NewEncoder(writer).Encode(map[string]any{"data": map[string]any{"updateProjectV2ItemFieldValue": map[string]any{"projectV2Item": map[string]string{"id": "item-node"}}}})
			default:
				t.Fatalf("unexpected GraphQL query: %s", payload.Query)
			}
		default:
			t.Fatalf("unexpected request: %s %s", request.Method, request.URL.Path)
		}
	}))
	defer server.Close()

	state := func(id string) config.State { return config.State{ID: id, Sources: []string{id}} }
	service := App{
		Config: config.Config{
			AcceptanceBranch: "main",
			GitHub:           config.GitHub{Repository: "example/repository", Project: config.Project{ID: "project-node"}},
			States:           config.States{Draft: state("draft"), Ready: state("ready"), InProgress: state("progress"), Archived: state("archived"), ImplementationAccepted: state("accepted")},
		},
		GitHub: github.NewWithBaseURL("token", server.URL, server.Client()),
	}
	number, err := service.Draft(context.Background(), workflow.RequirementClassification, "Review requirement", "Description.", []string{path}, []string{"alice", "bob"})
	if err != nil {
		t.Fatal(err)
	}
	if number != 17 || len(createdAssignees) != 2 || createdAssignees[0] != "alice" || createdAssignees[1] != "bob" {
		t.Fatalf("Draft() ticket = %d, assignees = %#v", number, createdAssignees)
	}
	ticket, found, err := artifact.Ticket(path)
	if err != nil || !found || ticket != "https://github.com/example/repository/issues/17" {
		t.Fatalf("artifact ticket = %q, %t, %v", ticket, found, err)
	}
}

func TestDraftReusesRootTicketAndPreservesAssignees(t *testing.T) {
	path := filepath.Join(t.TempDir(), "requirement.md")
	if err := os.WriteFile(path, []byte("# Specification\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := artifact.WriteTicket(path, "https://github.com/example/repository/issues/17"); err != nil {
		t.Fatal(err)
	}
	body, err := workflow.TicketBody("Define the requirement.", []string{path})
	if err != nil {
		t.Fatal(err)
	}
	var requested []string
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		switch request.URL.Path {
		case "/repos/example/repository/assignees":
			_ = json.NewEncoder(writer).Encode([]map[string]string{{"login": "alice"}})
		case "/repos/example/repository/issues/17":
			_ = json.NewEncoder(writer).Encode(map[string]any{"body": body})
		case "/repos/example/repository/issues/17/assignees":
			var input struct {
				Assignees []string `json:"assignees"`
			}
			if err := json.NewDecoder(request.Body).Decode(&input); err != nil {
				t.Fatal(err)
			}
			requested = input.Assignees
			_ = json.NewEncoder(writer).Encode(map[string]any{"assignees": []map[string]string{{"login": "existing"}, {"login": "alice"}}})
		default:
			t.Fatalf("unexpected request: %s %s", request.Method, request.URL.Path)
		}
	}))
	defer server.Close()
	service := App{
		Config: config.Config{GitHub: config.GitHub{Repository: "example/repository"}},
		GitHub: github.NewWithBaseURL("token", server.URL, server.Client()),
	}
	number, err := service.Draft(context.Background(), workflow.RequirementClassification, "", "Description.", []string{path}, []string{"alice"})
	if err != nil {
		t.Fatal(err)
	}
	if number != 17 || len(requested) != 1 || requested[0] != "alice" {
		t.Fatalf("Draft() ticket = %d, requested assignees = %#v", number, requested)
	}
}

func TestDraftRejectsIneligibleAssigneeBeforeCreatingTicket(t *testing.T) {
	path := filepath.Join(t.TempDir(), "requirement.md")
	if err := os.WriteFile(path, []byte("# Specification\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/repos/example/repository/assignees" {
			t.Fatalf("unexpected request: %s %s", request.Method, request.URL.Path)
		}
		_ = json.NewEncoder(writer).Encode([]map[string]string{{"login": "bob"}})
	}))
	defer server.Close()
	service := App{
		Config: config.Config{GitHub: config.GitHub{Repository: "example/repository"}},
		GitHub: github.NewWithBaseURL("token", server.URL, server.Client()),
	}
	if _, err := service.Draft(context.Background(), workflow.RequirementClassification, "Requirement", "Description.", []string{path}, []string{"alice"}); err == nil {
		t.Fatal("Draft() succeeded with an ineligible assignee")
	}
}

func TestRequiredAssignees(t *testing.T) {
	if _, err := requiredAssignees(nil); err == nil {
		t.Fatal("requiredAssignees() accepted no assignee")
	}
	if _, err := requiredAssignees([]string{"alice", "ALICE"}); err == nil {
		t.Fatal("requiredAssignees() accepted duplicate assignees")
	}
	tooMany := make([]string, 11)
	for index := range tooMany {
		tooMany[index] = string(rune('a' + index))
	}
	if _, err := requiredAssignees(tooMany); err == nil {
		t.Fatal("requiredAssignees() accepted more than ten assignees")
	}
}

func TestHandoffCreatesPredecessorLinkedSpecificationTicket(t *testing.T) {
	path := filepath.Join(t.TempDir(), "specification.md")
	if err := os.WriteFile(path, []byte("# Specification\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	parentBody, err := workflow.TicketBody("Define the requirement.", []string{"requirement.md"})
	if err != nil {
		t.Fatal(err)
	}
	var childBody string
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		switch request.URL.Path {
		case "/repos/example/repository/assignees":
			_ = json.NewEncoder(writer).Encode([]map[string]string{{"login": "lead"}})
		case "/repos/example/repository/issues/17":
			_ = json.NewEncoder(writer).Encode(map[string]any{"number": 17, "node_id": "requirement-node", "body": parentBody})
		case "/repos/example/repository/issues":
			if request.Method == http.MethodGet {
				_ = json.NewEncoder(writer).Encode([]map[string]any{{"number": 17, "body": parentBody}})
				return
			}
			var input struct {
				Body string `json:"body"`
			}
			if err := json.NewDecoder(request.Body).Decode(&input); err != nil {
				t.Fatal(err)
			}
			childBody = input.Body
			_ = json.NewEncoder(writer).Encode(map[string]any{"number": 18, "html_url": "https://github.com/example/repository/issues/18", "assignees": []map[string]string{{"login": "lead"}}})
		case "/repos/example/repository/issues/18":
			_ = json.NewEncoder(writer).Encode(map[string]string{"node_id": "specification-node"})
		case "/repos/example/repository/issues/18/comments":
			writer.WriteHeader(http.StatusCreated)
		case "/graphql":
			data, _ := io.ReadAll(request.Body)
			var payload struct {
				Query string `json:"query"`
			}
			_ = json.Unmarshal(data, &payload)
			switch {
			case strings.Contains(payload.Query, "items(first: 100"):
				_ = json.NewEncoder(writer).Encode(map[string]any{
					"data": map[string]any{
						"node": map[string]any{
							"items": map[string]any{
								"nodes": []any{map[string]any{
									"id":      "parent-item",
									"content": map[string]string{"id": "requirement-node"},
									"fieldValues": map[string]any{"nodes": []any{map[string]any{
										"optionId": "accepted",
										"field":    map[string]string{"id": "status-field"},
									}}},
								}},
								"pageInfo": map[string]any{"hasNextPage": false},
							},
						},
					},
				})
			case strings.Contains(payload.Query, "addProjectV2ItemById"):
				_ = json.NewEncoder(writer).Encode(map[string]any{"data": map[string]any{"addProjectV2ItemById": map[string]any{"item": map[string]string{"id": "specification-item"}}}})
			case strings.Contains(payload.Query, "updateProjectV2ItemFieldValue"):
				_ = json.NewEncoder(writer).Encode(map[string]any{"data": map[string]any{"updateProjectV2ItemFieldValue": map[string]any{"projectV2Item": map[string]string{"id": "specification-item"}}}})
			case strings.Contains(payload.Query, "addSubIssue"):
				_ = json.NewEncoder(writer).Encode(map[string]any{"data": map[string]any{"addSubIssue": map[string]any{"issue": map[string]string{"id": "requirement-node"}}}})
			default:
				t.Fatalf("unexpected GraphQL query: %s", payload.Query)
			}
		default:
			t.Fatalf("unexpected request: %s %s", request.Method, request.URL.Path)
		}
	}))
	defer server.Close()
	state := func(id string) config.State { return config.State{ID: id, Sources: []string{id}} }
	service := App{Config: config.Config{AcceptanceBranch: "main", GitHub: config.GitHub{Repository: "example/repository", Project: config.Project{ID: "project-node", StatusFieldID: "status-field"}}, States: config.States{Draft: state("draft"), Accepted: state("accepted"), Ready: state("ready"), InProgress: state("progress"), Archived: state("archived"), ImplementationAccepted: state("implementation-accepted")}}, GitHub: github.NewWithBaseURL("token", server.URL, server.Client())}
	number, err := service.Handoff(context.Background(), 17, workflow.SpecificationClassification, "Review specification", "Description.", []string{path}, []string{"lead"})
	if err != nil {
		t.Fatal(err)
	}
	if number != 18 {
		t.Fatalf("Handoff() = %d, want 18", number)
	}
	if strings.Contains(childBody, "dw:ticket") || !strings.Contains(childBody, "Description.") {
		t.Fatalf("child ticket body = %q", childBody)
	}
}

func TestRegisterReadsArtifactTicket(t *testing.T) {
	path := filepath.Join(t.TempDir(), "requirement.md")
	if err := os.WriteFile(path, []byte("# Requirement\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := artifact.WriteTicket(path, "https://github.com/example/repository/issues/17"); err != nil {
		t.Fatal(err)
	}
	var updatedBody string
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		switch request.URL.Path {
		case "/repos/example/repository/pulls/4":
			if request.Method == http.MethodGet {
				_ = json.NewEncoder(writer).Encode(map[string]any{
					"number": 4,
					"body":   "Review this change.",
					"base":   map[string]string{"ref": "main"},
				})
				return
			}
			data, _ := io.ReadAll(request.Body)
			var input map[string]string
			_ = json.Unmarshal(data, &input)
			updatedBody = input["body"]
		case "/repos/example/repository/issues/17/comments":
			writer.WriteHeader(http.StatusCreated)
		default:
			t.Fatalf("unexpected request: %s %s", request.Method, request.URL.Path)
		}
	}))
	defer server.Close()

	service := App{
		Config: config.Config{
			AcceptanceBranch: "main",
			GitHub:           config.GitHub{Repository: "example/repository"},
		},
		GitHub: github.NewWithBaseURL("token", server.URL, server.Client()),
	}
	if err := service.Register(context.Background(), 4, 0, workflow.Requirement, []string{path}); err != nil {
		t.Fatal(err)
	}
	review, err := workflow.Parse(updatedBody)
	if err != nil {
		t.Fatal(err)
	}
	if review.RequirementNumber != 17 || review.RequirementURL != "https://github.com/example/repository/issues/17" {
		t.Fatalf("review Requirement = %d, %q", review.RequirementNumber, review.RequirementURL)
	}
}
