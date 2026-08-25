# ADR: Replace Roles with Experts

## Context

The previous role model implied a provider-specific orchestration structure.
The harness needs portable specialist declarations that work across different
client runtimes.

## Considered Options

- Retain roles and add expert aliases.
- Replace roles with one provider-neutral expert catalog.

## Decision

Replace `workspace.agent.role.roles` with
`workspace.agent.expert.experts`. Do not retain a compatibility alias.

## Rationale

One catalog has a clear portable contract. An alias would retain two names for
the same behavior and would make migration and client mapping ambiguous.

## Consequences

Consumers must migrate directly to the expert option. Expert declarations do
not create teams, shared state, messaging, or provider-specific permissions.
Client adapters can differ in preload and runtime behavior.
