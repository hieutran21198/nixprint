# Agent Harness Expert Integrations Specification

This specification satisfies the
[requirements](../requirements/agent-harness-expert-presets.md).

## Expert Catalog

`workspace.agent.expert.experts.<id>` has only these fields:

- `description`
- `persistentInstructions`
- `defaultSkills`

`defaultSkills` identifies portable workflow preferences. A client can preload
the skills or add lazy-use guidance. It MUST NOT be represented as an
authorization boundary.

The agent service defines `workspace.agent.skill.skills.asd-ste100-writing`.
The skill applies ASD-STE100 principles to new or changed project
documentation. It is available to every enabled harness. The Artifact-Driven
scope expert selects it by default.

## Composition Activation

The `artifact-polyrepo-workspace` profile contributes `scope-expert`,
`technical-expert`, coordinator guidance, authoring guidance, technical review
guidance, and `semantic-artifact-review` when its Agent Harness configuration
has an enabled client.

The coordinator identifies the authoritative artifact context, delegates only
bounded scopes, escalates authority conflicts, and collects validation
evidence. Scope authority accepts requirements. Technical authority owns
technical correctness of decisions and specifications. The coordinator never
accepts artifacts or resolves authority conflicts.

`workspace.blueprint.polyrepo.implementationExperts.<id>` requires a
description, persistent instructions, default skills, and the current
write-boundary contract. A declaration outside the Polyrepo blueprint fails
evaluation. The profile does not infer experts from repositories or generate
category and product combinations. See the
[Write Boundaries specification](../../agent-harness-write-boundaries/specifications/write-boundaries.md).

The profile has no separate enable option. Select it with
`workspace.composition.use`. The obsolete
`workspace.agent.expert.polyrepo.implementationExperts` option does not exist.

## Ownership Boundaries

Artifact experts work in accepted documentation scopes. Polyrepo experts work
only in their declared implementation scope. Repository ownership is
implementation ownership only. Implementation acceptance follows repository
policy, required review, continuous integration, and merge rules.

## Client Mapping

| Client | Expert asset | Default skill mapping |
| --- | --- | --- |
| Codex | `.codex/agents/*.toml` | Persistent lazy-use guidance |
| Claude Code | `.claude/agents/*.md` | Native skill front matter and guidance |
| OpenCode | `.opencode/agents/*.md` | Persistent lazy-use guidance |

Claude Code also receives root `CLAUDE.md` with `@AGENTS.md`. This is the
minimal bridge to canonical project instructions. MCP configuration and native
permission boundaries remain unchanged.
