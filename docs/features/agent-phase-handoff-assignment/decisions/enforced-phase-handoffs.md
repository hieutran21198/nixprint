# ADR: Enforce Phase Handoffs

## Context

The earlier assignment design applied only to a Phase-2 ticket. It did not
define how Phase-1 ownership, Phase-3 builder selection, or Phase-4 start
relate to each other.

## Considered Options

- Keep assignment optional for direct ticket creation.
- Create independent tickets for each documentation phase.
- Require predecessor-linked handoffs and assignment at every handoff.

## Decision

Require a root Phase-1 requirement ticket. Require the accepted requirement
ticket to hand off to Phase 2. Require the accepted Phase-2 ticket to hand off
to Phase 3. Reuse the Phase-3 builder assignment when Phase 4 starts.

## Rationale

The ticket chain gives each phase one verified predecessor. The selected
assignee is available before the phase starts. The model preserves the
technical lead's ownership of task and plan artifacts.

## Consequences

Manual users must select one to ten eligible assignees for every root ticket
and documentation handoff. The adapter must validate Issue records, Project
state, and assignment confirmation before it performs a state-changing action.
