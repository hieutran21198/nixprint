# Agent Harness Write Boundaries Requirements

## Outcome

Each Polyrepo implementation expert has an enforced repository write boundary.
The boundary works when the developer starts Codex, Claude Code, or OpenCode
through the required runner.

## Constraints

- Require non-empty `writePaths` for each Polyrepo implementation expert.
- Remove `repository` and `implementationArea`. Do not provide aliases.
- Let `writeGlobs` narrow supported client edit policies. They must not expand
  `writePaths`.
- Warn when Codex and `writeGlobs` are both enabled.
- Use a Linux Bubblewrap runner for required cross-client enforcement.
- Fail closed when the runner cannot create the sandbox.

## Acceptance Criteria

- The runner permits declared writes and rejects other repository writes.
- Claude Code and OpenCode receive native direct-edit guardrails.
- Codex receives write-boundary guidance and the required warning.
- The selected composition profile can enable required mode.
