# Agent Service

This service implements the
[Agent Harness](../../docs/features/agent-harness/README.md). It generates
project files for Codex, Claude Code, and OpenCode from one provider-neutral
configuration.

## Configuration

`workspace.agent.harness` enables the service, selects clients, and selects
the optional implementation boundary. `workspace.agent.mcp`,
`workspace.agent.expert`, and `workspace.agent.skill` define neutral MCP
servers, experts, and skills.

MCP secret values use SecretSpec environment-variable references. Generated
files contain references, not resolved values.

The service provides the `asd-ste100-writing` skill with default priority.

## Experts and Write Boundaries

An expert defines a description, persistent instructions, default skills,
`writePaths`, and optional `writeGlobs`. Default skills are workflow
preferences. They do not change provider-native permissions.

`writePaths` define portable writable files or directory roots.
`writeGlobs` can narrow direct edits for Claude Code and OpenCode. Codex
receives a warning because it has no portable native positive-glob boundary.

Set `implementationBoundary.mode = "required"` to add the Linux Bubblewrap
runner:

```text
devenv shell -- workspace-agent-run <expert-id> -- <client command...>
```

The runner mounts the repository read-only and makes only declared
`writePaths` writable. It fails closed when the sandbox cannot start. A
client started without the runner does not receive the shared write guarantee.

## Workspace Composition

The `artifact-polyrepo-workspace` profile owns its effective Agent Harness
settings under `workspace.composition.agent`. It adds documentation and
technical experts, shared workflow skills, and explicitly configured Polyrepo
implementation experts.

Configure implementation experts at
`workspace.blueprint.polyrepo.implementationExperts`. Each implementation
expert requires at least one validated write path.

## Validation

Run:

```text
bash services/agent/tests/test-module.sh
```
