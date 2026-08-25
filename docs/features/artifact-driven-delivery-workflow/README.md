# Artifact-Driven Delivery Workflow Integration

## Scope

This scope defines the Nix composition between Artifact-Driven Documentation,
the GitHub delivery-workflow adapter, and optional agent guidance.

## Scope-Level Owner

The workspace documentation maintainer owns this scope.

## Included Concerns

- A read-only Nix integration marker.
- The provider-neutral `delivery.ticket` front-matter contract.
- GitHub adapter activation and agent-harness consumers.

## Excluded Concerns

- GitHub Project and ticket configuration outside `workspace.delivery-workflow`.
- A second copy of generated delivery files.

## Documents

- [Requirements](requirements/nix-integration.md)
- [Specification](specifications/nix-integration.md)
- [Decision](decisions/derived-integration-marker.md)
- [Tasks](tasks/nix-integration.md)
- [Implementation Plan](implementation-plan/nix-integration.md)
- [Delivery Workflow Governance](../../wiki/governance/documentation/artifact-driven/delivery-workflow.md)
- [Research Requirement](requirements/delivery-workflow-integration-research.md)
- [Shared Research](../../wiki/research/artifact-driven-execution-system-governance.md)
