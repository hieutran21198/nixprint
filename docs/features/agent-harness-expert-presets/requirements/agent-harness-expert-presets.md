# Agent Harness Expert Integrations Requirements

## Outcome

Provide a provider-neutral expert catalog for the agent harness. Compose
Artifact-Driven artifact expertise and configured Polyrepo implementation
expertise through derived integration modules.

The [specification](../specifications/agent-harness-expert-presets.md) defines
the required interfaces and activation rules.

## Constraints

- Keep `workspace.agent.expert.experts` as the generic provider-neutral expert
  catalog.
- Keep the active primary agent as coordinator.
- Keep default skills as workflow preferences. They are not authorization
  boundaries.
- Provide an agent-neutral ASD-STE100 writing skill for project documentation.
- Select the ASD-STE100 writing skill for the Artifact-Driven scope expert.
- Derive Artifact-Driven and Polyrepo agent integration state from their
  participating models and the enabled harness.
- Do not provide a user-set integration enable option.
- Configure Polyrepo implementation experts only through
  `workspace.integration.polyrepo-agent.implementationExperts`.
- Require every Polyrepo implementation expert to have a bounded area.
- Remove the preset modules and the obsolete
  `workspace.agent.expert.polyrepo.implementationExperts` option.
- Preserve provider-native permissions, selected-client behavior, MCP output,
  and SecretSpec handling.

## Acceptance Criteria

- Artifact-Driven and agent integration supplies scope and technical experts
  plus shared workflow skills, including on-demand semantic artifact review.
- The Artifact-Driven scope expert selects the ASD-STE100 writing skill.
- Polyrepo and agent integration supplies only explicitly configured
  implementation experts.
- Combined integrations are additive.
- Generated Codex, Claude Code, and OpenCode assets expose selected experts.
- Claude Code receives an instruction bridge to canonical `AGENTS.md`.
- Disabled clients receive no client assets.
- Generated files contain secret references and no resolved secret values.
