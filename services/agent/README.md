# Agent Service

This service generates project configuration for supported AI-agent clients.

`workspace.agent.harness` selects enabled clients. MCP secret values are
injected through Devenv's native SecretSpec integration.
`workspace.agent.mcp`, `workspace.agent.expert`, and `workspace.agent.skill`
define client-neutral project capabilities.

`workspace.agent.expert.experts.<id>` defines a provider-neutral expert. An
expert has a description, persistent instructions, and `defaultSkills`.
Default skills are portable workflow preferences. They do not grant permission
or restrict a provider's native permission model.

The Artifact-Driven and agent integration activates when Artifact-Driven
Documentation and the harness are enabled. It provides `scope-expert`,
`technical-expert`, workflow skills, and the on-demand
`semantic-artifact-review` skill.

The Polyrepo and agent integration activates when the Polyrepo blueprint and
the harness are enabled. Configure bounded implementation experts in
`workspace.integration.polyrepo-agent.implementationExperts`. Each declaration
must name a repository or another implementation area.

Both integrations expose a read-only `build.enabled` marker. They have no
user-set enable option.

Supported clients are Codex, Claude Code, and OpenCode.
