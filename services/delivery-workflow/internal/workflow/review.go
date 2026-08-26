package workflow

import (
	"errors"
	"fmt"
	"strings"

	"gopkg.in/yaml.v3"
)

const (
	markerStart = "<!-- dw:review-unit\n"
	markerEnd   = "-->"
)

type Phase string

const (
	Requirement    Phase = "requirement"
	SpecsADRs      Phase = "specs-adrs"
	TasksPlan      Phase = "tasks-plan"
	Implementation Phase = "implementation"
)

type ReviewUnit struct {
	Version           int           `yaml:"version"`
	RequirementURL    string        `yaml:"requirement_url"`
	RequirementNumber int           `yaml:"requirement_number"`
	Phase             Phase         `yaml:"phase"`
	Groups            []TicketGroup `yaml:"groups"`
	AcceptanceBranch  string        `yaml:"acceptance_branch"`
}

type Classification string

const (
	RequirementClassification   Classification = "requirement"
	SpecificationClassification Classification = "specification"
	DecisionClassification      Classification = "decision"
	TaskClassification          Classification = "task"
)

func (c Classification) Valid() bool {
	return c == RequirementClassification || c == SpecificationClassification || c == DecisionClassification || c == TaskClassification
}

type TicketGroup struct {
	TicketURL      string         `yaml:"ticket_url"`
	TicketNumber   int            `yaml:"ticket_number"`
	Classification Classification `yaml:"classification"`
	Artifacts      []string       `yaml:"artifacts,omitempty"`
}

func TicketBody(description string, artifacts []string) (string, error) {
	description = strings.Join(strings.Fields(description), " ")
	if description == "" {
		return "", errors.New("ticket description is required")
	}
	seen := map[string]bool{}
	var refs []string
	for _, path := range artifacts {
		path = strings.TrimSpace(path)
		if path != "" && !seen[path] {
			seen[path] = true
			refs = append(refs, path)
		}
	}
	if len(refs) == 0 {
		return "", errors.New("ticket artifact paths are required")
	}
	var body strings.Builder
	body.WriteString(description)
	body.WriteString("\n\nArtifacts:\n")
	for _, path := range refs {
		fmt.Fprintf(&body, "- `%s`\n", path)
	}
	return body.String(), nil
}

func (r *ReviewUnit) Validate() error {
	if r.Version != 2 {
		return errors.New("review unit version must be 2")
	}
	if r.RequirementURL == "" || r.RequirementNumber < 1 {
		return errors.New("review unit root requirement is required")
	}
	if !r.Phase.Valid() {
		return fmt.Errorf("unknown workflow phase %q", r.Phase)
	}
	if r.AcceptanceBranch == "" {
		return errors.New("review unit acceptance branch is required")
	}
	if len(r.Groups) == 0 {
		return errors.New("review unit ticket groups are required")
	}
	for _, group := range r.Groups {
		if group.TicketURL == "" || group.TicketNumber < 1 || !group.Classification.Valid() {
			return errors.New("review unit group ticket and classification are required")
		}
		if r.Phase != Implementation && len(group.Artifacts) == 0 {
			return errors.New("artifact paths are required for phases 1-3")
		}
	}
	return nil
}

func (p Phase) Valid() bool {
	return p == Requirement || p == SpecsADRs || p == TasksPlan || p == Implementation
}

func (p Phase) Documentation() bool { return p != Implementation }

func Parse(body string) (ReviewUnit, error) {
	start := strings.Index(body, markerStart)
	if start == -1 {
		return ReviewUnit{}, errors.New("PR body has no dw review-unit record")
	}
	start += len(markerStart)
	endOffset := strings.Index(body[start:], markerEnd)
	if endOffset == -1 {
		return ReviewUnit{}, errors.New("PR body has an unfinished dw review-unit record")
	}
	var review ReviewUnit
	if err := yaml.Unmarshal([]byte(body[start:start+endOffset]), &review); err != nil {
		return ReviewUnit{}, fmt.Errorf("parse review-unit record: %w", err)
	}
	if err := review.Validate(); err != nil {
		return ReviewUnit{}, err
	}
	return review, nil
}

func Upsert(body string, review ReviewUnit) (string, error) {
	if err := review.Validate(); err != nil {
		return "", err
	}
	data, err := yaml.Marshal(review)
	if err != nil {
		return "", fmt.Errorf("encode review-unit record: %w", err)
	}
	block := markerStart + string(data) + markerEnd
	start := strings.Index(body, markerStart)
	if start == -1 {
		if strings.TrimSpace(body) == "" {
			return block + "\n", nil
		}
		return strings.TrimRight(body, "\n") + "\n\n" + block + "\n", nil
	}
	contentStart := start + len(markerStart)
	endOffset := strings.Index(body[contentStart:], markerEnd)
	if endOffset == -1 {
		return "", errors.New("PR body has an unfinished dw review-unit record")
	}
	end := contentStart + endOffset + len(markerEnd)
	return body[:start] + block + body[end:], nil
}

func AuditMarker(pr int, outcome string) string {
	return fmt.Sprintf("<!-- dw:audit pr=%d outcome=%s -->", pr, outcome)
}
