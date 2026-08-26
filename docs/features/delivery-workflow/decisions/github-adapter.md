---
delivery:
  ticket: https://github.com/hieutran21198/nixprint/issues/3
---
# GitHub Adapter Decision

## Context

The workflow needs external ticket state and repository-native correlation. It must keep workflow phase, ticket classification, and Project status separate.

## Options

1. Store lifecycle state in Markdown.
2. Use GitHub Issues, native sub-issues, pull requests, Projects, and audit comments.
3. Build a hosted workflow database.

## Decision

Use the repository-local `dw` command and GitHub Actions. Use one root Requirement Issue. Use native direct sub-issues for Specification, Decision, and Task tickets. Use the Project `Status` field only for lifecycle state.

For a user-owned Project, use repository labels for classification. For an organization-owned Project, use native Issue Types. Require the selected classifications to exist.

Store machine correlation in artifact front matter, version 2 pull-request records, native sub-issue relationships, and root Requirement audit comments. Do not store a hidden ticket record in an Issue body.

## Rationale

This design uses GitHub-native relationships and keeps each concept independent. One phase record supports atomic validation and retry without a separate database.

## Consequences

- The adapter supports one repository and one Project at a time.
- Operators must create labels or Issue Types before use.
- The adapter does not delete or repurpose unrelated Project statuses.
- A different provider needs an adapter for the same provider-neutral phase rules.

## Specification

See the [Delivery Workflow Specification](../specifications/delivery-workflow.md).
