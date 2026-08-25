# Agent Harness Adapter Specification

## Configuration

`workspace.agent.harness` enables the harness and selects Codex, Claude Code,
and OpenCode clients.

`workspace.agent.mcp.servers` defines local stdio MCP commands and environment
values. An environment value can be a literal value or a SecretSpec environment
variable reference.

`workspace.agent.role.roles` defines a role description, instructions, and
skill IDs. `workspace.agent.skill.skills` defines a skill description and
Agent Skills-compatible instructions.

## Client Assets

The harness emits native configuration only for selected clients:

| Client | MCP assets | Role assets | Skill assets |
| --- | --- | --- | --- |
| Codex | `.codex/config.toml` | `.codex/agents/*.toml` | `.agents/skills/` and Codex registrations |
| Claude Code | `.mcp.json` | `.claude/agents/*.md` | `.claude/skills/` |
| OpenCode | `opencode.json` | `.opencode/agents/*.md` | `.agents/skills/` |

MCP servers are project-global. Roles inherit them. The feature does not map
role-specific tool permissions or MCP allow lists.

## Secret Injection

`workspace.agent.mcp` adds each referenced SecretSpec value to Devenv's native
shell environment. Generated Codex, Claude Code, and OpenCode configuration
refers to that environment variable by the syntax required by that client.
