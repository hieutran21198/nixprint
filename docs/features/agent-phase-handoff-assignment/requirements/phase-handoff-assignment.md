# Agent Phase Handoff Assignment Requirement

## Outcome

The delivery workflow enforces one ordered handoff for each documentation
phase. It starts implementation only from an accepted task-plan ticket that
already has a builder assignment.

## Constraints

- A root ticket MUST be a Phase-1 requirement ticket.
- Each assignment list MUST contain one to ten distinct eligible GitHub users.
- A handoff MUST use a Ready predecessor in the required prior phase.
- A child ticket MUST retain its predecessor ticket URL and phase.
- Ticket assignment MUST NOT change artifact ownership or acceptance authority.
- Phase 4 MUST reuse the task-ticket builder assignment.

## Acceptance Criteria

- `dw assignees` lists all eligible repository Issue assignees.
- `dw draft` creates or reuses only a root requirement ticket.
- `dw handoff` creates or safely reuses only the two permitted child phases.
- Invalid assignment, predecessor, state, or child linkage fails before a new
  Issue or Project state change.
- `dw start` accepts only a Ready assigned task-plan ticket.
