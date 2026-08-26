# Agent Harness Write Boundaries Implementation Plan

This plan implements the [tasks](../tasks/write-boundaries.md).

## Sequence

1. Define typed write paths and globs on implementation experts.
2. Map the expert boundary into generated client assets.
3. Generate the Bubblewrap runner for required Linux mode.
4. Verify configuration validation, client assets, warnings, and filesystem
   enforcement.

## Verification

Run Nix formatting, focused Harness evaluation, Devenv evaluation, a permitted
write test, a denied write test, and whitespace checks.
