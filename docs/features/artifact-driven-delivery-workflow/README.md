# Artifact-Driven Delivery Workflow Record

## Scope

This historical scope defines the delivery ticket contract and GitHub adapter.
The current Nix composition is the
[Artifact-Polyrepo Workspace profile](../workspace-composition-profiles/README.md).

## Scope-Level Owner

The workspace documentation maintainer owns this scope.

## Included Concerns

- The provider-neutral `delivery.ticket` front-matter contract.
- GitHub adapter behavior and agent-harness guidance.

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
