# Artifact-Driven Delivery Workflow Nix Integration Specification

This specification satisfies the
[requirements](../requirements/nix-integration.md).

## Interface

Select `workspace.composition.use = "artifact-polyrepo-workspace"`. Configure
Delivery Workflow in `workspace.composition.deliveryWorkflow`. The profile
sets the Artifact-Driven Documentation model, Polyrepo blueprint, and effective
Delivery Workflow configuration. It requires Git hooks when Delivery Workflow
is enabled.

## Consumers

The delivery-workflow module owns GitHub configuration and generated delivery
assets. The profile owns the combined-use-case validation.

The profile adds the `delivery-workflow` skill only when Delivery Workflow and
the harness are active. The scope expert receives this skill as a default
workflow preference.

## Correlation Contract

Documentation review artifacts use this fixed YAML front matter:

```yaml
---
delivery:
  ticket: "<canonical ticket URL>"
---
```

The GitHub adapter writes the URL when it creates a ticket, reuses one URL for
related artifacts, and reads it when it registers a documentation review unit.
