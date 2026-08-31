---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/9
---
# Agent Harness Requirements

## Outcome

Provide one provider-neutral project configuration for supported AI-agent
clients, local MCP servers, experts, reusable skills, and optional enforced
implementation write boundaries.

## Constraints

- The Agent Harness MUST support Codex, Claude Code, and OpenCode.
- One harness configuration MUST select the enabled clients.
- A disabled client MUST receive no client-specific assets.
- MCP servers MUST use local standard input and output commands.
- Each MCP server declaration MUST provide an enable setting.
- MCP environment values MUST support literal values and SecretSpec secret
  references.
- Generated files MUST contain secret references and MUST NOT contain resolved
  secret values.
- Experts and skills MUST remain independent of client-native formats.
- MCP servers MUST remain project-global. Experts MUST NOT define separate MCP
  allow lists.
- Default skills MUST be workflow preferences. They MUST NOT grant or restrict
  provider-native permissions.
- The Agent service MUST provide the `asd-ste100-writing` skill for enabled
  harness clients.
- Expert write paths MUST use validated repository-relative files or directory
  roots.
- Optional write globs MUST narrow declared write paths.
- Required cross-client write enforcement MUST use the Linux Bubblewrap
  runner and MUST fail closed when the runner cannot start.
- Client-native edit policies MUST remain additional guardrails. They MUST NOT
  replace the shared runner guarantee.
- The Agent Harness MUST provide the `context7` MCP server. The server MUST
  give agents current library documentation through a local standard input and
  output command.
- The `context7` API key MUST stay optional. A configured key MUST use one
  SecretSpec secret reference, such as `CONTEXT7_API_KEY`.
- The Agent Harness MUST provide the `codegraph` MCP server. The server MUST
  index this repository locally and MUST serve code-graph queries through a
  local standard input and output command.
- The `context7` and `codegraph` servers MUST use the provider-neutral MCP
  server declarations. They MUST NOT add client-specific source configuration.
- Every enabled client MUST receive the `context7` and `codegraph` servers.

## Acceptance Criteria

- Each enabled client receives its native MCP, expert, and skill assets.
- Agent declarations map to every enabled client without duplicate
  client-specific source configuration.
- SecretSpec supplies each declared secret environment variable when the
  harness starts.
- Invalid MCP commands, secret references, write paths, or write globs fail
  evaluation.
- A disabled MCP server MUST not generate a client entry or require its command
  and secret references.
- The required runner permits declared repository writes and rejects other
  repository writes.
- Claude Code and OpenCode receive native direct-edit guardrails.
- Codex receives write-boundary guidance and a warning when write globs cannot
  form a portable native boundary.
- Each enabled client receives native `context7` and `codegraph` MCP entries.
- SecretSpec supplies the declared `context7` API key when the harness starts,
  and generated files contain only the secret reference.
- Evaluation fails when the `context7` or `codegraph` command is empty or
  invalid.

## Specification

See the [Agent Harness Specification](../specifications/agent-harness.md).
