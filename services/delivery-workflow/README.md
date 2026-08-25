# Delivery Workflow Service

`dw` is the GitHub starter adapter for the Artifact-Driven Delivery Workflow.
It supports one GitHub repository and one user-owned or organization GitHub
Project.

The tool uses GitHub Issues as tickets. It uses the Project `Status` field for
workflow semantics. Status names are configured values. They are not required
names.

## Setup

1. Create a user-owned or organization GitHub Project with a single-select
   `Status` field.
2. Create a personal access token (PAT) with access to the repository and
   Project. Store it as the `DW_GITHUB_TOKEN` repository secret.
3. Protect the acceptance branch with the applicable reviews and CI checks.
4. Run `dw init` in the managed repository. The command lists the available
   Project statuses and writes `.dw/config.yaml` with the selected option IDs.
5. Add an authorization rule. Use `authorizer_teams` for an organization
   Project or `authorizer_users` for a user-owned Project.
6. Add the example validation, transition, and reconciliation workflows.

Use an operator token through `GH_TOKEN` or the GitHub CLI for local commands.
Use `DW_GITHUB_TOKEN` in GitHub Actions for transition and reconciliation.

For a user-owned Project, use a classic PAT with `repo`, `read:org`,
`read:project`, and `project` scopes. The token is a GitHub Actions secret. Do
not store it in `.dw/config.yaml` or Nix configuration.

## Commands

```text
dw draft --phase requirement --title "Document the requirement" --artifact docs/features/example/requirements/requirement.md
dw register --pr 42 --issue 17 --phase requirement --artifact docs/features/example/requirements/requirement.md
dw start --issue 17
dw register --pr 43 --issue 17 --phase implementation
dw reject --pr 42 --reason "The requirement is not accepted."
```

`dw transition` processes a merged pull request. It does not archive an
unmerged pull request. An implementation merge moves a ticket to the configured
implementation-acceptance status. That status can be `Done`, `Ready to Test`,
or another Project value.

`dw reconcile` rechecks closed merged pull requests for the configured
acceptance branch. The example schedules it daily and also permits a manual
run.

## Configuration

See [the GitHub configuration example](examples/github/dw.config.yaml). The
configuration stores GitHub Project field and option IDs. It does not store a
token or GitHub App private key.

The `sources` list permits an execution system to use an intermediate status
as a valid source for a transition. For example, `states.draft.sources` can
include both Draft and Code Review Project option IDs.

## Nix Configuration

Set `workspace.delivery-workflow.enable = true` to seed `.dw/config.yaml` and
the GitHub Actions workflow files. Configure the GitHub Project IDs and the
state option IDs in the same Nix configuration.

```nix
workspace.delivery-workflow = {
  enable = true;
  github = {
    repository = "example/example-service";
    project = {
      owner = "example";
      ownerType = "organization";
      number = 1;
      id = "PVT_kwDOExample";
      statusFieldId = "PVTSSF_example";
    };
  };
  authorizerTeams = [ "delivery-maintainers" ];
  states = {
    draft = { id = "draft-option-id"; sources = [ "draft-option-id" ]; };
    ready = { id = "ready-option-id"; sources = [ "ready-option-id" ]; };
    inProgress = { id = "in-progress-option-id"; sources = [ "in-progress-option-id" ]; };
    archived = { id = "archived-option-id"; sources = [ "archived-option-id" ]; };
    implementationAccepted = {
      id = "ready-to-test-option-id";
      sources = [ "ready-to-test-option-id" ];
    };
  };
};
```

For a user-owned Project, set `ownerType = "user"` and set
`authorizerUsers = [ "YOUR_GITHUB_LOGIN" ];`.
