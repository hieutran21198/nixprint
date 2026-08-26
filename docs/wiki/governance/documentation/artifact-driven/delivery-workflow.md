# Artifact-Driven Delivery Workflow

## Purpose

This document defines the delivery workflow for Artifact-Driven Development.
It defines how documentation artifacts, pull requests (PRs), merge requests
(MRs), continuous integration and continuous delivery (CI/CD), and
execution-system tickets work together.

## Scope

This workflow applies to these phases:

1. Requirement.
2. Specifications and architecture decision records (ADRs).
3. Tasks and implementation plans.
4. Implementation.

This document does not define a provider-specific integration or a release
lifecycle.

## Terms

- An acceptance branch is the protected branch that accepts a PR or MR.
- An execution system manages tickets and their work data.
- A review unit is one ticket, one workflow phase, and one PR or MR.
- An explicit rejection is an authorized decision to reject a review unit.
- A predecessor is the accepted ticket that authorizes the next documentation
  phase.

## Ticket State Semantics

This workflow uses these ticket-state semantics:

- `Draft`
- `Ready`
- `In Progress`
- `Done`
- `Archived`

An execution system MAY map these semantics to states with different names. It
MAY use additional intermediate states, such as `Code Review`, `Ready to Test`,
`Testing`, `QA`, or `UAT`.

The execution system owns its state model, assignment, priority, scheduling,
and work history.

## Phases 1–3

For requirements, specifications and ADRs, and tasks and implementation plans,
the workflow MUST be:

```text
Draft artifact
  -> sync ticket as Draft
  -> create PR/MR
  -> accepted merge: ticket Ready
  -> explicit rejection: ticket Archived
```

The integration MUST create or update the ticket as `Draft` before it registers
the PR or MR.

The integration MUST transition the ticket to `Ready` only after an accepted
merge to the acceptance branch.

The integration MUST transition the ticket to `Archived` only after an explicit
rejection.

## Documentation Handoffs

The Requirement owner MUST create the root Phase-1 Requirement ticket. The
ticket MUST identify one to ten eligible Issue assignees. The Requirement owner
is the Phase-1 artifact owner and Issue assignee.

After the Requirement ticket is `Ready`, the Requirement owner MUST hand it to
a Draft Phase-2 Specifications and ADRs ticket. The technical lead owns the
Phase-2 artifacts and is the Phase-2 Issue assignee.

After the Phase-2 ticket is `Ready`, the technical lead MUST hand it to a Draft
Phase-3 Tasks and Implementation Plan ticket. The technical lead remains the
Phase-3 artifact owner. The selected builder is the Phase-3 Issue assignee.

Each child ticket MUST record its canonical predecessor ticket URL and
predecessor phase. The integration MUST reject a handoff when the predecessor
is not `Ready`, has the wrong phase, or already has an invalid child link.

An Issue assignee identifies GitHub work responsibility. It MUST NOT change
artifact ownership or acceptance authority.

## Phase 4

For implementation, the workflow MUST be:

```text
Task ticket Ready
  -> implementation starts: ticket In Progress
  -> create PR/MR
  -> accepted merge: implementation accepted
  -> rejection, close, or rework: ticket remains In Progress
```

The execution system MUST transition the task ticket from `Ready` to
`In Progress` when implementation starts.

The integration MUST start only a `Ready` Phase-3 ticket with one or more
existing builder assignees. It MUST reuse those assignees. It MUST NOT ask for,
add, remove, or replace an assignee when Phase 4 starts.

An accepted implementation merge is the ADD implementation acceptance
boundary. It does not by itself require the task ticket to transition to
`Done`.

The execution system MAY use post-implementation states and MAY transition the
task ticket to `Done` after testing, QA, UAT, or release validation.

A rejected, closed, or rework implementation PR or MR MUST NOT change the task
ticket from `In Progress`.

## Acceptance and Rejection

An accepted PR or MR MUST merge to the configured acceptance branch.

The acceptance branch MUST require the reviews and CI checks that apply to its
repository.

A branch push, PR or MR creation, approval, or passing CI check MUST NOT by
itself change a terminal ticket state.

An explicit rejection is a provider-independent decision. This governance does
not prescribe how a provider records that decision.

An unmerged PR or MR close MUST NOT by itself archive a phase 1–3 ticket. The
integration MUST classify the close according to its configured rejection
decision rule.

## System Responsibilities

| System | Responsibility |
| --- | --- |
| Version control | Manage branches, commits, PRs or MRs, reviews, and merge results. |
| CI | Validate the proposed artifact or implementation and report merge-check evidence. |
| CD | Build, promote, and deploy accepted changes. Record deployment evidence. |
| Execution system | Manage tickets and execution data. |
| Integration layer | Correlate review units, classify outcomes, and apply permitted ticket transitions. |

CI MUST validate documentation artifacts in phases 1–3 before merge. CI MUST
validate implementation in phase 4 before merge.

CD MAY provide deployment evidence. The execution system controls state changes
after the implementation acceptance boundary, including a transition to `Done`.

## Integration Rules

The integration MUST use provider-independent terms and semantics. It MUST NOT
require a provider-specific ticket type, field, workflow, or rejection
mechanism.

For each review unit, the integration MUST retain:

- The ticket identifier or canonical URL.
- The workflow phase.
- The artifact paths or task identifier.
- The PR or MR identifier and repository.
- The acceptance branch.
- The permitted outcome.

The PR or MR MUST identify its ticket and workflow phase.

The integration MUST verify the current PR or MR state before it changes a
ticket. It MUST apply a transition only when the ticket has its expected state.

The integration MUST process duplicate and late events safely. It MUST
reconcile non-terminal review units after a delivery failure.

A repeated documentation handoff MUST identify the same predecessor and child
phase. The integration MUST reuse the linked child ticket, retain its existing
assignees, and confirm that all supplied assignees are present.

## Artifact Ticket Correlation

An artifact in phases 1-3 that belongs to a review unit MUST use this YAML
front-matter contract:

```yaml
---
delivery:
  ticket: "<canonical ticket URL>"
---
```

The `delivery.ticket` value MUST identify the review-unit ticket. Related
artifacts in the same review unit MUST use the same value.

The contract MUST NOT contain provider configuration, a ticket state, or a
command. The execution-system adapter owns those details.

## Research Basis

[Artifact-Driven Delivery Workflow Integration Research](../../../research/artifact-driven-execution-system-governance.md)
provides provider mappings, official sources, and implementation findings.
