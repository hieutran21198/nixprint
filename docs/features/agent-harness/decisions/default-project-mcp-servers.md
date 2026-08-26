---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/12
---
# Default Project MCP Servers Decision

## Requirement

This decision supports the
[Agent Harness Requirements](../requirements/agent-harness.md). The
requirements define the `context7` and `codegraph` servers.

## Context

Agents need current library documentation and code-graph queries about this
repository. The requirements limit MCP servers to local standard input and
output commands through provider-neutral declarations. Every enabled client
must receive both servers.

## Options

1. Add each server to the client-native configurations separately.
2. Use a hosted or remote transport for documentation lookup.
3. Run `context7` through `npx` with an optional SecretSpec key, and run
   `@colbymchenry/codegraph` as a local repository index over standard input
   and output.
4. Run `@astudioplus/codegraph-mcp`, which downloads a platform engine binary
   at install time.

## Decision

Use option 3. Declare `context7` with the command `npx -y
@upstash/context7-mcp`. Make its `CONTEXT7_API_KEY` value an optional
SecretSpec secret reference. Declare `codegraph` with the command `codegraph
serve --mcp` from `@colbymchenry/codegraph`, a repository-root process
directory, and no secrets.

## Rationale

Both servers reuse the existing neutral declaration options, secret handling,
and client adapters. The npx command removes a pinned local installation step
for `context7`. `@colbymchenry/codegraph` keeps the index local, auto-syncs it
on file changes, supports all three enabled clients, and needs no engine
download. A hosted transport would violate the local-transport requirement,
and per-client configuration would duplicate the neutral model.

## Consequences

- Without a configured API key, `context7` may receive rate limits.
- The `codegraph` index requires one `codegraph init` run in the repository
  root. `.codegraph/` must stay outside version control.
- Both commands depend on Node.js tooling in the execution environment.
- A different codegraph package requires a new decision and specification
  change.

## Specification

See the [Agent Harness Specification](../specifications/agent-harness.md).
