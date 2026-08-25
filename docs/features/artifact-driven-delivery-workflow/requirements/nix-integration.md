# Artifact-Driven Delivery Workflow Nix Integration Requirements

## Outcome

Compose Artifact-Driven Documentation and the delivery workflow without
duplicating provider configuration or generated files.

## Constraints

- The integration marker MUST be read-only and derived from both models.
- Enabling the delivery workflow MUST require Artifact-Driven Documentation.
- Documentation MUST use the fixed `delivery.ticket` front-matter contract.
- The contract MUST NOT expose provider configuration, ticket states, or commands.
- Agent skills MUST require both the integration marker and an enabled harness.

## Acceptance Criteria

- Artifact-Driven-only evaluation leaves the integration inactive.
- Combined evaluation enables the marker and delivery assets.
- A delivery workflow without Artifact-Driven Documentation fails assertion.
- Harness selection changes only generated agent guidance.
