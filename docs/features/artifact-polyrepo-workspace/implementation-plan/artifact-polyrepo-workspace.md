---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/5
---
# Artifact-Polyrepo Workspace Implementation Plan

## Inputs

- [Requirements](../requirements/artifact-polyrepo-workspace.md).
- [Specification](../specifications/artifact-polyrepo-workspace.md).
- [Concrete Workspace Profile Decision](../decisions/concrete-workspace-profile.md).
- [Tasks](../tasks/artifact-polyrepo-workspace.md).

## Change Sequence

1. Compare the profile specification with the Nix modules and tests.
2. Fold the former composition feature into the canonical feature.
3. Consolidate general Artifact-Driven governance into one current model.
4. Rewrite the architecture index as the canonical profile explanation.
5. Move any still-valid research conclusions into canonical governance.
6. Update documentation seed files and their Nix file tree.
7. Delete superseded composition, governance-fragment, architecture, and
   research artifacts.
8. Update every documentation and service index.
9. Run the verification defined by APW-8.

## Dependencies

The Agent Harness plan owns provider-specific assets and expert boundaries.
The Delivery Workflow plan owns its focused governance, former feature
records, setup guidance, and delivery-specific research.

## Risks and Controls

- Governance consolidation can remove an active location or ownership rule.
  Check every source rule before deletion.
- Seed assets can recreate removed pages. Update `default.nix` and the asset
  tree in the same change.
- Profile behavior can be confused with direct domain configuration. Keep the
  `unset` behavior and priority-10 override semantics explicit.
- A deleted research page can contain a current constraint. Move only the
  implemented or still-governing constraint before deletion.

## Verification

- Run `bash services/agent/tests/test-module.sh`.
- Run `devenv eval`.
- Evaluate `services/documentation/artifact-driven/default.nix` through the
  integrated workspace.
- Compare generated documentation paths with the canonical wiki paths.
- Run Markdown lint and relative-link validation.
- Confirm that deleted page names and the former feature name have no
  remaining references.
