# Agent Service

This service generates project configuration for supported AI-agent clients.

`workspace.agent.harness` selects enabled clients. MCP secret values are
injected through Devenv's native SecretSpec integration.
`workspace.agent.mcp`, `workspace.agent.role`, and `workspace.agent.skill`
define client-neutral project capabilities.

Supported clients are Codex, Claude Code, and OpenCode.
