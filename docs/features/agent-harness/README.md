# Agent Harness

## Scope

This feature defines provider-neutral project configuration for supported
AI-agent clients. It includes Model Context Protocol (MCP) servers, experts,
skills, generated client assets, secret references, and implementation write
boundaries.

## Scope-Level Owner

The Agent service maintainer owns this scope. The implementation belongs to
the `services` repository category and to `services/agent`.

## Included Concerns

- Agent Harness activation and client selection.
- Provider-neutral MCP, expert, and skill declarations.
- Native project assets for Codex, Claude Code, and OpenCode.
- SecretSpec environment-variable references.
- Expert write-boundary validation and enforcement.

## Excluded Concerns

- Provider-native orchestration, shared agent state, and direct messaging.
- Hosted or remote MCP transports.
- Workspace-specific expert composition.

## Documents

- [Requirements](requirements/agent-harness.md)
- [Specification](specifications/agent-harness.md)
- [Provider-Neutral Harness Decision](decisions/provider-neutral-harness.md)
- [Tasks](tasks/agent-harness.md)
- [Implementation Plan](implementation-plan/agent-harness.md)
