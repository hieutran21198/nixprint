package github

import (
	"context"
	"encoding/json"
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
