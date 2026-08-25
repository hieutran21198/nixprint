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
	Version          int      `yaml:"version"`
	TicketURL        string   `yaml:"ticket_url"`
	TicketNumber     int      `yaml:"ticket_number"`
	Phase            Phase    `yaml:"phase"`
	Artifacts        []string `yaml:"artifacts,omitempty"`
	AcceptanceBranch string   `yaml:"acceptance_branch"`
}

func (r ReviewUnit) Validate() error {
	if r.Version != 1 {
		return errors.New("review unit version must be 1")
	}
	if r.TicketURL == "" || r.TicketNumber < 1 {
		return errors.New("review unit ticket is required")
	}
	if !r.Phase.Valid() {
		return fmt.Errorf("unknown workflow phase %q", r.Phase)
	}
	if r.AcceptanceBranch == "" {
		return errors.New("review unit acceptance branch is required")
	}
	if r.Phase != Implementation && len(r.Artifacts) == 0 {
		return errors.New("artifact paths are required for phases 1-3")
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
