# Workspace Composition Profiles

## Scope

This feature adds concrete workspace composition profiles. A profile groups a
known application use case and owns the effective settings of the domains it
configures.

The first profile is `artifact-polyrepo-workspace`. It requires Artifact-Driven
Documentation and the Polyrepo blueprint. It can also enable Agent Harness and
Delivery Workflow.

## Owner

The workspace configuration maintainer owns this scope. The implementation is
in `services/composition`, `services/blueprint`, `services/agent`, and
`services/delivery-workflow`.

## Documents

- [Requirements](requirements/workspace-composition-profiles.md)
- [Specification](specifications/workspace-composition-profiles.md)
- [Decision](decisions/concrete-composition-profiles.md)
- [Tasks](tasks/workspace-composition-profiles.md)
- [Implementation Plan](implementation-plan/workspace-composition-profiles.md)
