---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/3
---
# Provider-Neutral Harness Decision

## Requirement

This decision supports the [Agent Harness Requirements](../requirements/agent-harness.md).

## Context

The workspace supports Codex, Claude Code, and OpenCode. These clients use
different MCP, expert, skill, and edit-policy formats. The system also needs
one write guarantee that does not depend on a client-native policy.

## Options

1. Store and maintain a separate complete configuration for each client.
2. Store neutral MCP, expert, and skill declarations, then generate native
   assets for enabled clients.
3. Require one client and remove the other adapters.

## Decision

Use provider-neutral declarations with thin client adapters. Keep client
selection in one harness configuration. Use Bubblewrap as the shared required
write boundary on Linux. Keep native edit policies as additional guardrails.

## Rationale

This model matches the implemented configuration boundary. It prevents three
independent sources of expert and skill truth. It also separates portable
write enforcement from client-specific policy capabilities.

## Consequences

- A new client needs an adapter from the existing neutral declarations.
- A client-specific limitation can produce guidance or a warning.
- Secret values stay outside generated files.
- Required cross-client enforcement depends on Linux and Bubblewrap.
- The harness does not provide orchestration, shared state, or remote MCP
  transports.

## Specification

See the [Agent Harness Specification](../specifications/agent-harness.md).
