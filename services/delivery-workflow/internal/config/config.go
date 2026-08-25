package config

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

const Version = 1

// Config is the repository-local delivery workflow configuration.
type Config struct {
	Version          int      `yaml:"version"`
	GitHub           GitHub   `yaml:"github"`
	AcceptanceBranch string   `yaml:"acceptance_branch"`
	AuthorizerTeams  []string `yaml:"authorizer_teams"`
	AuthorizerUsers  []string `yaml:"authorizer_users"`
	States           States   `yaml:"states"`
}

type GitHub struct {
	Repository string  `yaml:"repository"`
	Project    Project `yaml:"project"`
}

type Project struct {
	Owner         string `yaml:"owner"`
	OwnerType     string `yaml:"owner_type"`
	Number        int    `yaml:"number"`
	ID            string `yaml:"id"`
	StatusFieldID string `yaml:"status_field_id"`
	StatusField   string `yaml:"status_field"`
}

type States struct {
	Draft                  State `yaml:"draft"`
	Ready                  State `yaml:"ready"`
	InProgress             State `yaml:"in_progress"`
	Archived               State `yaml:"archived"`
	ImplementationAccepted State `yaml:"implementation_accepted"`
}

type State struct {
	ID      string   `yaml:"id"`
	Name    string   `yaml:"name"`
	Sources []string `yaml:"sources"`
}

func Load(path string) (Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return Config{}, fmt.Errorf("read configuration: %w", err)
	}
	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return Config{}, fmt.Errorf("parse configuration: %w", err)
	}
	if err := cfg.Validate(); err != nil {
		return Config{}, err
	}
	return cfg, nil
}

func Save(path string, cfg Config) error {
	cfg.Version = Version
	cfg.GitHub.Project.OwnerType = cfg.GitHub.Project.OwnerKind()
	data, err := yaml.Marshal(cfg)
	if err != nil {
		return fmt.Errorf("encode configuration: %w", err)
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return fmt.Errorf("create configuration directory: %w", err)
	}
	if err := os.WriteFile(path, data, 0o600); err != nil {
		return fmt.Errorf("write configuration: %w", err)
	}
	return nil
}

func (c Config) Validate() error {
	if c.Version != Version {
		return fmt.Errorf("configuration version must be %d", Version)
	}
	if !strings.Contains(c.GitHub.Repository, "/") {
		return errors.New("github.repository must be owner/repository")
	}
	if c.GitHub.Project.Owner == "" || c.GitHub.Project.ID == "" || c.GitHub.Project.StatusFieldID == "" {
		return errors.New("github.project must include owner, id, and status field id")
	}
	if ownerType := c.GitHub.Project.OwnerKind(); ownerType != "organization" && ownerType != "user" {
		return errors.New("github.project.owner_type must be organization or user")
	}
	if c.AcceptanceBranch == "" {
		return errors.New("acceptance_branch is required")
	}
	for name, state := range map[string]State{
		"draft":                   c.States.Draft,
		"ready":                   c.States.Ready,
		"in_progress":             c.States.InProgress,
		"archived":                c.States.Archived,
		"implementation_accepted": c.States.ImplementationAccepted,
	} {
		if state.ID == "" {
			return fmt.Errorf("states.%s.id is required", name)
		}
		if len(state.Sources) == 0 {
			return fmt.Errorf("states.%s.sources is required", name)
		}
	}
	return nil
}

// OwnerKind returns the Project owner type. Existing configuration without the
// field remains compatible with organization-owned Projects.
func (p Project) OwnerKind() string {
	if p.OwnerType == "" {
		return "organization"
	}
	return p.OwnerType
}

func (c Config) RepositoryParts() (string, string, error) {
	parts := strings.SplitN(c.GitHub.Repository, "/", 2)
	if len(parts) != 2 || parts[0] == "" || parts[1] == "" {
		return "", "", errors.New("github.repository must be owner/repository")
	}
	return parts[0], parts[1], nil
}
