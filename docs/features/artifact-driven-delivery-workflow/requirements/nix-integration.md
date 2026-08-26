# Artifact-Driven Delivery Workflow Nix Integration Requirements

## Outcome

The Artifact-Polyrepo Workspace profile composes Artifact-Driven Documentation
and Delivery Workflow without duplicating provider configuration or generated
files.

## Constraints

- The selected profile MUST own the effective Delivery Workflow settings.
- Profile Delivery Workflow MUST require Git hooks.
- Documentation MUST use the fixed `delivery.ticket` front-matter contract.
- The contract MUST NOT expose provider configuration, ticket states, or commands.
- Agent skills MUST require profile Delivery Workflow and an enabled harness.

## Acceptance Criteria

- A selected profile with optional features disabled remains valid.
- A selected profile with Delivery Workflow enables delivery assets.
- Profile Delivery Workflow with Git hooks disabled fails assertion.
- Harness selection changes only generated agent guidance.
