# Workspace Composition Profiles Requirements

## Outcome

Provide one selected workspace profile for a concrete application use case.
The profile must configure its required domains and own the effective settings
of its optional domains.

## Constraints

- Select one profile with `workspace.composition.use`.
- Keep domain modules independent when no profile is selected.
- Do not model participant sets as nested integration paths.
- `artifact-polyrepo-workspace` must select Artifact-Driven Documentation and
  the Polyrepo blueprint.
- Its Agent Harness configuration is optional and requires an enabled client.
- Its Delivery Workflow configuration is optional and requires Git hooks.
- Profile settings must override ordinary direct settings for the domains the
  profile owns.
- Keep Polyrepo implementation experts with the Polyrepo blueprint.

## Acceptance Criteria

- An unset profile preserves direct domain configuration.
- The selected profile overrides direct Agent Harness and Delivery Workflow
  settings.
- The profile generates Artifact-Driven guidance and Polyrepo root guidance.
- Agent guidance is generated only when the profile enables a client.
- Delivery guidance is generated only when the profile enables both Agent
  Harness and Delivery Workflow.
