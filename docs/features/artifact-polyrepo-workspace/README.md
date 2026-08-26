# Artifact-Polyrepo Workspace

## Scope

This feature defines the concrete workspace profile that combines
Artifact-Driven Documentation and the Polyrepo blueprint. It can also compose
Agent Harness and Delivery Workflow configuration.

## Scope-Level Owner

The workspace configuration maintainer owns this scope. The implementation
belongs to the `services` repository category and to `services/composition`,
`services/documentation`, `services/blueprint`, `services/agent`, and
`services/delivery-workflow`.

## Included Concerns

- Concrete profile selection.
- Profile-owned domain configuration and validation.
- Artifact-Driven documentation and Polyrepo root guidance.
- Documentation experts, technical experts, implementation experts, and
  workflow skills.

## Excluded Concerns

- Generic participant or capability registries.
- Direct domain configuration when no profile is selected.
- Provider-specific Delivery Workflow behavior.

## Documents

- [Requirements](requirements/artifact-polyrepo-workspace.md)
- [Specification](specifications/artifact-polyrepo-workspace.md)
- [Concrete Workspace Profile Decision](decisions/concrete-workspace-profile.md)
- [Tasks](tasks/artifact-polyrepo-workspace.md)
- [Implementation Plan](implementation-plan/artifact-polyrepo-workspace.md)
