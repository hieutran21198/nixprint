# Agent Service

This service generates project configuration for supported AI-agent clients.

`workspace.agent.harness` selects enabled clients. MCP secret values are
injected through Devenv's native SecretSpec integration.
`workspace.agent.mcp`, `workspace.agent.expert`, and `workspace.agent.skill`
define client-neutral project capabilities.

`workspace.agent.expert.experts.<id>` defines a provider-neutral expert. An
expert has a description, persistent instructions, `defaultSkills`, optional
`writePaths`, and optional `writeGlobs`. Default skills are portable workflow
preferences. They do not grant permission or restrict a provider's native
permission model.

The service provides the `asd-ste100-writing` skill for new or changed project
documentation. Artifact-Driven scope experts select this skill by default.

The `artifact-polyrepo-workspace` composition profile provides
Artifact-Driven scope and technical experts, workflow skills, and the
on-demand `semantic-artifact-review` skill when its Agent Harness configuration
has an enabled client. Configure bounded implementation experts in
`workspace.blueprint.polyrepo.implementationExperts`. Each declaration must
define non-empty repository-relative `writePaths`. Optional `writeGlobs` can
narrow direct edits for Claude Code and OpenCode. They do not make a portable
Codex write boundary.

The profile owns its effective Agent Harness settings. Configure them under
`workspace.composition.agent`; those settings override ordinary direct harness
settings while the profile is selected.

Supported clients are Codex, Claude Code, and OpenCode.

Set `workspace.composition.agent.implementationBoundary.mode = "required"`
to require the Linux Bubblewrap runner. Start an implementation expert with:

```text
devenv shell -- workspace-agent-run <expert-id> -- <client command...>
```

The runner mounts the repository read-only and makes only the expert's
declared `writePaths` writable. It fails when Bubblewrap cannot start. A
client started without the runner does not receive this cross-client guarantee.
