# Agent Harness Expert Presets Implementation Plan

This plan implements the
[task definitions](../tasks/agent-harness-expert-presets.md).

## Sequence

1. Replace the role option and generated role fields with expert fields.
2. Add the Artifact-Driven preset and coordinator workflow guidance.
3. Add the Polyrepo preset with explicit bounded implementation configuration.
4. Update native client generation and the Claude `AGENTS.md` bridge.
5. Update documentation and run deterministic Nix evaluation checks.

## Dependencies

- Artifact-Driven Documentation model for artifact presets.
- Polyrepo blueprint for implementation-expert presets.
- The agent harness and at least one selected client for generated assets.

## Risks

- Native skill preload behavior differs by client.
- A configured implementation scope can be too broad. Configuration validation
  requires a stated repository or implementation area, while review confirms
  that the stated boundary is appropriate.

## Verification

Evaluate Artifact-Driven-only, Polyrepo-only, combined, disabled-harness, and
invalid-Polyrepo configurations. Check native expert assets, the Claude bridge,
client selection, MCP secret references, and absence of secret values.
