# ADR: Use a Shared Write-Boundary Runner

## Context

Codex, Claude Code, and OpenCode have different permission systems. OpenCode
does not restrict arbitrary shell writes with its agent edit policy.

## Decision

Use concrete `writePaths` as the required implementation boundary. Use one
Linux Bubblewrap runner to enforce the same boundary for every supported
client. Generate client-native edit guardrails as additional protection.

`writeGlobs` narrow direct edits only. They do not replace `writePaths`.

## Consequences

The required mode fails on unsupported platforms or when Bubblewrap cannot
create a sandbox. Developers must start implementation work through the
generated runner to receive the cross-client guarantee.
