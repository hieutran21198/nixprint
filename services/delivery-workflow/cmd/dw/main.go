package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"os"
	"strings"

	"github.com/cirius/delivery-workflow/internal/app"
	"github.com/cirius/delivery-workflow/internal/config"
	"github.com/cirius/delivery-workflow/internal/github"
	"github.com/cirius/delivery-workflow/internal/workflow"
)

const defaultConfig = ".dw/config.yaml"

func main() {
	if err := run(context.Background(), os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "dw:", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, args []string) error {
	if len(args) == 0 {
		return usage()
	}
	switch args[0] {
	case "init":
		return runInit(ctx, args[1:])
	case "draft":
		return runDraft(ctx, args[1:])
	case "handoff":
		return runHandoff(ctx, args[1:])
	case "assignees":
		return runAssignees(ctx, args[1:])
	case "start":
		return runStart(ctx, args[1:])
	case "register":
		return runRegister(ctx, args[1:])
	case "validate":
		return runValidate(ctx, args[1:])
	case "transition":
		return runTransition(ctx, args[1:])
	case "reject":
		return runReject(ctx, args[1:])
	case "reconcile":
		return runReconcile(ctx, args[1:])
	case "help", "--help", "-h":
		fmt.Fprint(os.Stdout, usageText)
		return nil
	default:
		return fmt.Errorf("unknown command %q", args[0])
	}
}

func runInit(ctx context.Context, args []string) error {
	flags := flag.NewFlagSet("init", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	path := flags.String("config", defaultConfig, "configuration path")
	repository := flags.String("repository", "", "GitHub owner/repository")
	ownerType := flags.String("project-owner-type", "organization", "GitHub Project owner type: organization or user")
	owner := flags.String("project-owner", "", "GitHub Project owner login")
	project := flags.Int("project", 0, "GitHub Project number")
	branch := flags.String("acceptance-branch", "main", "protected acceptance branch")
	statusField := flags.String("status-field", "Status", "GitHub Project status field")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if *repository == "" || *owner == "" || *project < 1 {
		return errors.New("--repository, --project-owner, and --project are required")
	}
	client, err := github.New("")
	if err != nil {
		return err
	}
	return app.Init(ctx, client, *path, *repository, *ownerType, *owner, *project, *branch, *statusField, os.Stdin, os.Stdout)
}

func loadApp() (app.App, error) {
	path := os.Getenv("DW_CONFIG")
	if path == "" {
		path = defaultConfig
	}
	cfg, err := config.Load(path)
	if err != nil {
		return app.App{}, err
	}
	client, err := github.New("")
	if err != nil {
		return app.App{}, err
	}
	return app.App{Config: cfg, GitHub: client}, nil
}

func runDraft(ctx context.Context, args []string) error {
	flags := flag.NewFlagSet("draft", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	phase := flags.String("phase", "", "requirement")
	title := flags.String("title", "", "GitHub Issue title")
	artifacts := stringList{}
	flags.Var(&artifacts, "artifact", "artifact path; repeat as required")
	assignees := stringList{}
	flags.Var(&assignees, "assignee", "GitHub username to assign; repeat one to ten times")
	if err := flags.Parse(args); err != nil {
		return err
	}
	service, err := loadApp()
	if err != nil {
		return err
	}
	number, err := service.Draft(ctx, workflow.Phase(*phase), *title, artifacts, assignees)
	if err != nil {
		return err
	}
	fmt.Printf("Created Draft ticket #%d\n", number)
	return nil
}

func runHandoff(ctx context.Context, args []string) error {
	flags := flag.NewFlagSet("handoff", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	predecessor := flags.Int("predecessor", 0, "accepted predecessor GitHub Issue number")
	phase := flags.String("phase", "", "specs-adrs or tasks-plan")
	title := flags.String("title", "", "GitHub Issue title")
	artifacts := stringList{}
	flags.Var(&artifacts, "artifact", "artifact path; repeat as required")
	assignees := stringList{}
	flags.Var(&assignees, "assignee", "GitHub username to assign; repeat one to ten times")
	if err := flags.Parse(args); err != nil {
		return err
	}
	service, err := loadApp()
	if err != nil {
		return err
	}
	number, err := service.Handoff(ctx, *predecessor, workflow.Phase(*phase), *title, artifacts, assignees)
	if err != nil {
		return err
	}
	fmt.Printf("Created Draft ticket #%d\n", number)
	return nil
}

func runAssignees(ctx context.Context, args []string) error {
	if len(args) != 0 {
		return errors.New("assignees accepts no arguments")
	}
	service, err := loadApp()
	if err != nil {
		return err
	}
	assignees, err := service.Assignees(ctx)
	if err != nil {
		return err
	}
	for _, assignee := range assignees {
		fmt.Println(assignee)
	}
	return nil
}

func runStart(ctx context.Context, args []string) error {
	flags := flag.NewFlagSet("start", flag.ContinueOnError)
	issue := flags.Int("issue", 0, "GitHub Issue number")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if *issue < 1 {
		return errors.New("--issue is required")
	}
	service, err := loadApp()
	if err != nil {
		return err
	}
	return service.Start(ctx, *issue)
}

func runRegister(ctx context.Context, args []string) error {
	flags := flag.NewFlagSet("register", flag.ContinueOnError)
	pr := flags.Int("pr", 0, "pull request number")
	issue := flags.Int("issue", 0, "GitHub Issue number")
	phase := flags.String("phase", "", "workflow phase")
	artifacts := stringList{}
	flags.Var(&artifacts, "artifact", "artifact path; repeat as required")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if *pr < 1 {
		return errors.New("--pr is required")
	}
	service, err := loadApp()
	if err != nil {
		return err
	}
	return service.Register(ctx, *pr, *issue, workflow.Phase(*phase), artifacts)
}

func runValidate(ctx context.Context, args []string) error {
	flags := flag.NewFlagSet("validate", flag.ContinueOnError)
	pr := flags.Int("pr", 0, "pull request number")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if *pr < 1 {
		return errors.New("--pr is required")
	}
	service, err := loadApp()
	if err != nil {
		return err
	}
	return service.Validate(ctx, *pr)
}

func runTransition(ctx context.Context, args []string) error {
	flags := flag.NewFlagSet("transition", flag.ContinueOnError)
	pr := flags.Int("pr", 0, "pull request number")
	eventPath := flags.String("event-file", "", "GitHub event payload path")
	if err := flags.Parse(args); err != nil {
		return err
	}
	service, err := loadApp()
	if err != nil {
		return err
	}
	if *eventPath != "" {
		return service.TransitionEvent(ctx, *eventPath)
	}
	if *pr < 1 {
		return errors.New("--pr or --event-file is required")
	}
	return service.Transition(ctx, *pr)
}

func runReject(ctx context.Context, args []string) error {
	flags := flag.NewFlagSet("reject", flag.ContinueOnError)
	pr := flags.Int("pr", 0, "pull request number")
	reason := flags.String("reason", "", "explicit rejection reason")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if *pr < 1 {
		return errors.New("--pr is required")
	}
	service, err := loadApp()
	if err != nil {
		return err
	}
	return service.Reject(ctx, *pr, *reason)
}

func runReconcile(ctx context.Context, args []string) error {
	if len(args) != 0 {
		return errors.New("reconcile accepts no arguments")
	}
	service, err := loadApp()
	if err != nil {
		return err
	}
	return service.Reconcile(ctx)
}

func usage() error {
	return errors.New(strings.TrimSpace(usageText))
}

const usageText = `usage: dw <command>

Commands: init, assignees, draft, handoff, start, register, validate, transition, reject, reconcile
`

type stringList []string

func (values *stringList) String() string { return strings.Join(*values, ",") }
func (values *stringList) Set(value string) error {
	*values = append(*values, value)
	return nil
}
