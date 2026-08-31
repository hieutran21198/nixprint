---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/22
---
# Implement Composition Doctor Task

## Requirement

This task implements the
[Artifact-Polyrepo Composition Doctor Requirements](../requirements/composition-doctor.md).
The [Composition Doctor Specification](../specifications/composition-doctor.md)
defines the command behavior. The
[Evaluation-Time ASCII Report Decision](../decisions/evaluation-time-ascii-report.md)
defines the rendering model.

## Work

- Add `workspace-composition-doctor` to the composition module.
- Generate the report from effective Nix configuration values.
- Render the required ASCII module state table, checks, warnings, client list,
  and experts matrix.
- Return status `0` for a valid configuration and status `1` for an invalid
  configuration.
- Extend the focused module evaluation tests for the generated command.
- Verify the report in the configured workspace.

The [Implementation Plan](../implementation-plan/implement-composition-doctor.md)
defines the change sequence, risks, and verification approach.
