---
delivery:
  ticket: https://github.com/hieutran21198/nixprint/issues/1
---
# Delivery Workflow Requirements

## Outcome

Provide a reliable Artifact-Driven Delivery Workflow. Correlate each complete documentation phase with one pull request and all tickets and artifacts in that phase.

## Constraints

- The workflow MUST keep phase, classification, and Project `Status` separate.
- Phase 1 MUST contain the complete Requirement artifact set.
- Phase 2 MUST contain the complete Specification and Decision artifact set.
- Phase 3 MUST contain the complete Task and Implementation Plan artifact set.
- A phase MUST start only after acceptance of the complete prior-phase set.
- Each Specification, Decision, and Task ticket MUST be a native direct sub-issue of the root Requirement ticket.
- Phase 1 acceptance MUST move the Requirement from Draft to Accepted.
- Phase 2 acceptance MUST move Specification and Decision tickets from Draft to Accepted.
- Phase 3 acceptance MUST move Task tickets from Draft to Ready.
- Phase 2 and Phase 3 acceptance MUST NOT change the Accepted Requirement status.
- Phase 4 start MUST move an assigned Ready Task to In Progress.
- An accepted implementation merge MUST move the Task to Implementation Accepted only when automatic transition is enabled.
- An implementation rejection, closure, or rework MUST leave the Task In Progress.
- An explicit documentation rejection MUST move its Draft tickets to Archived.
- A phase-acceptance audit record MUST identify the phase, pull request, tickets, and artifacts.
- The adapter MUST write the phase-acceptance record only after all ticket transitions succeed.
- The adapter MUST reject parallel active pull requests for one Requirement and phase.
- A replacement pull request MAY start after an unmerged pull request closes when no phase-acceptance record exists.
- Configuration MUST use version 2 only.
- User-owned Projects MUST use configured labels. Organization-owned Projects MUST use configured native Issue Types.
- The adapter MUST require classifications to exist. It MUST NOT provision organization Issue Types.
- Issue bodies MUST contain one description paragraph and a deduplicated artifact-reference list.
- Issue bodies MUST NOT contain hidden delivery records or copied canonical artifact content.

## Acceptance Criteria

- `dw init` discovers six lifecycle states and the active classification catalog.
- `dw draft` creates or reuses a Requirement ticket.
- `dw handoff` creates or reuses a native direct child ticket.
- `dw register` records the complete phase set in one version 2 pull-request record.
- `dw validate` compares the registered set with all applicable changed artifacts.
- Transitions are idempotent and do not create a premature phase-acceptance record.
- Nix generates version 2 configuration with all classifications, Accepted, Ready, and Phase 4 automation.

## Specification

See the [Delivery Workflow Specification](../specifications/delivery-workflow.md).
