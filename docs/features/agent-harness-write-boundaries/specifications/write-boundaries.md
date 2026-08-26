# Agent Harness Write Boundaries Specification

## Configuration

```nix
workspace.composition.agent.implementationBoundary.mode = "required";

workspace.blueprint.polyrepo.implementationExperts.nix-expert = {
  writePaths = [ "services/agent" "devenv.nix" ];
  writeGlobs = [ "services/agent/**/*.nix" ];
};
```

`writePaths` contains unique, non-root, repository-relative file or directory
paths. A path cannot contain a glob, parent traversal, or an absolute path.
The runner rejects a declared path that does not exist when it starts.

`writeGlobs` is optional. A glob is unique, repository-relative, contains a
glob character, and has a literal prefix inside a declared write path.

`implementationBoundary.mode` is `disabled` by default. `required` is Linux
only and requires an enabled Harness client.

## Runtime Behavior

`workspace-agent-run <expert-id> -- <client command...>` resolves the Git
worktree root. It mounts the workspace read-only with Bubblewrap and rebinds
only the expert write paths as writable. It uses a private temporary directory
and has no unsandboxed retry path.

Claude Code gets a `PreToolUse` hook for direct Write and Edit tools. OpenCode
gets ordered edit rules that deny all edits before allowing the configured
paths or globs. Codex receives the declared path guidance. A Codex-enabled
expert with `writeGlobs` emits a Nix warning because Codex does not provide a
portable positive write-glob boundary.
