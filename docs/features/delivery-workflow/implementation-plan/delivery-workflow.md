---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/5
---
# Delivery Workflow Implementation Plan

## Inputs

- [Requirements](../requirements/delivery-workflow.md).
- [Specification](../specifications/delivery-workflow.md).
- [GitHub Adapter Decision](../decisions/github-adapter.md).
- [Tasks](../tasks/delivery-workflow.md).

## Change Sequence

1. Compare all canonical statements with the Go and Nix implementation.
2. Correct the standalone documentation-model requirement identified by DW-1.
3. Preserve valid phase, handoff, assignment, adapter, and retry behavior in
   the canonical feature.
4. Rewrite the focused shared governance page.
5. Consolidate operational setup in the service README.
6. Update seed assets, indexes, and direct cross-references.
7. Delete the three former features, duplicate guide, and delivery research.
8. Run the verification defined by DW-6.

## Dependencies

The Artifact-Polyrepo Workspace plan owns general Artifact-Driven governance
and the documentation seed tree. Coordinate seed deletions in one change. The
Agent Harness plan owns the generated `delivery-workflow` skill text.

## Risks and Controls

- Phase handoff constraints can be lost when patch records are removed.
  Compare the canonical specification with `internal/app/app.go` and its tests.
- Logical states can be confused with Project status names. Preserve the
  configured ID mapping and source-state rules.
- The service README can duplicate governance. Keep operational commands and
  provider setup local. Keep authority and lifecycle policy in the wiki.
- Seed workflows can diverge from root workflows. Compare each generated
  workflow after the rewrite.

## Verification

- Run `go test ./...` in `services/delivery-workflow`.
- Run `devenv eval`.
- Compare the three root workflows with their example sources after action
  reference substitution.
- Run Markdown lint and relative-link validation.
- Confirm that the former feature, guide, and research names have no remaining
  references.
