package workflow

import "testing"

func TestReviewUnitRoundTrip(t *testing.T) {
	review := ReviewUnit{Version: 1, TicketURL: "https://github.com/example/repository/issues/1", TicketNumber: 1, Phase: Requirement, Artifacts: []string{"docs/requirement.md"}, AcceptanceBranch: "main"}
	body, err := Upsert("Review this change.", review)
	if err != nil {
		t.Fatalf("Upsert() returned %v", err)
	}
	actual, err := Parse(body)
	if err != nil {
		t.Fatalf("Parse() returned %v", err)
	}
	if actual.TicketNumber != review.TicketNumber || actual.Phase != review.Phase || actual.Artifacts[0] != review.Artifacts[0] {
		t.Fatalf("Parse() = %#v, want %#v", actual, review)
	}
}

func TestImplementationDoesNotRequireArtifacts(t *testing.T) {
	review := ReviewUnit{Version: 1, TicketURL: "https://github.com/example/repository/issues/2", TicketNumber: 2, Phase: Implementation, AcceptanceBranch: "main"}
	if err := review.Validate(); err != nil {
		t.Fatalf("Validate() returned %v", err)
	}
}

func TestDocumentationRequiresArtifacts(t *testing.T) {
	review := ReviewUnit{Version: 1, TicketURL: "https://github.com/example/repository/issues/2", TicketNumber: 2, Phase: Requirement, AcceptanceBranch: "main"}
	if err := review.Validate(); err == nil {
		t.Fatal("Validate() succeeded without artifact paths")
	}
}

func TestTicketRecordRoundTripPreservesPredecessor(t *testing.T) {
	record := TicketRecord{
		Version:   1,
		Phase:     SpecsADRs,
		Artifacts: []string{"docs/features/example/specifications/example.md"},
		Predecessor: &TicketLink{
			URL:   "https://github.com/example/repository/issues/17",
			Phase: Requirement,
		},
	}
	body, err := TicketBody(record)
	if err != nil {
		t.Fatal(err)
	}
	parsed, err := ParseTicket(body)
	if err != nil {
		t.Fatal(err)
	}
	if parsed.Predecessor == nil || parsed.Predecessor.URL != record.Predecessor.URL || parsed.Predecessor.Phase != Requirement {
		t.Fatalf("ParseTicket() predecessor = %#v", parsed.Predecessor)
	}
}
