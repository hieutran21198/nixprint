# Workspace

This workspace uses a polyrepo layout and an artifact-driven documentation
model.

## Before Work Starts

1. Read [Polyrepo Governance](docs/wiki/governance/polyrepo.md).
2. Read [Artifact-Driven Documentation Governance](docs/wiki/governance/documentation/artifact-driven/README.md).
3. Identify the cohesive change scope.
4. Identify the repository category that owns the implementation.

## Work Flow

Define and maintain the change scope in `docs/features/<scope-id>/`.

Keep system-wide knowledge in `docs/wiki/`. Keep defined terms in
`docs/glossary/`.

Implement the change in the applicable `apps/`, `services/`, `libs/`, or
`deployment/` repository. Keep implementation rules in that repository.
