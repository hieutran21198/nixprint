# Agent Harness Expert Presets Requirements

## Outcome

Provide a provider-neutral expert catalog for the agent harness. Automatically
compose Artifact-Driven artifact expertise and configured Polyrepo
implementation expertise.

## Constraints

- Replace `workspace.agent.role.roles` with `workspace.agent.expert.experts`.
- Keep the active primary agent as coordinator.
- Keep default skills as workflow preferences. They are not authorization
  boundaries.
- Activate each preset only when its required model and the harness are
  enabled.
- Require every Polyrepo implementation expert to have a bounded area.
- Preserve provider-native permissions, selected-client behavior, MCP output,
  and SecretSpec handling.

## Acceptance Criteria

- Artifact-Driven supplies scope and technical experts plus shared workflow
  skills, including on-demand semantic artifact review.
- Polyrepo supplies only explicitly configured implementation experts.
- Combined presets are additive.
- Generated Codex, Claude Code, and OpenCode assets expose selected experts.
- Claude Code receives an instruction bridge to canonical `AGENTS.md`.
- Disabled clients receive no client assets.
- Generated files contain secret references and no resolved secret values.
