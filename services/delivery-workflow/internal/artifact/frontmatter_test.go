package artifact

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestWriteAndReadTicket(t *testing.T) {
	path := filepath.Join(t.TempDir(), "requirement.md")
	if err := os.WriteFile(path, []byte("# Requirement\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	url := "https://github.com/example/repository/issues/17"
	if err := WriteTicket(path, url); err != nil {
		t.Fatal(err)
	}
	ticket, found, err := Ticket(path)
	if err != nil {
		t.Fatal(err)
	}
	if !found || ticket != url {
		t.Fatalf("Ticket() = %q, %t, want %q, true", ticket, found, url)
	}
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(contents), "# Requirement") {
		t.Fatalf("artifact body was not retained: %q", contents)
	}
}

func TestTicketRejectsEmptyValue(t *testing.T) {
	path := filepath.Join(t.TempDir(), "requirement.md")
	contents := "---\ndelivery:\n  ticket: \"\"\n---\n# Requirement\n"
	if err := os.WriteFile(path, []byte(contents), 0o644); err != nil {
		t.Fatal(err)
	}
	if _, _, err := Ticket(path); err == nil {
		t.Fatal("Ticket() succeeded with an empty ticket URL")
	}
}
