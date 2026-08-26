# Delivery Workflow Service

`dw` implements the GitHub adapter for the
[Delivery Workflow](../../docs/features/delivery-workflow/README.md). It
supports one GitHub repository and one user-owned or organization-owned GitHub
Project.

GitHub Issues provide ticket identity. The Project single-select status field
provides workflow state. Configured option IDs define the logical states, so
the visible status names can be different.

## Setup

1. Create a GitHub Project with a single-select status field.
2. Protect the configured acceptance branch with applicable reviews and
   checks.
3. Create a token that can read the repository and update its Issues and
   Project.
4. Run `dw init` and select the Project option for each logical state.
5. Configure at least one authorized rejection user or team.
6. Add the validation, transition, and reconciliation workflows.

For a user-owned Project, a classic personal access token needs `repo`,
`read:org`, `read:project`, and `project` scopes. Store the Actions token
as the `DW_GITHUB_TOKEN` repository secret. Do not store a token in Nix or
`.dw/config.yaml`.

`dw` reads `DW_GITHUB_TOKEN`, `GH_TOKEN`, then `GITHUB_TOKEN`. It uses
`gh auth token` when none is set. `GITHUB_API_URL` can select a different
GitHub API base URL.

Initialize configuration with an operator token:

```text
dw init \
  --repository OWNER/REPOSITORY \
  --project-owner-type user \
  --project-owner OWNER \
  --project PROJECT_NUMBER
```

Use `organization` as the owner type for an organization-owned Project.

## Commands

```text
dw assignees
dw draft --phase requirement --title "Document the requirement" --artifact PATH --assignee OWNER
dw handoff --predecessor 17 --phase specs-adrs --title "Define the design" --artifact PATH --assignee TECHNICAL_LEAD
dw handoff --predecessor 18 --phase tasks-plan --title "Plan the change" --artifact TASK_PATH --artifact PLAN_PATH --assignee BUILDER
dw register --pr 42 --phase requirement --artifact PATH
dw start --issue 19
dw register --pr 43 --issue 19 --phase implementation
dw reject --pr 42 --reason "The requirement is not accepted."
dw reconcile
```

`dw assignees` reads every result page, removes case-insensitive duplicates,
sorts usernames, and prints one username per line.

`dw draft` creates or reuses only the root Requirement ticket. `dw handoff`
creates or reuses only the two permitted child phases. Both commands require
one to ten distinct eligible assignees. Reuse keeps existing assignees and adds
the requested users.

Each child ticket records its predecessor URL and phase. A handoff requires a
Ready predecessor in the exact prior phase. A retry reuses the one correctly
linked child.

`dw start` accepts only an assigned Ready `tasks-plan` ticket. It moves the
ticket to In Progress and does not change assignees.

`dw register` reads one canonical `delivery.ticket` URL from all
documentation artifacts. Implementation registration uses `--issue` because
it has no documentation artifact.

`dw transition` verifies a merged pull request and its acceptance branch
before it changes a ticket. Documentation merges move Draft to Ready.
Implementation merges move In Progress to the configured implementation
acceptance state.

`dw reject` applies only to documentation phases. It requires an authorized
actor and an explicit reason. An implementation ticket remains In Progress
after rejection, close, or rework.

`dw reconcile` retries applicable merged pull requests. Transitions are safe
to retry when the ticket already has the target state.

## Configuration

[The configuration example](examples/github/dw.config.yaml) shows version 1.
It contains:

- Repository and Project identifiers.
- The acceptance branch.
- Authorized users and teams.
- Target and permitted source option IDs for each logical state.

The `sources` lists can include intermediate Project values. For example, a
Draft transition source can include Draft and Code Review.

Configuration without `github.project.owner_type` remains compatible and
means `organization`.

## Nix Generation

`workspace.delivery-workflow.enable = true` seeds:

- `.dw/config.yaml`.
- `.github/workflows/dw-validate.yml`.
- `.github/workflows/dw-transition.yml`.
- `.github/workflows/dw-reconcile.yml`.

The standalone module does not inspect the documentation model. The
`artifact-polyrepo-workspace` profile selects Artifact-Driven Documentation,
owns its effective configuration at `workspace.composition.deliveryWorkflow`,
and requires enabled Git hooks.

Set `github.project.ownerType = "user"` and configure `authorizerUsers` for
a user-owned Project. An organization-owned Project can use
`authorizerTeams`.

The composite action runs from its own Go module and reads the managed
repository configuration through `DW_CONFIG`. Validation uses the workflow
GitHub token. Transition and reconciliation use `DW_GITHUB_TOKEN`.

## Validation

Run:

```text
cd services/delivery-workflow
go test ./...
```
