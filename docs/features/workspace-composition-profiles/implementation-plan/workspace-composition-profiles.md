# Workspace Composition Profiles Implementation Plan

This plan implements the
[tasks](../tasks/workspace-composition-profiles.md).

## Sequence

1. Share typed configuration schemas between direct modules and the profile.
2. Add `workspace.composition` and select one concrete profile by enum.
3. Apply profile-owned domain settings with override priority 10.
4. Move Artifact-Driven, Polyrepo, Agent, and Delivery Workflow combined
   behavior into the Artifact-Polyrepo profile.
5. Remove the old integration modules without compatibility aliases.
6. Test profile overrides, optional behavior, validation failures, and unset
   direct configuration.

## Verification

Run Nix formatting, parsing, focused evaluation, documentation validation, and
whitespace checks.
