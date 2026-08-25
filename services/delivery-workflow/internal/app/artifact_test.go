package app

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
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
	service := App{Config: config.Config{GitHub: config.GitHub{Repository: "example/repository"}}}
	number, err := service.Draft(context.Background(), workflow.Requirement, "", []string{first, second})
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
	if review.TicketNumber != 17 || review.TicketURL != "https://github.com/example/repository/issues/17" {
		t.Fatalf("review ticket = %d, %q", review.TicketNumber, review.TicketURL)
	}
}
