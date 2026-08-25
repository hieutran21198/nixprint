# Documentation Structure

## Purpose

This document defines the top-level documentation structure.

## Structure

```text
docs/
├── features/
│   └── <feature-id>/
│       ├── requirements/
│       ├── specifications/
│       ├── decisions/
│       ├── tasks/
│       └── implementation-plan/
├── wiki/
└── glossary/
```

`features/` contains the record for each cohesive change scope. A feature can
be user-facing, cross-cutting, technical, or operational.

`wiki/` contains system-wide knowledge. `glossary/` contains shared terms and
abbreviations.

## Feature Identifiers

A feature folder name MUST be its stable identifier. It MUST:

- Be unique in `docs/features/`.
- Use lowercase ASCII letters, digits, and hyphens.
- Describe the cohesive change scope.
- Remain unchanged after the feature is accepted.
- Not use an execution-system identifier.

When a name conflict occurs, the new identifier MUST use a more specific scope
name.

## Feature Areas

A feature folder MUST use the five area names in this document. It MUST create
an area only when the cohesive change requires that document type. It MUST NOT
create unused empty areas.
