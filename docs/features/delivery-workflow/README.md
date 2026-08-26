# Delivery Workflow

## Scope

This feature defines the Artifact-Driven Delivery Workflow and its GitHub
adapter. It correlates documentation and implementation review units with
execution-system tickets.

## Scope-Level Owner

The Delivery Workflow service maintainer owns this scope. The implementation
belongs to the `services` repository category and to
`services/delivery-workflow`.

## Included Concerns

- Provider-neutral workflow phases and ticket-state semantics.
- Artifact, ticket, and pull-request correlation.
- Ordered documentation handoffs and assignment validation.
- GitHub Issues, GitHub Projects, GitHub Actions, and the `dw` command.
- Nix-generated adapter configuration and workflow assets.

## Excluded Concerns

- Post-implementation testing, quality assurance, release, and deployment.
- A hosted webhook service or separate event database.
- Provider-specific behavior outside the GitHub adapter.

## Documents

- [Requirements](requirements/delivery-workflow.md)
- [Shared Delivery Workflow Governance](../../wiki/governance/documentation/artifact-driven/delivery-workflow.md)
