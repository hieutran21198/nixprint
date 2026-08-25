# GitHub Delivery Workflow Starter Implementation Plan

## Sequence

1. Build the `dw` Go command and GitHub API adapter.
2. Define the repository-local configuration and PR review-unit record.
3. Add GitHub Actions assets for validation, transition, and reconciliation.
4. Configure a Project, protected acceptance branch, and GitHub App.
5. Verify documentation and implementation transitions in a staging Project.

## Dependencies

- A GitHub organization Project with a single-select status field.
- A `DW_GITHUB_TOKEN` repository secret with access to pull requests, Issues,
  and the configured GitHub Project.
- A protected acceptance branch with required repository checks.

## Risks

- GitHub Actions delivery can fail. Scheduled and manual reconciliation reduce
  this risk.
- A manual Project update can create an unexpected state. `dw` stops instead
  of overwriting it.

## Verification

Run unit tests for configuration and review-unit records. Run a staging Project
through Draft, Ready, In Progress, implementation acceptance, and explicit
rejection transitions.
