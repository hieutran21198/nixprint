# ADR: Agent-Neutral Adapters

## Context

Codex, Claude Code, and OpenCode use different configuration formats. The
project must define its MCP servers, roles, and skills once.

## Considered Options

- Define each client configuration separately.
- Define one client-neutral layer and generate client assets.

## Decision

Use client-neutral MCP, role, and skill modules. The harness owns client
selection and final project files. Adapter modules contribute typed assets only
for enabled clients.

## Rationale

This keeps shared project behavior independent of a client. It also prevents
adapter modules from writing conflicting client configuration files.

## Consequences

The first version exposes only behavior that has a meaningful shared mapping.
Client-specific models, permissions, hooks, and remote MCP transports remain
out of scope.
