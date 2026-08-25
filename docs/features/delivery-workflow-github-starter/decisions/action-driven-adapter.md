# ADR: Action-Driven GitHub Adapter

## Context

The first adapter needs merge-driven ticket updates. A hosted webhook service
would add deployment and event-store work before the initial workflow is usable.

## Options

1. Use a hosted GitHub App webhook service.
2. Use local commands and GitHub Actions.
3. Use local commands only.

## Decision

Use local `dw` commands and GitHub Actions. Use the `DW_GITHUB_TOKEN`
repository secret for Actions. Use an operator token for local commands.

## Rationale

This design has no service deployment. It supports user-owned Projects without
GitHub App setup. It retains merge verification and a scheduled reconciliation
path.

## Consequences

The first adapter stores review-unit and audit data in GitHub. It does not
provide a separate event database or webhook receiver.
