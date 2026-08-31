---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/20
---
# Evaluation-Time ASCII Report Decision

## Requirement

This decision supports the
[Artifact-Polyrepo Composition Doctor Requirements](../requirements/composition-doctor.md).

## Context

The Composition Doctor must report effective Nix configuration without runtime
diagnostics. Users must be able to read the report in terminals, CI logs, and
copied text. Expert write boundaries can contain long paths and glob patterns.

## Options

1. Generate a static POSIX shell report from the effective Nix configuration.
2. Run Devenv or Nix evaluation when the command starts.
3. Use a full-screen terminal interface or an external table-rendering tool.

## Decision

Generate a static POSIX shell report from the effective Nix configuration. Use
ASCII section headings, a narrow module table, and indented expert records.

## Rationale

The generated report uses the same effective values that generate workspace
assets. It does not repeat configuration evaluation or require runtime tools.
ASCII text remains readable in constrained terminals and copied logs. Indented
records keep long skills, paths, and glob patterns readable without terminal
width logic.

## Consequences

- The command is available without a full-screen terminal interface.
- The command has no external rendering dependency.
- The command does not use color or Unicode characters.
- The report is deterministic when it sorts generated collections.
- The command reports configuration state only. It does not prove runtime
  readiness.

## Specification

See the
[Artifact-Polyrepo Composition Doctor Specification](../specifications/composition-doctor.md).
