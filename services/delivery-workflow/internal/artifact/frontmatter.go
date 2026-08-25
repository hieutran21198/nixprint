// Package artifact manages the provider-neutral delivery ticket contract in
// Artifact-Driven Markdown documents.
package artifact

import (
	"errors"
	"fmt"
	"os"
	"strings"

	"gopkg.in/yaml.v3"
)

// Ticket reads delivery.ticket from YAML front matter. It reports found as
// false when the document has no ticket declaration.
func Ticket(path string) (ticket string, found bool, err error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", false, fmt.Errorf("read artifact %q: %w", path, err)
	}
	header, _, present, err := splitFrontMatter(data)
	if err != nil || !present {
		return "", false, err
	}
	var values map[string]any
	if err := yaml.Unmarshal(header, &values); err != nil {
		return "", false, fmt.Errorf("parse front matter in %q: %w", path, err)
	}
	delivery, ok := values["delivery"].(map[string]any)
	if !ok {
		if _, exists := values["delivery"]; exists {
			return "", false, fmt.Errorf("delivery front matter in %q must be a mapping", path)
		}
		return "", false, nil
	}
	value, ok := delivery["ticket"]
	if !ok {
		return "", false, nil
	}
	ticket, ok = value.(string)
	if !ok || strings.TrimSpace(ticket) == "" {
		return "", false, fmt.Errorf("delivery.ticket in %q must be a non-empty string", path)
	}
	return ticket, true, nil
}

// WriteTicket creates or updates delivery.ticket in YAML front matter.
func WriteTicket(path, ticket string) error {
	if strings.TrimSpace(ticket) == "" {
		return errors.New("delivery ticket URL is required")
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("read artifact %q: %w", path, err)
	}
	header, body, present, err := splitFrontMatter(data)
	if err != nil {
		return err
	}
	values := map[string]any{}
	if present {
		if err := yaml.Unmarshal(header, &values); err != nil {
			return fmt.Errorf("parse front matter in %q: %w", path, err)
		}
		if values == nil {
			values = map[string]any{}
		}
	}
	delivery, ok := values["delivery"].(map[string]any)
	if !ok {
		if _, exists := values["delivery"]; exists {
			return fmt.Errorf("delivery front matter in %q must be a mapping", path)
		}
		delivery = map[string]any{}
		values["delivery"] = delivery
	}
	delivery["ticket"] = ticket
	encoded, err := yaml.Marshal(values)
	if err != nil {
		return fmt.Errorf("encode front matter for %q: %w", path, err)
	}
	info, err := os.Stat(path)
	if err != nil {
		return fmt.Errorf("stat artifact %q: %w", path, err)
	}
	contents := append([]byte("---\n"), encoded...)
	contents = append(contents, []byte("---\n")...)
	contents = append(contents, body...)
	if err := os.WriteFile(path, contents, info.Mode().Perm()); err != nil {
		return fmt.Errorf("write artifact %q: %w", path, err)
	}
	return nil
}

func splitFrontMatter(data []byte) (header, body []byte, present bool, err error) {
	text := string(data)
	if !strings.HasPrefix(text, "---\n") && !strings.HasPrefix(text, "---\r\n") {
		return nil, data, false, nil
	}
	lines := strings.SplitAfter(text, "\n")
	for index, line := range lines[1:] {
		if strings.TrimRight(line, "\r\n") != "---" {
			continue
		}
		return []byte(strings.Join(lines[1:index+1], "")), []byte(strings.Join(lines[index+2:], "")), true, nil
	}
	return nil, nil, false, errors.New("artifact front matter has no closing delimiter")
}
