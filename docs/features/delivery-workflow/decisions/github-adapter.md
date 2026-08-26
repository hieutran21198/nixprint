---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/3
---
# GitHub Adapter Decision

## Requirement

This decision supports the
[Delivery Workflow Requirements](../requirements/delivery-workflow.md).

## Context

Artifact-Driven documentation needs ordered review handoffs and traceability.
The current repository uses GitHub Issues, pull requests, Projects, and
Actions. The workflow must verify external state before it changes a ticket.

## Options

1. Store workflow state only in Markdown and depend on manual ticket changes.
2. Implement a GitHub adapter that stores portable correlation records in
   artifacts, Issues, and pull requests.
3. Build a hosted event service and separate workflow database.

## Decision

Use a repository-local `dw` command and a GitHub composite action. Use GitHub
Issues as tickets and one GitHub Project status field as the execution state.
Keep the workflow phase and correlation records provider-neutral in their
Markdown and comment formats.

## Rationale

This boundary uses the repository's current delivery system. It makes each
transition conditional on current pull-request and ticket state. It also
supports retry without a separate service or database.

## Consequences

- The adapter supports one repository and one Project at a time.
- Status names can differ, but configured option IDs define the semantics.
- Operators and Actions need suitable GitHub tokens.
- Repository configuration stores identifiers, not credentials.
- A different provider needs a new adapter for the same phase semantics.
- Testing, release, and deployment remain outside this workflow.

## Specification

See the [Delivery Workflow Specification](../specifications/delivery-workflow.md).
