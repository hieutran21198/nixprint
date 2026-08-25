# ADR: Add an ASD-STE100 Writing Skill

## Context

Project documentation must use ASD-STE100 principles. The agent service needs
a reusable skill for that work. Artifact-Driven scope experts need this skill
as a default workflow preference.

## Considered Options

- Define the skill in the Artifact-Driven and agent integration.
- Define the skill in the generic agent skill service.

## Decision

Define `workspace.agent.skill.skills.asd-ste100-writing` in the generic agent
skill service. Select it from the Artifact-Driven and agent integration. Local
implementation experts may select it when their scope includes agent
instructions or project documentation.

## Rationale

The skill is agent-neutral and reusable. The Artifact-Driven integration owns
the default selection for documentation scope work.

## Consequences

Every enabled harness receives the skill. The skill remains a workflow
preference. The project `AGENTS.md` rule provides the mandatory documentation
policy.

The [specification](../specifications/agent-harness-expert-presets.md) defines
the resulting behavior. The
[implementation plan](../implementation-plan/agent-harness-expert-presets.md)
applies this decision.
