# Artifact-Polyrepo Workspace Architecture

## Purpose

This page explains the implemented workspace composition boundary.

## Canonical Profile

The workspace has one concrete composition profile:
`artifact-polyrepo-workspace`. It selects Artifact-Driven Documentation and
the Polyrepo blueprint. It can also enable Agent Harness and Delivery
Workflow.

A profile represents one supported workspace use case. It is not a generic
capability registry. It does not create pairwise integration modules.

## Domain Ownership

Each domain owns its direct configuration, generated files, and validation.
The profile owns:

- Profile selection.
- Effective Agent Harness and Delivery Workflow settings.
- Validation that exists because the selected domains operate together.
- Mapping of explicit Polyrepo implementation experts into Agent Harness.

The Polyrepo blueprint owns implementation-expert declarations. Agent Harness
owns client asset generation. Delivery Workflow owns GitHub configuration and
workflow assets.

## Configuration

Select the profile and place its optional settings below
`workspace.composition`:

```nix
workspace.composition = {
  use = "artifact-polyrepo-workspace";
  agent.enable = false;
  deliveryWorkflow.enable = false;
};
```

The profile applies its domain settings with Nix override priority 10.
Ordinary direct settings do not replace them. When
`workspace.composition.use = "unset"`, direct domain configuration remains
effective.

The profile requires at least one enabled client when Agent Harness is active.
It requires Git hooks when Delivery Workflow is active.

## Feature Record

See the
[Artifact-Polyrepo Workspace feature](../../features/artifact-polyrepo-workspace/README.md)
for the complete current interface and decisions.
