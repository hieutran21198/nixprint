# GitHub Adapter Specification

## Participants

| Participant | Responsibility |
| --- | --- |
| GitHub | Branches, pull requests, reviews, and merge result. |
| GitHub Actions | Validation, merge handling, and reconciliation. |
| GitHub Issues | Ticket identity and history. |
| GitHub Projects | Configured ticket-state values in a user-owned or organization Project. |
| `dw` | Correlation and permitted Project updates. |

## Configuration

`dw init` lists the selected Project `Status` field values. It writes the
chosen option IDs to `.dw/config.yaml`.

The configuration maps Draft, Ready, In Progress, Archived, and
implementation acceptance. Implementation acceptance can map to `Done`,
`Ready to Test`, or another value.

`workspace.delivery-workflow` is the Nix option for generated configuration.
When enabled, it seeds `.dw/config.yaml` and the GitHub Actions workflows.
Set `github.project.ownerType` to `user` for a user-owned Project. A user-owned
Project uses `authorizerUsers` for explicit rejection authorization.

## Review Unit

`dw register` writes a YAML record in an HTML comment in the PR description.
The record contains the ticket URL and number, phase, artifact paths when
applicable, and acceptance branch.

## Transitions

| Event | Result |
| --- | --- |
| `dw draft` | Create a phase 1–3 ticket and set Draft. |
| `dw start` | Move Ready to In Progress. |
| Merged documentation PR | Move Draft-semantic value to Ready. |
| Authorized `dw reject` | Move Draft-semantic value to Archived. |
| Merged implementation PR | Move In Progress-semantic value to the configured implementation-acceptance value. |
| Unmerged closed PR | Do not change the ticket. |

The command re-reads the PR and Project state before it changes a ticket. It
does not transition from an unexpected state.
