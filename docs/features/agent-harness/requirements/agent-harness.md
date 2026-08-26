---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/1
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
- MCP environment values MUST support literal values and SecretSpec secret
  references.
- Generated files MUST contain secret references and MUST NOT contain resolved
  secret values.
- Experts and skills MUST remain independent of client-native formats.
- Default skills MUST be workflow preferences. They MUST NOT grant or restrict
  provider-native permissions.
- Expert write paths MUST use validated repository-relative files or directory
  roots.
- Optional write globs MUST narrow declared write paths.
- Required cross-client write enforcement MUST use the Linux Bubblewrap
  runner and MUST fail closed when the runner cannot start.
- Client-native edit policies MUST remain additional guardrails. They MUST NOT
  replace the shared runner guarantee.

## Acceptance Criteria

- Each enabled client receives its native MCP, expert, and skill assets.
- Agent declarations map to every enabled client without duplicate
  client-specific source configuration.
- SecretSpec supplies each declared secret environment variable when the
  harness starts.
- Invalid MCP commands, secret references, write paths, or write globs fail
  evaluation.
- The required runner permits declared repository writes and rejects other
  repository writes.
- Claude Code and OpenCode receive native direct-edit guardrails.
- Codex receives write-boundary guidance and a warning when write globs cannot
  form a portable native boundary.
