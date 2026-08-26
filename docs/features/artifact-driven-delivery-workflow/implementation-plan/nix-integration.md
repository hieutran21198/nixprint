# Artifact-Driven Delivery Workflow Nix Integration Plan

This plan implements the [tasks](../tasks/nix-integration.md).

## Sequence

1. Add the Artifact-Polyrepo Workspace profile and its delivery assertion.
2. Add the front-matter contract to Artifact-Driven governance and generated
   documentation assets.
3. Update the GitHub adapter to create or reuse tickets through that contract.
4. Add the harness-only skill and scope-expert guidance.
5. Run Go tests, focused Nix evaluation, formatting, and whitespace checks.

## Dependencies

- The Artifact-Polyrepo Workspace profile.
- Delivery Workflow GitHub configuration.
- An enabled harness only for generated expert and skill assets.

## Risks

An artifact write can fail after the adapter creates a ticket. A later draft
run reuses the recorded URL after the artifact write succeeds.

## Verification

Evaluate the profile with optional delivery and harness configurations. Test
front-matter writing, parsing, ticket reuse, and agent-skill generation.
