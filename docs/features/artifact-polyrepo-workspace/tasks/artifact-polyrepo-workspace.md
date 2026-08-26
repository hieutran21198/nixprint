---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/5
---
# Artifact-Polyrepo Workspace Tasks

## Scope

These tasks implement the
[Artifact-Polyrepo Workspace Specification](../specifications/artifact-polyrepo-workspace.md).
The execution system owns task status.

## Tasks

### APW-1: Reconcile the Canonical Feature

Compare the canonical feature with `services/composition`,
`services/blueprint/polyrepo`, `services/documentation/artifact-driven`, and
the Agent evaluation tests. Preserve the exact profile interface, override
behavior, assertions, generated root assets, expert mapping, and skill rules.

### APW-2: Fold the Composition Record

Move all valid current behavior from `workspace-composition-profiles` into the
canonical feature. Delete the former feature directory after the valid content
is preserved.

### APW-3: Define One Documentation Governance Model

Fold the valid general rules from the Artifact-Driven governance fragments
into `docs/wiki/governance/documentation/artifact-driven/README.md`. Keep the
Delivery Workflow policy in its focused governance page.

Make current accepted documents canonical. Use Git as change history. Remove
rules that require superseded project documents to remain visible.

### APW-4: Define One Architecture Page

Rewrite `docs/wiki/architecture/README.md` to explain the implemented concrete
workspace profile. Delete `architecture/composition-profiles.md` after its
valid content is preserved.

### APW-5: Remove Research Records

Preserve any valid current governance rule from the centralized-documentation
research page. Then delete the research page. Research history must not remain
in the canonical reader path.

### APW-6: Synchronize Generated Documentation Assets

Update `services/documentation/artifact-driven/default.nix` and its seed assets
to generate the new wiki structure. Remove entries for deleted governance,
guide, and research pages.

### APW-7: Update Navigation

Update `docs/README.md`, `docs/features/README.md`, `docs/wiki/README.md`, the
documentation governance index, and applicable service indexes. Remove all
pending-replacement sections and obsolete links.

### APW-8: Verify the Result

Run Nix evaluation, Markdown lint, link validation, seed-source comparison,
and repository-wide terminology searches.

## Plan

See the
[Artifact-Polyrepo Workspace Implementation Plan](../implementation-plan/artifact-polyrepo-workspace.md).
