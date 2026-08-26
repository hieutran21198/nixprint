# GitHub Delivery Workflow Setup

## Purpose

This guide configures the GitHub starter for the Artifact-Driven Delivery
Workflow.

## Prerequisites

- A GitHub repository.
- A GitHub Project with a single-select `Status` field.
- A protected acceptance branch.
- A personal access token (PAT) for workflow automation.

## Configure the Project

Create status values that map to the workflow semantics. The value names are
your choice.

For example:

| Workflow semantic | GitHub Project value |
| --- | --- |
| Draft | Draft |
| Ready | Todo |
| In Progress | In Progress |
| Archived | Archived |
| Implementation acceptance | Ready For Testing |

For a user-owned Project, use a classic PAT with these scopes:

- `repo`
- `read:org`
- `read:project`
- `project`

Store the PAT as the `DW_GITHUB_TOKEN` repository secret. Do not store it in
the repository, Nix configuration, or `.dw/config.yaml`.

## Discover Project Values

Run `dw init` with a user token. Set the owner type to `user` for a personal
Project or `organization` for an organization Project.

```text
dw init \
  --config /tmp/dw-config.yaml \
  --repository OWNER/REPOSITORY \
  --project-owner-type user \
  --project-owner OWNER \
  --project PROJECT_NUMBER
```

Select the five Project values. Copy the generated Project, field, and option
IDs to `workspace.composition.deliveryWorkflow` in `devenv.local.nix`. Select
the Artifact-Polyrepo Workspace profile at the same level.

For a user-owned Project, set `authorizerUsers`. For an organization Project,
you can set `authorizerTeams`.

## Generate Repository Files

Set `workspace.composition.use = "artifact-polyrepo-workspace"` and
`workspace.composition.deliveryWorkflow.enable = true`. The profile owns the
effective Delivery Workflow settings and requires enabled Git hooks. The option
seeds:

- `.dw/config.yaml`
- `.github/workflows/dw-validate.yml`
- `.github/workflows/dw-transition.yml`
- `.github/workflows/dw-reconcile.yml`

Review and commit these files. They use `DW_GITHUB_TOKEN` for accepted-merge
transitions and reconciliation.

## Protect the Acceptance Branch

Require the applicable reviews and CI checks on the acceptance branch. Add the
delivery-workflow validation check after authors use `dw register` for all
in-scope PRs.

## Use the Workflow

For Phase 1, list eligible assignees and create the Requirement ticket with
one to ten selected requirement owners. For the next phases, hand off only a
Ready predecessor. The Phase 2 assignee is the technical lead. The Phase 3
assignees are the builders.

```text
dw assignees
dw draft --phase requirement --title "Requirement title" --artifact PATH --assignee OWNER
dw handoff --predecessor ISSUE_OR_URL --phase specs-adrs --artifact PATH --assignee TECHNICAL_LEAD
dw handoff --predecessor ISSUE_OR_URL --phase tasks-plan --artifact PATH --assignee BUILDER
```

For implementation, start the ticket before you register the implementation
PR.

```text
dw start --issue ISSUE_NUMBER
dw register --pr PR_NUMBER --issue ISSUE_NUMBER --phase implementation
```

`dw start` reuses the builders assigned to the accepted Ready task ticket. It
does not accept or change assignees.

An accepted implementation merge moves the ticket to the configured
implementation-acceptance value. Testing, QA, UAT, and release validation can
move it to `Done` later.
