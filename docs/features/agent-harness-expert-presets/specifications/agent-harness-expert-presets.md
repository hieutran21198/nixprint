# Agent Harness Expert Presets Specification

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

## Preset Activation

Artifact-Driven activates only when
`workspace.documentation.model == "artifact-driven"` and the harness has an
enabled client. It contributes `scope-expert`, `technical-expert`, coordinator
guidance, authoring guidance, technical review guidance, and
`semantic-artifact-review`.

The coordinator identifies the authoritative artifact context, delegates only
bounded scopes, escalates authority conflicts, and collects validation
evidence. Scope authority accepts requirements. Technical authority owns
technical correctness of decisions and specifications. The coordinator never
accepts artifacts or resolves authority conflicts.

Polyrepo activates only when its blueprint and the harness have an enabled
client. `workspace.agent.expert.polyrepo.implementationExperts.<id>` requires
a description, persistent instructions, default skills, and either `repository`
or `implementationArea`. A declaration outside the Polyrepo blueprint fails
evaluation. The preset does not infer experts from repositories or generate
category and product combinations.

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
