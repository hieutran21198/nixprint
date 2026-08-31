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
3. Run Nix-provided Context7 and Codegraph commands with an optional SecretSpec
   key for Context7.
4. Run `@astudioplus/codegraph-mcp`, which downloads a platform engine binary
   at install time.

## Decision

Use option 3. Provide Context7 and Codegraph as built-in MCP servers. Context7
uses the command `context7-mcp` and the optional `CONTEXT7_API_KEY` SecretSpec
environment reference. Codegraph uses the command `codegraph serve --mcp` in
the repository root. Nix installs `pkgs.context7-mcp` and
`pkgs.codegraph` when the related built-in server is enabled. Users can override
either package with a compatible package.

## Rationale

Both servers reuse the existing neutral declaration options, secret handling,
and client adapters. The package options provide reproducible project defaults
without preventing users from selecting compatible packages. Codegraph keeps
the index local, auto-syncs it on file changes, supports all three enabled
clients, and needs no engine download. A hosted transport would violate the
local-transport requirement, and per-client configuration would duplicate the
neutral model.

## Consequences

- Without a configured API key, `context7` may receive rate limits.
- The `codegraph` index requires one `codegraph init` run in the repository
  root. `.codegraph/` must stay outside version control.
- Nix resolves both default packages in the development environment.
- A different codegraph package requires a new decision and specification
  change.

## Specification

See the [Agent Harness Specification](../specifications/agent-harness.md).
