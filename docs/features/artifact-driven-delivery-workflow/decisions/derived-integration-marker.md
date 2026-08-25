# ADR: Use a Derived Integration Marker

## Context

Delivery ticket correlation depends on Artifact-Driven feature artifacts. The
agent harness needs to know when both models are active. The harness itself
must not control the integration.

## Considered Options

- Add a configurable integration enable option.
- Derive one read-only integration marker from both models.

## Decision

Derive `workspace.integration.artifact-driven-delivery-workflow.build.enabled`
from the Artifact-Driven Documentation model and delivery-workflow build.

## Rationale

The marker cannot represent a partial configuration. It is available to every
consumer, including configurations without an agent harness.

## Consequences

The GitHub adapter remains the only owner of GitHub configuration and generated
delivery assets. The integration module has no provider options or files.
