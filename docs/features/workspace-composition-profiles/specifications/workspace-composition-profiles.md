# Workspace Composition Profiles Specification

This specification satisfies the
[requirements](../requirements/workspace-composition-profiles.md).

## Public Configuration

```nix
workspace.composition = {
  use = "unset"; # or "artifact-polyrepo-workspace"
  agent = {
    enable = false;
    clients.codex.enable = false;
  };
  deliveryWorkflow.enable = false;
};
```

`agent` uses the Agent Harness configuration schema. `deliveryWorkflow` uses
the Delivery Workflow configuration schema.

## Profile Behavior

When `use = "artifact-polyrepo-workspace"`, the profile sets these effective
values with Nix override priority 10:

- `workspace.documentation.model = "artifact-driven"`
- `workspace.blueprint.use = "polyrepo"`
- `workspace.agent.harness = workspace.composition.agent`
- `workspace.delivery-workflow = workspace.composition.deliveryWorkflow`

An ordinary direct setting has lower priority and does not change the selected
profile. A deliberately stronger Nix priority is an explicit escape hatch and
is outside this profile contract.

The profile adds Artifact-Driven scope and technical experts only when its
Agent Harness has an enabled client. It maps
`workspace.blueprint.polyrepo.implementationExperts` into that generated
expert catalog. It adds Delivery Workflow guidance only when both optional
features are enabled.

## Validation

Profile Agent Harness requires one enabled client. Profile Delivery Workflow
requires `workspace.git.hooks.enable = true`. Delivery Workflow validates its
GitHub configuration only when it is enabled.
