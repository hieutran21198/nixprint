# Documentation Navigation

## Purpose

This document defines how developers and AI agents find related documentation.

## Indexes

`docs/` MUST have a `README.md` index. Each major documentation area MUST have
a `README.md` index when the area contains documentation.

Each feature folder MUST have a `README.md`. It MUST state:

- The cohesive change scope.
- The scope-level owner.
- Included and excluded concerns.
- Links to its used document areas.

## Traceability

Documentation MUST use relative links with descriptive link text.

Requirements and specifications MUST link to each other when both exist.
Decisions MUST link to the requirements or specifications that motivated them
and to the implementation plan that applies them. Implementation plans MUST
link to their task definitions.

Documents MUST link only to directly related documents. They MUST NOT duplicate
a central traceability matrix.

## Starting Work

Before creating or changing project documentation, a developer or AI agent MUST
start at `docs/README.md`. It MUST then use the relevant area index and, for a
cohesive change, the feature `README.md`.
