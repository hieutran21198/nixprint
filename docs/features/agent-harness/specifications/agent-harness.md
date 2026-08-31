---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/11
---
# Agent Harness Specification

## Requirement

This specification implements the [Agent Harness Requirements](../requirements/agent-harness.md).

## Configuration Interface

The Agent Harness uses these project options:

| Option | Type and default | Meaning |
| --- | --- | --- |
| `workspace.agent.harness.enable` | Boolean, `false` | Enables the harness. |
| `workspace.agent.harness.clients.<client>.enable` | Boolean, `false` | Enables `codex`, `claude`, or `opencode`. |
| `workspace.agent.harness.implementationBoundary.mode` | `disabled` or `required`, `disabled` | Selects shared write enforcement. |
| `workspace.agent.mcp.servers.<id>.enable` | Boolean, `false` | Enables the MCP server. |
| `workspace.agent.mcp.servers.<id>.command` | List of strings, empty | Defines a local standard input and output command. |
| `workspace.agent.mcp.servers.<id>.cwd` | Nullable path, `null` | Sets the optional process directory. |
| `workspace.agent.mcp.servers.<id>.environment` | Attribute set, empty | Sets literal values or `{ secret = "NAME"; }` references. |
| `workspace.agent.mcp.mcps.context7.package` | Package, `pkgs.context7-mcp` | Selects the Context7 MCP package. |
| `workspace.agent.mcp.mcps.codegraph.package` | Package, `pkgs.codegraph` | Selects the Codegraph MCP package. |
| `workspace.agent.expert.experts.<id>.description` | String | Defines when to use an expert. |
| `workspace.agent.expert.experts.<id>.persistentInstructions` | String | Defines persistent expert instructions. |
| `workspace.agent.expert.experts.<id>.defaultSkills` | List of strings, empty | Defines preferred workflow skills. |
| `workspace.agent.expert.experts.<id>.writePaths` | List of strings, empty | Defines writable files or directory roots. |
| `workspace.agent.expert.experts.<id>.writeGlobs` | List of strings, empty | Narrows `writePaths` for supported native policies. |
| `workspace.agent.skill.skills.<id>.description` | String | Defines when to load a skill. |
| `workspace.agent.skill.skills.<id>.instructions` | String | Defines Agent Skills-compatible content. |

The harness generates files only when the harness and at least one client are
enabled. Evaluation fails when the harness has no enabled client.

## Generated Client Assets

The harness maps one neutral declaration to each enabled client.

| Client | MCP asset | Expert asset | Skill asset |
| --- | --- | --- | --- |
| Codex | `.codex/config.toml` | `.codex/agents/<id>.toml` | `.agents/skills/<id>/SKILL.md`, referenced from the Codex configuration |
| Claude Code | `.mcp.json` | `.claude/agents/<id>.md` | `.claude/skills/<id>/SKILL.md` and `.agents/skills/<id>/SKILL.md` |
| OpenCode | `.opencode/opencode.json` | `.opencode/agents/<id>.md` | `.agents/skills/<id>/SKILL.md` |

Claude Code also receives `CLAUDE.md` with an `@AGENTS.md` reference. Every
enabled client receives the shared `.agents/bin/validate-write` command.
Disabled clients receive none of their client-specific assets.

## MCP Mapping

Each MCP command list must contain at least one string. The first string is the
executable for Codex and Claude Code. The remaining strings are arguments.
OpenCode receives the complete list as its local command.

Enabled MCP servers are project-global for each enabled client. Experts do not
define client-specific MCP allow lists. Disabled MCP servers do not generate
client entries. They do not require a command or SecretSpec references.

An enabled `context7` or `codegraph` server installs its selected MCP package.
The package option defaults to the project package from Nixpkgs. A user can set
the option to a compatible package from their own package set. The selected
package must provide the executable in the server command.

Literal environment values remain literal. Secret references use the
SecretSpec environment-variable name:

- Codex uses `env_vars`.
- Claude Code uses `${NAME}`.
- OpenCode uses `{env:NAME}`.

Evaluation fails when a secret reference does not have enabled SecretSpec or
does not identify a declared SecretSpec secret. The generated configuration
contains the reference. It does not contain the resolved value.

## Project MCP Servers

The workspace declares two project MCP servers through the neutral options.
Every enabled client receives both servers.

`context7` provides current library documentation. It uses this declaration:

```nix
workspace.agent.mcp.servers.context7 = {
  enable = true;
  command = [ "context7-mcp" ];
  environment.CONTEXT7_API_KEY = { secret = "CONTEXT7_API_KEY"; };
};
```

The `context7-mcp` executable comes from the selected Context7 package. The
`CONTEXT7_API_KEY` secret is optional. When no key is configured, the
server runs without an API key and may receive rate limits. When the secret is
declared, SecretSpec supplies it at startup, and every generated client asset
contains only the `{env:CONTEXT7_API_KEY}`, `${CONTEXT7_API_KEY}`, or
`env_vars` reference form for its client.

`codegraph` provides code-graph queries over a local repository index. It uses
this declaration:

```nix
workspace.agent.mcp.servers.codegraph = {
  enable = true;
  command = [ "codegraph" "serve" "--mcp" ];
  cwd = ./.;
};
```

The `codegraph` command comes from the selected Codegraph package. The
repository root is the process directory. The server reads the local
`.codegraph/` index. The index requires one `codegraph init` run in the
repository root. The server auto-syncs the index on file changes. The
`.codegraph/` directory MUST NOT enter version control. `codegraph` declares
no secrets and no literal environment values.

## Expert and Skill Mapping

Experts and skills remain client-neutral until file generation. Each expert
receives its description, persistent instructions, and default skill guidance.
Default skills are workflow preferences. They do not change client permission
settings.

The Agent service provides `asd-ste100-writing` with default priority. The
skill applies the project writing standard to new or changed documentation.
The Artifact-Polyrepo Workspace scope expert selects it by default.

Each `writePath` must be a unique repository-relative file or directory root.
It must not be empty, `.`, absolute, home-relative, contain parent traversal,
or contain a glob marker. An empty `writePaths` list is valid for an expert
that does not implement changes.

Each `writeGlob` must be unique and repository-relative. It must contain a
glob marker and must not contain parent traversal. Its literal prefix must be
inside one declared `writePath`.

## Write Enforcement

Claude Code receives a `PreToolUse` hook for `Write` and `Edit`. The hook
rejects paths outside the repository. It applies `writeGlobs` when present.
Otherwise, it applies `writePaths`.

OpenCode receives a deny-all edit rule followed by allow rules. The allow
rules use `writeGlobs` when present. Otherwise, they use each `writePath` and
its descendants.

Codex receives write guidance. Codex produces an evaluation warning when an
expert has `writeGlobs`, because those globs do not form a portable Codex
boundary.

The `required` boundary mode is available only on Linux. It requires an
enabled harness client and adds Bubblewrap plus this command:

```text
devenv shell -- workspace-agent-run <expert-id> -- <client command...>
```

The runner mounts the host file system read-only. It bind-mounts only the
declared `writePaths` as writable. Each declared path must exist and resolve
inside the repository. The runner rejects unknown experts and experts without
write paths. A runner startup failure prevents the client command from
starting.

Client-native policies are extra guardrails. The Bubblewrap runner is the
shared enforcement mechanism when the boundary is required.

## Verification

`services/agent/tests/test-module.sh` verifies evaluation, generated assets,
secret references, expert validation, native policies, required runner
generation, and the `context7` and `codegraph` server declarations.
`devenv eval` verifies the integrated workspace configuration.

## Decision

The [Provider-Neutral Harness Decision](../decisions/provider-neutral-harness.md)
defines the selected model. The
[Default Project MCP Servers Decision](../decisions/default-project-mcp-servers.md)
defines the selected servers.
