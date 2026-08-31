# Artifact-Polyrepo Composition Doctor Requirements

## Outcome

Provide `workspace-composition-doctor` as a Devenv command. The command helps
users inspect the effective Artifact-Polyrepo Workspace composition.

## Constraints

- The command MUST report the selected composition profile.
- The command MUST report the effective state of Artifact-Driven
  Documentation, the Polyrepo blueprint, Agent Harness, and Delivery Workflow.
- The command MUST identify each configured module as enabled or disabled.
- The command MUST report composition assertions and evaluation warnings.
- The command MUST report whether the profile configuration is valid.
- The command MUST generate an experts matrix only when Agent Harness is
  enabled.
- The experts matrix MUST identify each expert by ID and role.
- The experts matrix MUST identify the source of each expert as `profile` or
  `polyrepo implementation`.
- The experts matrix MUST report each expert's default skills, write paths,
  write globs, and enabled client coverage.
- The command MUST use the effective configuration after profile override
  priorities apply.
- The command MUST NOT start MCP servers or agent clients.
- The command MUST NOT check executable availability, resolve secret values, or
  make network requests.
- The command MUST return a nonzero status when composition assertions fail.

## Acceptance Criteria

- A user can run `devenv shell -- workspace-composition-doctor`.
- The output identifies the selected profile and the effective state of each
  composition module.
- The output identifies failed assertions and evaluation warnings.
- A valid profile reports a successful configuration status.
- An invalid profile causes a nonzero command status and identifies the failed
  check.
- When Agent Harness is enabled, the output contains one experts-matrix row for
  each effective profile expert and configured Polyrepo implementation expert.
- When Agent Harness is disabled, the output states that no experts matrix is
  available.

## Scope

This requirement does not define runtime readiness checks, MCP probes,
secret-value inspection, or a machine-readable output format.
