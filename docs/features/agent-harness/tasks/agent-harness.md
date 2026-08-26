---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/5
---
# Agent Harness Tasks

## Scope

These tasks implement the [Agent Harness Specification](../specifications/agent-harness.md).
The execution system owns task status.

## Tasks

### AH-1: Reconcile the Canonical Documents

Compare the canonical requirement, specification, and decision with
`services/agent` and its tests. Correct any statement that is not implemented.
Preserve all current options, generated assets, validation rules, warnings,
secret-reference behavior, and write-boundary semantics.

### AH-2: Fold the Former Feature Records

Move all valid current behavior from these records into the canonical Agent
Harness documents:

- `agent-harness-adapters`.
- `agent-harness-expert-presets`.
- `agent-harness-write-boundaries`.

Do not retain patch sequence, superseded terminology, or duplicate decisions.

### AH-3: Update Service Navigation

Rewrite `services/agent/README.md` as the local implementation entry point.
Use the canonical Agent Harness terms and link to the canonical feature.
Remove links and descriptions for the former feature records.

### AH-4: Delete Superseded Records

Delete the three former Agent Harness feature directories after AH-1 through
AH-3 preserve their valid content.

### AH-5: Verify the Result

Run the Agent Nix module test, `devenv eval`, Markdown lint, link validation,
and a repository-wide obsolete-term search.

## Plan

See the [Agent Harness Implementation Plan](../implementation-plan/agent-harness.md).
