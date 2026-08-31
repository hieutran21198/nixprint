---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/19
---
# Artifact-Polyrepo Composition Doctor Specification

## Requirement

This specification implements the
[Artifact-Polyrepo Composition Doctor Requirements](../requirements/composition-doctor.md).

## Command Interface

The workspace provides this Devenv command:

```text
devenv shell -- workspace-composition-doctor
```

The command is available whether `workspace.composition.use` is `unset` or
`artifact-polyrepo-workspace`.

The command reports the effective Nix module configuration. It does not run a
new configuration evaluation. It does not start a process, resolve a secret,
check an executable, or make a network request.

## Configuration Sources

The command reads values after Nix option priorities apply. It reports these
module states:

| Module | Effective value |
| --- | --- |
| Artifact-Driven Documentation | `workspace.documentation.artifact-driven.build.enabled` |
| Polyrepo blueprint | `workspace.blueprint.polyrepo.build.enabled` |
| Agent Harness | `workspace.agent.harness.build.enabled` |
| Delivery Workflow | `workspace.delivery-workflow.build.enabled` |

When Agent Harness is enabled, the command reports the enabled values of:

- `workspace.agent.harness.clients.codex.enable`.
- `workspace.agent.harness.clients.claude.enable`.
- `workspace.agent.harness.clients.opencode.enable`.

The command reports every effective `config.assertions` entry as a check. It
reports every effective `config.warnings` entry as a warning.

## Output

The command writes a human-readable report to standard output. The report uses
ASCII characters only. It uses no ANSI escape sequences, Unicode box-drawing
characters, runtime terminal-width detection, or external table command.

The report uses these sections in this order:

1. Title and configuration status.
2. Selected profile.
3. Module state table.
4. Enabled Agent Harness clients.
5. Configuration checks.
6. Configuration warnings.
7. Experts matrix, when available.
8. Final result.

The module state table uses ASCII borders. It contains only the module name and
its state. The command renders long values as indented list items. It does not
put long values in a fixed-width table.

Each check begins with `[PASS]` or `[FAIL]`. When no warnings exist, the
warnings section contains `- None.`. The final result is `RESULT: VALID` or
`RESULT: INVALID`.

## Experts Matrix

The command renders an experts matrix only when Agent Harness is enabled. The
matrix includes composition-owned experts only:

- `scope-expert` with the `documentation scope` role and the `profile` source.
- `technical-expert` with the `technical review` role and the `profile` source.
- Each effective `workspace.blueprint.polyrepo.implementationExperts.<id>`
  entry with the `implementation` role and the `polyrepo implementation`
  source.

For each expert, the matrix reports the expert ID, role, source, enabled client
coverage, default skills, write paths, and write globs. The command sorts
implementation experts by ID. It preserves the configured order of skills,
write paths, and write globs.

When Agent Harness is disabled, the report states that no experts matrix is
available.

## Status

The configuration is valid only when every effective assertion is true. The
command exits with status `0` for a valid configuration. It exits with status
`1` for an invalid configuration.

## Verification

`services/agent/tests/test-module.sh` verifies command generation, module
states, configuration checks, warnings, experts-matrix values, and invalid
configuration status. `devenv shell -- workspace-composition-doctor` verifies
the configured workspace report.

## Decision

The [Evaluation-Time ASCII Report Decision](../decisions/evaluation-time-ascii-report.md)
defines the selected rendering model.
