package github

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestDiscoverUserProject(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/graphql" {
			t.Fatalf("request path = %q, want /graphql", request.URL.Path)
		}
		data, err := io.ReadAll(request.Body)
		if err != nil {
			t.Fatal(err)
		}
		var payload struct {
			Query string `json:"query"`
		}
		if err := json.Unmarshal(data, &payload); err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(payload.Query, "owner: user(login: $owner)") {
			t.Fatalf("query does not select a user Project: %s", payload.Query)
		}
		_ = json.NewEncoder(writer).Encode(map[string]any{
			"data": map[string]any{
				"owner": map[string]any{
					"projectV2": map[string]any{
						"id": "project-id",
						"fields": map[string]any{
							"nodes": []any{map[string]any{
								"id":      "field-id",
								"name":    "Status",
								"options": []any{map[string]string{"id": "ready-id", "name": "Ready"}},
							}},
						},
					},
				},
			},
		})
	}))
	defer server.Close()

	client := NewWithBaseURL("token", server.URL, server.Client())
	projectID, fieldID, options, err := client.DiscoverProject(context.Background(), "user", "hieutran21198", 4, "Status")
	if err != nil {
		t.Fatalf("DiscoverProject() returned %v", err)
	}
	if projectID != "project-id" || fieldID != "field-id" || len(options) != 1 || options[0].ID != "ready-id" {
		t.Fatalf("DiscoverProject() = %q, %q, %#v", projectID, fieldID, options)
	}
}

func TestListAssigneesPaginatesAndSorts(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.URL.Path != "/repos/example/repository/assignees" {
			t.Fatalf("request path = %q", request.URL.Path)
		}
		switch request.URL.Query().Get("page") {
		case "1":
			values := make([]map[string]string, 100)
			for index := range values {
				values[index] = map[string]string{"login": fmt.Sprintf("user-%03d", 100-index)}
			}
			_ = json.NewEncoder(writer).Encode(values)
		case "2":
			_ = json.NewEncoder(writer).Encode([]map[string]string{{"login": "Alice"}, {"login": "alice"}})
		default:
			t.Fatalf("unexpected page %q", request.URL.Query().Get("page"))
		}
	}))
	defer server.Close()

	client := NewWithBaseURL("token", server.URL, server.Client())
	assignees, err := client.ListAssignees(context.Background(), "example/repository")
	if err != nil {
		t.Fatal(err)
	}
	if len(assignees) != 101 || assignees[0] != "alice" || assignees[1] != "user-001" || assignees[len(assignees)-1] != "user-100" {
		t.Fatalf("ListAssignees() = %#v", assignees)
	}
}

func TestAddAssigneesReturnsCurrentIssueAssignees(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		if request.Method != http.MethodPost || request.URL.Path != "/repos/example/repository/issues/17/assignees" {
			t.Fatalf("unexpected request: %s %s", request.Method, request.URL.Path)
		}
		var input struct {
			Assignees []string `json:"assignees"`
		}
		if err := json.NewDecoder(request.Body).Decode(&input); err != nil {
			t.Fatal(err)
		}
		if len(input.Assignees) != 1 || input.Assignees[0] != "alice" {
			t.Fatalf("input assignees = %#v", input.Assignees)
		}
		_ = json.NewEncoder(writer).Encode(map[string]any{"assignees": []map[string]string{{"login": "existing"}, {"login": "alice"}}})
	}))
	defer server.Close()

	client := NewWithBaseURL("token", server.URL, server.Client())
	assignees, err := client.AddAssignees(context.Background(), "example/repository", 17, []string{"alice"})
	if err != nil {
		t.Fatal(err)
	}
	if len(assignees) != 2 || assignees[0] != "existing" || assignees[1] != "alice" {
		t.Fatalf("AddAssignees() = %#v", assignees)
	}
}
