# Artifact-Driven Delivery Workflow Nix Integration Plan

This plan implements the [tasks](../tasks/nix-integration.md).

## Sequence

1. Add the derived integration marker and delivery assertion.
2. Add the front-matter contract to Artifact-Driven governance and generated
   documentation assets.
3. Update the GitHub adapter to create or reuse tickets through that contract.
4. Add the harness-only skill and scope-expert guidance.
5. Run Go tests, focused Nix evaluation, formatting, and whitespace checks.

## Dependencies

- Artifact-Driven Documentation model.
- Delivery-workflow GitHub configuration.
- An enabled harness only for generated expert and skill assets.

## Risks

An artifact write can fail after the adapter creates a ticket. A later draft
run reuses the recorded URL after the artifact write succeeds.

## Verification

Evaluate Artifact-Driven-only, combined delivery configurations with and
without a harness, and delivery without Artifact-Driven Documentation. Test
front-matter writing, parsing, ticket reuse, and agent-skill generation.
