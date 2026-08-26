---
delivery:
  ticket: https://github.com/hieutran21198/nixprint/issues/3
---
# Delivery Workflow Specification

## Requirement

This specification implements the [Delivery Workflow Requirements](../requirements/delivery-workflow.md).

## Model

The phases are `requirement`, `specs-adrs`, `tasks-plan`, and `implementation`. The classifications are `requirement`, `specification`, `decision`, and `task`. GitHub Project `Status` values represent lifecycle state only.

One pull request contains the complete review set for one documentation phase. Phase 1 contains all Requirement artifacts. Phase 2 contains all Specification and Decision artifacts. Phase 3 contains all Task and Implementation Plan artifacts. Registration groups artifacts by their `delivery.ticket` URL.

All Specification, Decision, and Task tickets are native direct sub-issues of the root Requirement ticket. The adapter verifies this relationship during reuse, registration, validation, and transition.

## Records

Artifacts store a canonical `delivery.ticket` URL in YAML front matter. A pull request stores one `dw:review-unit` version 2 record. The record contains the root Requirement, phase, acceptance branch, and complete ticket groups. Each group contains its ticket, classification, and artifacts.

An Issue body contains one required description paragraph followed by a deduplicated list of repository-relative artifact references. It contains no `dw:ticket` record and no copied canonical content.

After all ticket transitions for a documentation phase succeed, the adapter writes one `phase-accepted` audit comment on the root Requirement. The comment identifies the phase, accepted pull request, tickets, and artifacts. The comment is correlation evidence. It is not lifecycle state.

## Commands

```text
dw draft --classification requirement --title TITLE --description DESCRIPTION --artifact PATH... --assignee USER...
dw handoff --requirement ISSUE --classification specification|decision|task --title TITLE --description DESCRIPTION --artifact PATH... --assignee USER...
dw register --pr PR --phase requirement|specs-adrs|tasks-plan --artifact PATH...
dw register --pr PR --phase implementation --issue TASK
dw start --issue TASK
```

`dw init` discovers Draft, Accepted, Ready, In Progress, Archived, and Implementation Accepted. It also discovers the active classification catalog. It writes version 2 only.

## Gates and Transitions

Phase 2 requires an Accepted Requirement. Phase 3 requires all registered Phase 2 tickets to be Accepted. Phase 4 requires all registered Phase 3 Task tickets to be Ready. Ticket existence or partial acceptance does not satisfy a gate.

The transitions are:

- Phase 1: Requirement Draft to Accepted.
- Phase 2: Specification and Decision Draft to Accepted.
- Phase 3: Task Draft to Ready.
- Phase 4 start: Task Ready to In Progress.
- Accepted implementation merge: Task In Progress to Implementation Accepted when `phase4.auto_transition` is `true`.
- Explicit documentation rejection: owned Draft tickets to Archived.

The Requirement remains Accepted after Phase 1. A partial multi-ticket failure does not create the phase-acceptance record. Reconciliation retries incomplete transitions and writes the record only after all transitions reach the target.

The adapter rejects parallel active pull requests for the same Requirement and phase. It permits a replacement after an unmerged pull request closes when no phase-acceptance record exists.

## Configuration

`.dw/config.yaml` accepts version 2 only. `github.project.owner_type` is required. A `user` owner selects configured repository labels. An `organization` owner selects configured native Issue Types. The four configured values are `github.classification.requirement`, `specification`, `decision`, and `task`.

The lifecycle states are `draft`, `accepted`, `ready`, `in_progress`, `archived`, and `implementation_accepted`. Each state has an option ID and permitted source IDs. `phase4.auto_transition` controls the implementation-merge transition.

The adapter requires configured labels and Issue Types to exist. It does not provision organization Issue Types.

## Verification

Tests cover classification mechanisms, native parents, exact Issue bodies, complete phase sets, strict gates, partial failures, audit records, all transitions, parallel pull requests, and both Phase 4 automation settings. Nix tests verify version 2, all classifications, Accepted and Ready, owner-type selection, and generated configuration.

## Decision

The [GitHub Adapter Decision](../decisions/github-adapter.md) defines the adapter boundary.
