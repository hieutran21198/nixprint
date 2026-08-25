# ADR: Replace Expert Presets with Integrations

## Context

The agent service automatically composes Artifact-Driven and Polyrepo experts.
The previous implementation placed this cross-domain composition in agent
preset modules. The composition belongs to the relationship between the
participating systems, not to the generic agent service.

## Considered Options

- Retain the Artifact-Driven and Polyrepo agent presets.
- Move both compositions to derived integration modules.

## Decision

Replace the presets with `artifact-driven-agent` and `polyrepo-agent`
integrations. Derive each integration state from its participating systems and
the enabled agent harness. Move Polyrepo implementation expert declarations to
`workspace.integration.polyrepo-agent.implementationExperts`. Do not retain a
compatibility option.

## Rationale

Integration modules make cross-domain ownership explicit. The Polyrepo option
then identifies bounded implementation expertise without implying that the
generic agent catalog owns Polyrepo configuration.

## Consequences

The generic agent service retains only its provider-neutral expert contract.
Consumers must migrate the Polyrepo declaration path in the same change.

The [specification](../specifications/agent-harness-expert-presets.md) defines
the resulting interfaces and activation rules. The
[implementation plan](../implementation-plan/agent-harness-expert-presets.md)
applies this decision.
