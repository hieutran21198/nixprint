---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/5
---
# Delivery Workflow Tasks

## Scope

These tasks implement the
[Delivery Workflow Specification](../specifications/delivery-workflow.md).
The execution system owns task status.

## Tasks

### DW-1: Reconcile the Canonical Documents

Compare the requirement, specification, and decision with the Go command,
configuration schema, GitHub client, composite action, Nix module, workflows,
and tests. Remove the requirement that the standalone Nix module inspects the
documentation model, because the implementation does not enforce it. Keep the
Artifact-Polyrepo Workspace composition rule.

### DW-2: Fold the Former Feature Records

Move all valid current behavior from these records into the canonical Delivery
Workflow documents:

- `artifact-driven-delivery-workflow`.
- `delivery-workflow-github-starter`.
- `agent-phase-handoff-assignment`.

Delete the former feature directories after their valid behavior is preserved.

### DW-3: Rewrite Shared Workflow Governance

Rewrite the shared Delivery Workflow governance page around the four current
phases, artifact authority, assignment responsibility, permitted transitions,
and implementation acceptance. Keep command and adapter details in the feature
specification and service README.

### DW-4: Consolidate Setup Guidance

Preserve current GitHub token, Project, Action, and setup instructions in
`services/delivery-workflow/README.md`. Then delete the duplicate wiki setup
guide and delivery-workflow research page.

### DW-5: Update Generated Assets and Navigation

Remove the deleted guide and research assets from the Artifact-Driven
documentation seed. Update `services/README.md`, the Delivery Workflow service
README, and all documentation indexes and cross-references.

### DW-6: Verify the Result

Run the Delivery Workflow Go tests, `devenv eval`, Markdown lint, link
validation, generated-workflow comparison, and obsolete-term searches.

## Plan

See the [Delivery Workflow Implementation Plan](../implementation-plan/delivery-workflow.md).
