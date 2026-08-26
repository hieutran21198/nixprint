# Declare Project MCP Servers Task

## Requirement

This task implements the
[Agent Harness Requirements](../requirements/agent-harness.md). The
[Agent Harness Specification](../specifications/agent-harness.md) defines the
server declarations.

## Work

- Declare the `context7` and `codegraph` MCP servers in the workspace agent
  configuration with the commands from the specification.
- Enable SecretSpec for the workspace and declare the optional
  `CONTEXT7_API_KEY` secret.
- Add `.codegraph/` to `.gitignore`.
- Run `codegraph init` in the repository root to create the local index.
- Verify evaluation and the generated client assets.

The [Implementation Plan](../implementation-plan/declare-project-mcp-servers.md)
defines the change sequence, dependencies, risks, and verification approach.
