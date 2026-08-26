---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/3
---
# Concrete Workspace Profile Decision

## Requirement

This decision supports the
[Artifact-Polyrepo Workspace Requirements](../requirements/artifact-polyrepo-workspace.md).

## Context

Artifact-Driven Documentation, the Polyrepo blueprint, Agent Harness, and
Delivery Workflow can be configured separately. This workspace uses one
specific combination and needs one clear owner for the effective optional
settings.

## Options

1. Keep all domain settings independent and repeat their integration in each
   workspace.
2. Add one concrete profile that selects the required domains and owns its
   optional Agent Harness and Delivery Workflow settings.
3. Add a generic capability registry and derive profiles from it.

## Decision

Use the concrete `artifact-polyrepo-workspace` profile. The profile selects
Artifact-Driven Documentation and the Polyrepo blueprint. It owns its Agent
Harness and Delivery Workflow settings. It maps only explicit Polyrepo
implementation experts.

## Rationale

The concrete profile describes the implemented combination without a generic
composition abstraction. Explicit implementation experts preserve clear
write ownership. Profile-owned settings prevent mixed direct and composed
configuration.

## Consequences

- An unset profile preserves direct domain configuration.
- A selected profile overrides ordinary direct settings for its domains.
- New combinations need a concrete design before implementation.
- The profile does not infer experts or create pairwise integration modules.
- Provider-specific behavior remains in Agent Harness and Delivery Workflow.

## Specification

See the
[Artifact-Polyrepo Workspace Specification](../specifications/artifact-polyrepo-workspace.md).

## Implementation Plan

See the
[Artifact-Polyrepo Workspace Implementation Plan](../implementation-plan/artifact-polyrepo-workspace.md).
