---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/3
---
# Delivery Workflow Specification

## Requirement

This specification implements the
[Delivery Workflow Requirements](../requirements/delivery-workflow.md).

## Canonical Model

The workflow has four phases:

1. `requirement`.
2. `specs-adrs`.
3. `tasks-plan`.
4. `implementation`.

Phases 1 through 3 use Artifact-Driven Markdown artifacts, one GitHub Issue,
and one pull request. Phase 4 reuses the accepted `tasks-plan` Issue and uses
one implementation pull request.

The logical ticket states are Draft, Ready, In Progress, Archived, and
Implementation Accepted. Each logical state maps to a configured GitHub
Project option ID. The option name can be different from the logical name.

## Artifact and Review Records

Every artifact in one documentation review unit must contain the same
canonical GitHub Issue URL:

```yaml
---
delivery:
  ticket: https://github.com/OWNER/REPOSITORY/issues/NUMBER
---
```

The URL must identify a positive Issue number in the configured repository.

Each documentation Issue contains a version 1 `dw:ticket` record with its
phase and artifact paths. A root Requirement record has no predecessor. Each
child record contains the accepted predecessor URL and phase.

Each pull-request body contains one version 1 `dw:review-unit` record. It
contains the ticket URL and number, phase, artifact paths when applicable, and
acceptance branch.

## Command Interface

`dw` reads `.dw/config.yaml`. `DW_CONFIG` can select a different path. GitHub
authentication checks `DW_GITHUB_TOKEN`, `GH_TOKEN`, and `GITHUB_TOKEN` in
that order. It uses the GitHub CLI login when none of these variables is set.
`GITHUB_API_URL` can select the GitHub API base URL. Its default is
`https://api.github.com`.

| Command | Behavior |
| --- | --- |
| `dw init` | Discovers one Project and its single-select status field. It prompts for each logical state and writes version 1 configuration. |
| `dw assignees` | Lists repository-eligible Issue assignees, one username per line. |
| `dw draft` | Creates or safely reuses the root `requirement` ticket. |
| `dw handoff` | Creates or safely reuses `specs-adrs` after `requirement`, or `tasks-plan` after `specs-adrs`. |
| `dw start` | Moves an assigned Ready `tasks-plan` ticket to In Progress. |
| `dw register` | Adds or replaces the review-unit record in a pull-request body. |
| `dw validate` | Verifies the review-unit record and acceptance branch. |
| `dw transition` | Applies the permitted transition for a merged pull request. |
| `dw reject` | Archives an authorized documentation review with an explicit reason. |
| `dw reconcile` | Retries transitions for applicable merged pull requests. |

`dw assignees` reads all GitHub result pages. It removes case-insensitive
duplicates and sorts usernames without case sensitivity.

The command signatures are:

```text
dw init --config PATH --repository OWNER/REPOSITORY --project-owner-type organization|user --project-owner OWNER --project NUMBER --acceptance-branch BRANCH --status-field NAME
dw assignees
dw draft --phase requirement --title TITLE --artifact PATH... --assignee USER...
dw handoff --predecessor ISSUE --phase specs-adrs|tasks-plan --title TITLE --artifact PATH... --assignee USER...
dw start --issue ISSUE
dw register --pr PR --issue ISSUE --phase PHASE --artifact PATH...
dw validate --pr PR
dw transition --pr PR
dw transition --event-file PATH
dw reject --pr PR --reason REASON
dw reconcile
```

`dw init` defaults to `.dw/config.yaml`, an `organization` owner,
acceptance branch `main`, and status field `Status`. Documentation
registration derives the Issue from its artifacts, so `--issue` is optional
for phases 1 through 3. Implementation registration requires `--issue`.

`dw draft` accepts only `--phase requirement`. `dw draft` and `dw handoff`
require artifact paths and one to ten distinct eligible assignees. Reuse keeps
existing assignees and adds the requested assignees.

`dw handoff` requires a Ready predecessor of the exact prior phase. It rejects
multiple or mismatched child tickets. A repeated valid handoff reuses the one
correct child and writes its URL to all supplied artifacts.

`dw start` does not add or replace assignees. It requires an existing builder
assignment.

Documentation registration reads the ticket from all artifacts. It rejects
missing or different ticket URLs. Implementation registration has no artifact
record and requires `--issue`.

## Transition Rules

An accepted documentation pull request must be merged into the configured
acceptance branch. The transition moves its ticket from a configured Draft
source to Ready.

An accepted implementation pull request moves its ticket from a configured
In Progress source to Implementation Accepted.

`dw reject` applies only to phases 1 through 3. It requires a non-empty reason
and a current user in `authorizer_users` or an authorized organization team.
It moves the ticket from a configured Draft source to Archived.

An unmerged or wrong-branch pull request causes no acceptance transition. An
implementation pull request cannot use the archive operation. Therefore, a
rejected, closed, or reworked implementation remains In Progress.

A transition is idempotent when the ticket already has its target state. A
transition rejects any other source state. Each applied operation writes an
audit comment. `dw reconcile` ignores pull requests without review records,
retries merged review units, and reports the collected failures.

## Repository Configuration

Version 1 `.dw/config.yaml` contains:

- One `owner/repository` value.
- One user-owned or organization-owned Project.
- The Project node ID, status field name, and status field node ID.
- One acceptance branch.
- Authorized users and teams.
- Target and permitted source option IDs for every logical state.

The configuration contains no token or private key. Existing configuration
without `github.project.owner_type` remains compatible and means
`organization`.

## Nix Interface and Generated Assets

The Nix interface is:

| Option | Default |
| --- | --- |
| `workspace.delivery-workflow.enable` | `false` |
| `github.repository` | Empty string |
| `github.project.owner` | Empty string |
| `github.project.ownerType` | `organization` |
| `github.project.number` | `0` |
| `github.project.id` | Empty string |
| `github.project.statusField` | `Status` |
| `github.project.statusFieldId` | Empty string |
| `acceptanceBranch` | `main` |
| `authorizerTeams` | Empty list |
| `authorizerUsers` | Empty list |
| `states.<semantic>.id` | Empty string |
| `states.<semantic>.name` | Empty string |
| `states.<semantic>.sources` | Empty list |
| `action.ref` | `cirius/delivery-workflow@v1` |

The state semantics are `draft`, `ready`, `inProgress`, `archived`, and
`implementationAccepted`. A user-owned Project requires at least one
authorized user. Every logical state requires a target ID and at least one
source ID.

When enabled, the service seeds:

- `.dw/config.yaml`.
- `.github/workflows/dw-validate.yml`.
- `.github/workflows/dw-transition.yml`.
- `.github/workflows/dw-reconcile.yml`.

The Nix module substitutes `action.ref` into the seeded workflows. The module
does not inspect the documentation model. The Artifact-Polyrepo Workspace
profile selects Artifact-Driven Documentation when it enables this service.

The composite action uses its own Go module. It reads the managed repository
configuration through `DW_CONFIG`. The validation workflow uses the GitHub
token. Transition and reconciliation use the `DW_GITHUB_TOKEN` secret. The
reconciliation workflow runs daily and supports manual execution.

## Verification

`go test ./...` in `services/delivery-workflow` verifies configuration,
artifact front matter, ticket handoffs, assignment rules, review records,
authorization, transitions, retries, and GitHub API behavior. `devenv eval`
verifies generated Nix configuration and workflow assets.

## Decision

The [GitHub Adapter Decision](../decisions/github-adapter.md) defines the
selected execution-system boundary.
