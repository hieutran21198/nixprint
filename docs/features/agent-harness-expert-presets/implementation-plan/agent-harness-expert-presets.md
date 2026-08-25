# Agent Harness Expert Integrations Implementation Plan

This plan implements the
[task definitions](../tasks/agent-harness-expert-presets.md).

## Sequence

1. Add the built-in ASD-STE100 writing skill to the agent service.
2. Select the skill for Artifact-Driven documentation scope work and local Nix
   expertise that can change agent instructions.
3. Add derived Artifact-Driven and Polyrepo agent integration modules.
4. Move automatic Artifact-Driven experts and skills into the Artifact-Driven
   and agent integration.
5. Move bounded Polyrepo implementation expert configuration into the
   Polyrepo and agent integration.
6. Remove the preset modules and obsolete public option.
7. Update documentation and run deterministic Nix evaluation checks.

## Dependencies

- Artifact-Driven Documentation model for the Artifact-Driven and agent
  integration.
- Polyrepo blueprint for the Polyrepo and agent integration.
- The agent harness and at least one selected client for generated assets.

## Risks

- Native skill preload behavior differs by client.
- A configured implementation scope can be too broad. Configuration validation
  requires a stated repository or implementation area, while review confirms
  that the stated boundary is appropriate.
- Consumers of the obsolete Polyrepo option must migrate in the same change.

## Verification

Evaluate Artifact-Driven-only, Polyrepo-only, combined, disabled-harness,
unbounded-Polyrepo, and outside-Polyrepo configurations. Check derived
integration markers, native expert assets, the Claude bridge, client selection,
MCP secret references, and absence of secret values.
