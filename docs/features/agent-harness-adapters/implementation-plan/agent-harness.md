# Agent Harness Adapter Implementation Plan

## Sequence

1. Define harness client selection and internal generated-asset interfaces.
2. Define MCP, role, and skill adapters against those interfaces.
3. Generate native project files and SecretSpec environment references.
4. Validate generated assets for each selected client.

## Dependencies

- Installed Codex, Claude Code, or OpenCode client binaries.
- A project `secretspec.toml` declaring each MCP secret environment variable.

## Risks

- Client configuration formats can change. Keep mappings isolated by client.
- A client started outside the Devenv shell does not receive the SecretSpec
  environment variables required by an MCP server.

## Verification

Evaluate configurations for each supported client. Parse generated native
assets. Run a harmless local stdio MCP fixture through each installed client.
