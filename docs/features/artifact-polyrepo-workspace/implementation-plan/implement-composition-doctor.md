---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/22
---
# Implement Composition Doctor Plan

## Task

This plan implements the
[Implement Composition Doctor Task](../tasks/implement-composition-doctor.md).

## Change Sequence

1. Add `workspace-composition-doctor` to `services/composition/default.nix`.
   Define the command outside the selected profile condition. This makes the
   command available when `workspace.composition.use` is `unset`.
2. Generate the command content from effective Nix configuration values. Use
   the four specified `build.enabled` values for module states. Use effective
   Agent Harness client values, `config.assertions`, and `config.warnings` for
   the remaining report values.
3. Render the report with shell-safe `printf` statements. Use ASCII section
   headings, a narrow module table, list items for long values, and indented
   expert records. Do not add a runtime dependency, ANSI formatting, Unicode,
   JSON output, or terminal-width logic.
4. Render only composition-owned experts. Render `scope-expert` and
   `technical-expert` from the profile. Render explicit Polyrepo implementation
   experts in sorted ID order. Preserve the configured order of skills, write
   paths, and write globs.
5. Calculate the result from every effective assertion. Print `RESULT: VALID`
   and return status `0` when all assertions pass. Print `RESULT: INVALID` and
   return status `1` when an assertion fails.
6. Extend `services/agent/tests/eval.nix` to verify the generated command for
   unset, enabled, warning, and invalid configurations. Run the focused module
   test and the configured workspace command.

## Dependencies

- The [Composition Doctor Specification](../specifications/composition-doctor.md)
  and the
  [Evaluation-Time ASCII Report Decision](../decisions/evaluation-time-ascii-report.md)
  are accepted.
- The implementation belongs to the `services` repository category and the
  `services/composition` scope.

## Risks

- Devenv can reject a failed Nix assertion before it starts a generated command.
  Verify an invalid configuration with an evaluation fixture that executes the
  generated command. The fixture must show the failed check and status `1`.
- Assertion and warning messages can be long. Keep them as one list item per
  message. Do not place them in a fixed-width table.
- A direct Agent Harness expert can exist outside the composition-owned expert
  set. Do not render that expert in this command.

## Verification Approach

- `bash services/agent/tests/test-module.sh` passes.
- The evaluation tests verify profile selection, module states, checks,
  warnings, clients, experts, sorting, and status behavior.
- `devenv shell -- workspace-composition-doctor` produces the valid configured
  workspace report.
- The invalid-configuration fixture produces `[FAIL]`, `RESULT: INVALID`, and
  status `1`.
