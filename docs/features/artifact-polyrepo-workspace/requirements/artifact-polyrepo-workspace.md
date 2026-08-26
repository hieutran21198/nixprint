---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/1
---
# Artifact-Polyrepo Workspace Requirements

## Outcome

Provide one concrete workspace profile that configures Artifact-Driven
Documentation and the Polyrepo blueprint. Let the profile own the effective
Agent Harness and Delivery Workflow settings when those optional capabilities
are selected.

## Constraints

- `workspace.composition.use` MUST select at most one concrete profile.
- An unset profile MUST preserve direct domain configuration.
- The Artifact-Polyrepo Workspace profile MUST select Artifact-Driven
  Documentation and the Polyrepo blueprint.
- The profile MUST own its effective Agent Harness and Delivery Workflow
  settings.
- Profile-owned settings MUST override ordinary direct settings for the same
  domains.
- Agent Harness activation MUST require at least one enabled client.
- Delivery Workflow activation MUST require enabled Git hooks.
- Polyrepo implementation experts MUST use explicit non-empty write paths.
- The profile MUST map only explicitly configured implementation experts.
- The profile MUST add Artifact-Driven scope and technical experts only when
  Agent Harness is active.
- Delivery Workflow agent guidance MUST require both Agent Harness and
  Delivery Workflow.
- The profile MUST NOT infer experts from repository categories or create
  pairwise integration modules.

## Acceptance Criteria

- The selected profile generates Artifact-Driven documentation and Polyrepo
  workspace guidance.
- Optional Agent Harness and Delivery Workflow settings remain disabled by
  default.
- Agent activation generates the canonical experts and workflow skills for
  each enabled client.
- Configured Polyrepo implementation experts retain their instructions,
  skills, write paths, and write globs.
- Delivery Workflow activation generates its repository configuration and
  GitHub Actions assets.
- Invalid optional-capability combinations fail Nix evaluation.
- A deliberately stronger Nix override remains outside the profile contract.
