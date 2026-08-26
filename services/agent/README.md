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

The service provides the `asd-ste100-writing` skill for new or changed project
documentation. Artifact-Driven scope experts select this skill by default.

The `artifact-polyrepo-workspace` composition profile provides
Artifact-Driven scope and technical experts, workflow skills, and the
on-demand `semantic-artifact-review` skill when its Agent Harness configuration
has an enabled client. Configure bounded implementation experts in
`workspace.blueprint.polyrepo.implementationExperts`. Each declaration must
name a repository or another implementation area.

The profile owns its effective Agent Harness settings. Configure them under
`workspace.composition.agent`; those settings override ordinary direct harness
settings while the profile is selected.

Supported clients are Codex, Claude Code, and OpenCode.
