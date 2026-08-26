# Delivery Workflow Governance

## Purpose

This governance defines how Artifact-Driven documents, implementation changes,
pull requests, and execution-system tickets move through acceptance.

The workflow does not define post-implementation testing, release, or
deployment.

## Terms

- An acceptance branch is the protected branch that accepts a pull request.
- A review set is the complete artifact and ticket set for one phase and one pull request.
- A classification identifies a Requirement, Specification, Decision, or Task ticket.
- An explicit rejection is an authorized decision to reject a documentation
  review unit.

## Phases

| Phase | Artifacts | Artifact owner | Ticket assignment |
| --- | --- | --- | --- |
| Requirement | Requirements | Requirement owner | Requirement owner |
| Specifications and ADRs | Specifications and decisions | Technical lead | Technical lead |
| Tasks and plan | Tasks and implementation plans | Technical lead | Selected builders |
| Implementation | Implementation change | Implementation scope owner | Existing builders |

Each documentation phase uses one to ten distinct eligible assignees.
Assignment identifies execution responsibility. It does not transfer document
ownership or acceptance authority.

## Documentation Handoffs

The Requirement ticket is the root ticket. It has no predecessor.

An Accepted Requirement authorizes Phase 2. Acceptance of the complete Phase 2 set authorizes Phase 3. Acceptance of the complete Phase 3 set authorizes Phase 4.

Each Specification, Decision, and Task ticket MUST be a native direct sub-issue of the root Requirement ticket.

The integration MUST reject a handoff when:

- The complete prior-phase set is not accepted.
- A child has a different root Requirement.
- A child does not have the required native parent.

A valid retry reuses the linked child. It keeps current assignees and confirms
the requested assignees.

## State Transitions

An execution system MAY use different names for these logical states.

| Event | Required source | Result |
| --- | --- | --- |
| Create a documentation ticket | None | Draft |
| Accept Phase 1 | Draft Requirement | Accepted Requirement |
| Accept Phase 2 | Draft Specification and Decision | Accepted Specification and Decision |
| Accept Phase 3 | Draft Task | Ready Task |
| Explicitly reject a documentation review | Configured Draft source | Archived |
| Start implementation | Ready Tasks and Plan ticket | In Progress |
| Accept an implementation pull request | Configured In Progress source | Implementation Accepted |

Starting implementation reuses existing builder assignments. It does not add,
remove, or replace an assignee.

A rejected, closed, or reworked implementation pull request leaves the ticket
In Progress. The execution system can use later testing or release states, but
those states are outside this workflow.

## Acceptance and Rejection

An accepted pull request MUST merge to the configured acceptance branch. The
branch MUST apply the repository's required reviews and checks.

A branch push, pull-request creation, approval, or passing check does not
accept a review unit.

Only an explicit authorized rejection can archive a documentation review
ticket. An unmerged close or a request for changes does not archive it.
Implementation review tickets cannot use the archive transition.

## Correlation

Each documentation artifact uses the canonical URL of its owning ticket:

```yaml
---
delivery:
  ticket: "https://github.com/OWNER/REPOSITORY/issues/NUMBER"
---
```

The artifact contract contains only the ticket URL. It does not contain
provider configuration, ticket state, or commands.

The pull-request review record retains:

- The root Requirement URL and number.
- The workflow phase.
- Complete ticket, classification, and artifact groups.
- The acceptance branch.
- Pull-request correlation.

The implementation phase reuses the Tasks and Plan ticket and does not require
artifact front matter.

## Integration Reliability

The integration MUST read current pull-request and ticket state before each
transition. It MUST reject an unexpected source state.

A transition to the existing target state is a safe retry. The integration
MUST process duplicate and late accepted events without applying a different
transition. Reconciliation MUST retry applicable merged review units and
report failures.

The execution system owns assignment, priority, scheduling, state names, and
work history. Version control owns branches, reviews, checks, and merge
results. The integration owns correlation and permitted state changes.

## Current Adapter

The [Delivery Workflow feature](../../../../features/delivery-workflow/README.md)
defines the implemented GitHub adapter, command interface, configuration, and
generated workflows.
