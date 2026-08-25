package config

import "testing"

func TestValidateAcceptsConfiguredSemanticMappings(t *testing.T) {
	state := func(id string) State { return State{ID: id, Name: id, Sources: []string{id}} }
	cfg := Config{
		Version:          Version,
		AcceptanceBranch: "main",
		GitHub:           GitHub{Repository: "example/repository", Project: Project{Owner: "example", ID: "project", StatusFieldID: "field"}},
		States:           States{Draft: state("draft"), Ready: state("ready"), InProgress: state("progress"), Archived: state("archived"), ImplementationAccepted: state("test")},
	}
	if err := cfg.Validate(); err != nil {
		t.Fatalf("Validate() returned %v", err)
	}
}

func TestValidateRejectsStatusNamesAsConfiguration(t *testing.T) {
	cfg := Config{Version: Version, GitHub: GitHub{Repository: "example/repository"}}
	if err := cfg.Validate(); err == nil {
		t.Fatal("Validate() succeeded without GitHub Project option IDs")
	}
}

func TestProjectOwnerKindDefaultsToOrganization(t *testing.T) {
	project := Project{}
	if actual := project.OwnerKind(); actual != "organization" {
		t.Fatalf("OwnerKind() = %q, want organization", actual)
	}
}
