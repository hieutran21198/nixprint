# Agent Harness Adapter Requirement

## Outcome

Provide one project declaration for supported AI-agent clients, project MCP
servers, named roles, and reusable skills.

## Constraints

- Support Codex, Claude Code, and OpenCode.
- Keep MCP, role, and skill definitions independent of a client format.
- Select enabled clients in one harness configuration.
- Use Devenv's native SecretSpec environment injection. Do not write resolved
  secrets to files.
- Support local stdio MCP servers only.

## Acceptance Criteria

- An enabled client receives native MCP, role, and skill assets.
- A disabled client receives no assets.
- Roles inherit the enabled client's project MCP servers.
- Devenv injects each declared SecretSpec environment variable before a client
  starts.
- Generated files contain secret references, not secret values.
