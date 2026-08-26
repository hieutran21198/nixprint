# ADR: Use Concrete Composition Profiles

## Context

Artifact-Driven Documentation, Polyrepo, Agent Harness, and Delivery Workflow
are isolated domains. A workspace can require their combined behavior without
making every pair or participant set a separate integration module.

## Decision

Use one concrete composition profile for each supported workspace use case.
The profile is a higher-order configuration boundary. It sets required domain
choices and owns effective configuration for optional domains.

The first profile is `artifact-polyrepo-workspace`. Do not add a generic
capability registry, participant-set directory hierarchy, or compatibility
aliases for retired integration options.

## Consequences

Domain modules keep their direct configuration schemas. The profile reuses
those schemas and applies its settings at a higher priority. A future
Spec-Polyrepo profile can be added when Spec-Driven Documentation exists.

This decision supersedes the current behavior of the historical derived
integration records. Those records remain as history.
