---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/1
---
# Delivery Workflow Requirements

## Outcome

Provide a reliable Artifact-Driven Delivery Workflow that correlates each
review phase with one ticket and one pull request. Provide a GitHub adapter
that applies only verified and permitted ticket transitions.

## Constraints

- The workflow MUST support Requirement, Specifications and Architecture
  Decision Records, Tasks and Implementation Plan, and Implementation phases.
- Documentation phases MUST move from Draft to Ready only after an accepted
  merge to the configured acceptance branch.
- An explicit authorized rejection MUST be the only operation that archives a
  documentation review ticket.
- Implementation MUST start only from an assigned Ready task-plan ticket.
- An implementation start MUST reuse the existing builder assignments.
- A rejected, closed, or reworked implementation pull request MUST leave the
  ticket In Progress.
- The execution system MAY map workflow semantics to status values with
  different names.
- Each documentation phase MUST use one to ten distinct eligible assignees.
- Each documentation handoff MUST use the accepted ticket from the required
  prior phase.
- Child tickets MUST retain the predecessor ticket URL and phase.
- Assignment MUST NOT transfer artifact ownership or acceptance authority.
- Related documentation artifacts MUST use one canonical `delivery.ticket`
  URL in YAML front matter.
- Review units MUST retain the ticket, phase, artifact paths when applicable,
  acceptance branch, and pull-request correlation.
- The adapter MUST verify current pull-request and ticket state before each
  transition.
- Duplicate commands and late accepted-merge events MUST be safe to retry.
- The GitHub adapter MUST support one repository and one user-owned or
  organization-owned GitHub Project.
- Tokens and resolved secrets MUST NOT be stored in repository configuration.
- Delivery Workflow file generation MUST require Artifact-Driven
  Documentation.

## Acceptance Criteria

- `dw init` discovers the selected Project status field and writes version 1
  repository configuration.
- `dw assignees` lists all eligible Issue assignees.
- `dw draft` creates or reuses only a root Requirement ticket.
- `dw handoff` creates or safely reuses only the permitted child phases.
- `dw start` accepts only an assigned Ready task-plan ticket.
- `dw register` validates artifact correlation and records one review unit in
  the pull-request body.
- `dw validate` rejects missing or invalid review-unit data.
- Accepted documentation and implementation merges apply only their
  configured transitions.
- `dw reject` archives only an authorized documentation review with an
  explicit reason.
- `dw reconcile` retries applicable merged pull requests without duplicating
  terminal transitions.
- Nix configuration seeds `.dw/config.yaml` and the validation, transition,
  and reconciliation GitHub Actions workflows.
