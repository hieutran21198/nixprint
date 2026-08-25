# Artifact-Driven Delivery Workflow Nix Integration Specification

This specification satisfies the
[requirements](../requirements/nix-integration.md).

## Interface

`workspace.integration.artifact-driven-delivery-workflow.build.enabled` is
read-only. Its value is true only when:

```nix
workspace.documentation.model == "artifact-driven"
&& workspace.delivery-workflow.build.enabled
```

The integration module has no external-system options and generates no files.

## Consumers

The delivery-workflow module asserts that its `enable` option requires the
Artifact-Driven Documentation model. It owns GitHub configuration and generated
delivery assets.

The agent Artifact-Driven preset adds the `delivery-workflow` skill only when
the marker and the harness are active. The scope expert receives this skill as
a default workflow preference.

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
