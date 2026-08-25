package app

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/cirius/delivery-workflow/internal/config"
	"github.com/cirius/delivery-workflow/internal/github"
	"github.com/cirius/delivery-workflow/internal/workflow"
)

func TestTransitionMovesDocumentationTicketAfterVerifiedMerge(t *testing.T) {
	review := workflow.ReviewUnit{Version: 1, TicketURL: "https://github.com/example/repository/issues/17", TicketNumber: 17, Phase: workflow.Requirement, Artifacts: []string{"docs/requirement.md"}, AcceptanceBranch: "main"}
	body, err := workflow.Upsert("", review)
	if err != nil {
		t.Fatal(err)
	}
	var mutationOption string
	var auditComment string
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		switch request.URL.Path {
		case "/repos/example/repository/pulls/4":
			_ = json.NewEncoder(writer).Encode(map[string]any{"number": 4, "body": body, "merged": true, "base": map[string]string{"ref": "main"}})
		case "/repos/example/repository/issues/17":
			_ = json.NewEncoder(writer).Encode(map[string]string{"node_id": "issue-node"})
		case "/repos/example/repository/issues/17/comments":
			data, _ := io.ReadAll(request.Body)
			var comment map[string]string
			_ = json.Unmarshal(data, &comment)
			auditComment = comment["body"]
			writer.WriteHeader(http.StatusCreated)
		case "/graphql":
			data, _ := io.ReadAll(request.Body)
			var payload struct {
				Query     string         `json:"query"`
				Variables map[string]any `json:"variables"`
			}
			_ = json.Unmarshal(data, &payload)
			switch {
			case strings.Contains(payload.Query, "items(first: 100"):
				response := map[string]any{
					"data": map[string]any{
						"node": map[string]any{
							"items": map[string]any{
								"nodes": []any{map[string]any{
									"id":      "item-node",
									"content": map[string]string{"id": "issue-node"},
									"fieldValues": map[string]any{
										"nodes": []any{map[string]any{
											"optionId": "draft",
											"field":    map[string]string{"id": "status-field"},
										}},
									},
								}},
								"pageInfo": map[string]any{"hasNextPage": false, "endCursor": ""},
							},
						},
					},
				}
				_ = json.NewEncoder(writer).Encode(response)
			case strings.Contains(payload.Query, "updateProjectV2ItemFieldValue"):
				mutationOption, _ = payload.Variables["option"].(string)
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
	cfg := config.Config{Version: config.Version, AcceptanceBranch: "main", GitHub: config.GitHub{Repository: "example/repository", Project: config.Project{Owner: "example", ID: "project-node", StatusFieldID: "status-field"}}, States: config.States{Draft: state("draft"), Ready: state("ready"), InProgress: state("progress"), Archived: state("archived"), ImplementationAccepted: state("ready-to-test")}}
	service := App{Config: cfg, GitHub: github.NewWithBaseURL("token", server.URL, server.Client())}
	if err := service.Transition(context.Background(), 4); err != nil {
		t.Fatalf("Transition() returned %v", err)
	}
	if mutationOption != "ready" {
		t.Fatalf("status option = %q, want ready", mutationOption)
	}
	if !strings.Contains(auditComment, "outcome=accepted") {
		t.Fatalf("audit comment = %q", auditComment)
	}
}

func TestTransitionLeavesUnmergedImplementationPullRequestUnchanged(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/repos/example/repository/pulls/4" {
			t.Fatalf("unexpected request: %s", request.URL.Path)
		}
		_ = json.NewEncoder(writer).Encode(map[string]any{"number": 4, "merged": false, "base": map[string]string{"ref": "main"}})
	}))
	defer server.Close()
	state := func(id string) config.State { return config.State{ID: id, Sources: []string{id}} }
	cfg := config.Config{Version: config.Version, AcceptanceBranch: "main", GitHub: config.GitHub{Repository: "example/repository", Project: config.Project{Owner: "example", ID: "project-node", StatusFieldID: "status-field"}}, States: config.States{Draft: state("draft"), Ready: state("ready"), InProgress: state("progress"), Archived: state("archived"), ImplementationAccepted: state("ready-to-test")}}
	service := App{Config: cfg, GitHub: github.NewWithBaseURL("token", server.URL, server.Client())}
	if err := service.Transition(context.Background(), 4); err != nil {
		t.Fatalf("Transition() returned %v", err)
	}
}
