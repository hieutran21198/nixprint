# Documentation Ownership

## Purpose

This document defines documentation authority and scope-level ownership.

## Authority

Each topic MUST have one canonical document. Authority follows document type
and scope. It does not follow the most recent edit or the implementation.

- A feature folder owns its cohesive change record.
- The wiki owns system-wide knowledge.
- The glossary owns shared term definitions.

## Scope-Level Ownership

Each feature and each shared knowledge scope MUST have a responsible owner.
The scope owner MUST keep its canonical documentation correct and resolve
conflicts.

Folder-level ownership MAY supplement scope-level ownership. It MUST NOT
replace it.

## Acceptance

Only accepted changes have governance authority. An accepted change MAY create,
update, or supersede canonical documentation.

A rejected change MUST NOT create or revise canonical documentation. Its review
record MAY remain in the delivery workflow, but it has no governance authority.

Requirements, specifications, implementation plans, and task definitions
describe the current accepted scope. They MUST update in place when accepted
scope changes.

## Conflicts

When canonical documents conflict, the responsible scope owner MUST resolve the
conflict in the authoritative document first. Dependent documents MUST then
update their links or derived context.

## Implementation Note

This governance does not require a workflow tool. A Git-based workflow MAY use
pull requests, review, and merge rules to accept documentation changes.
