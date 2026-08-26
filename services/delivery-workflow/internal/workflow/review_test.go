package workflow

import (
	"strings"
	"testing"
)

func TestReviewUnitRoundTrip(t *testing.T) {
	group := TicketGroup{TicketURL: "https://github.com/example/repository/issues/1", TicketNumber: 1, Classification: RequirementClassification, Artifacts: []string{"docs/requirement.md"}}
	review := ReviewUnit{Version: 2, RequirementURL: group.TicketURL, RequirementNumber: 1, Phase: Requirement, Groups: []TicketGroup{group}, AcceptanceBranch: "main"}
	body, err := Upsert("Review this change.", review)
	if err != nil {
		t.Fatal(err)
	}
	actual, err := Parse(body)
	if err != nil {
		t.Fatal(err)
	}
	if actual.RequirementNumber != 1 || len(actual.Groups) != 1 {
		t.Fatalf("Parse() = %#v", actual)
	}
}

func TestTicketBodyContainsOnlyDescriptionAndDeduplicatedArtifacts(t *testing.T) {
	body, err := TicketBody("A  single\nparagraph.", []string{"docs/a.md", "docs/a.md", "docs/b.md"})
	if err != nil {
		t.Fatal(err)
	}
	want := "A single paragraph.\n\nArtifacts:\n- `docs/a.md`\n- `docs/b.md`\n"
	if body != want {
		t.Fatalf("TicketBody() = %q, want %q", body, want)
	}
	if strings.Contains(body, "dw:ticket") {
		t.Fatal("body contains hidden ticket record")
	}
}
