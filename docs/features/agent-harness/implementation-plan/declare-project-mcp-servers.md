# Declare Project MCP Servers Implementation Plan

## Requirement

This plan implements the
[Declare Project MCP Servers Task](../tasks/declare-project-mcp-servers.md).

## Change Sequence

1. Declare `workspace.agent.mcp.servers.context7` and
   `workspace.agent.mcp.servers.codegraph` in the workspace agent
   configuration. Use the commands, environment value, and process directory
   from the specification.
2. Enable SecretSpec and declare the optional `CONTEXT7_API_KEY` secret.
3. Add `.codegraph/` to `.gitignore`.
4. Run `codegraph init` in the repository root.
5. Verify evaluation and generated assets.

## Dependencies

- Steps 1 and 2 depend on the accepted specification and decision.
- Step 4 requires a local Node.js runtime and the `@colbymchenry/codegraph`
  package.
- Step 2 requires a configured SecretSpec provider on the operator machine.

## Risks

- Without a configured `CONTEXT7_API_KEY`, `context7` may receive rate limits.
  The server still starts.
- The `npx` command downloads the context7 package at first agent start. A
  cold start needs network access.
- A missing `.codegraph/` index makes codegraph queries fail. The server
  command itself still starts.

## Verification Approach

- `devenv eval` passes with both servers declared.
- Each enabled client asset contains native `context7` and `codegraph`
  entries.
- Generated files contain only secret reference forms of `CONTEXT7_API_KEY`.
- Evaluation fails when a server command is empty or when a secret reference
  has no SecretSpec declaration.
- `git status` shows no tracked `.codegraph/` paths.
