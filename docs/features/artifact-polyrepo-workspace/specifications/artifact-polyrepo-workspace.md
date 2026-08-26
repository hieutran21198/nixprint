---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/3
---
# Artifact-Polyrepo Workspace Specification

## Requirement

This specification implements the
[Artifact-Polyrepo Workspace Requirements](../requirements/artifact-polyrepo-workspace.md).

## Profile Interface

`workspace.composition.use` accepts `unset` or
`artifact-polyrepo-workspace`. Its default is `unset`.

The selected profile owns two optional configurations:

- `workspace.composition.agent` uses the Agent Harness configuration schema.
- `workspace.composition.deliveryWorkflow` uses the Delivery Workflow
  configuration schema.

The read-only
`workspace.composition.artifactPolyrepoWorkspace.build.enabled` value is true
only when the profile is selected.

## Selection Semantics

When the value is `unset`, direct domain configuration remains effective.

When the value is `artifact-polyrepo-workspace`, the profile sets these domain
values with Nix override priority 10:

```nix
workspace.documentation.model = "artifact-driven";
workspace.blueprint.use = "polyrepo";
workspace.agent.harness = workspace.composition.agent;
workspace.delivery-workflow = workspace.composition.deliveryWorkflow;
```

Ordinary direct definitions do not override these values. A caller can use a
deliberately stronger Nix override. That behavior is part of Nix and is not a
profile interface.

The profile seeds the root `AGENTS.md` and `README.md`. The selected
documentation model and blueprint generate their own governed workspace
files.

## Optional Capability Rules

The Agent Harness and Delivery Workflow are disabled by default.

Agent Harness activation requires at least one of these clients:

- Codex.
- Claude Code.
- OpenCode.

Delivery Workflow activation requires `workspace.git.hooks.enable = true`.
The selected profile always requires Artifact-Driven Documentation and the
Polyrepo blueprint after module evaluation.

## Agent Catalog

When the effective Agent Harness is enabled, the profile adds these experts:

- `scope-expert` resolves authoritative documentation scope and requirement
  acceptance boundaries.
- `technical-expert` reviews decisions and specifications for technical
  correctness.
- Each explicit
  `workspace.blueprint.polyrepo.implementationExperts.<id>` declaration maps
  to one implementation expert with the same description, instructions,
  default skills, write paths, and write globs.

The profile does not infer an expert from a repository category. Each Polyrepo
implementation expert must have at least one validated write path.

The profile also adds these skills with default priority:

- `artifact-driven-authoring`.
- `artifact-driven-coordination`.
- `artifact-driven-technical-review`.
- `semantic-artifact-review`.

It adds `delivery-workflow` only when the effective Agent Harness and profile
Delivery Workflow are both enabled. The profile maps the resulting catalog to
each enabled client through the Agent Harness.

The scope expert selects `artifact-driven-authoring`, `asd-ste100-writing`,
and `artifact-driven-coordination`. It also selects `delivery-workflow` when
that skill is active. The technical expert selects
`artifact-driven-technical-review` and `artifact-driven-coordination`.

## Coordination Rules

The active primary agent remains the coordinator. The coordinator identifies
the accepted authority, delegates only a bounded scope, routes accepted context
to implementation, and collects validation evidence. It does not accept
documents or resolve an authority conflict.

The scope expert identifies the cohesive feature scope and canonical
documents. Scope authority accepts requirements and resolves documentation
authority conflicts. The scope expert does not decide technical correctness or
implementation acceptance.

The technical expert checks decisions and specifications for assumptions,
interfaces, constraints, failure conditions, and verification. It does not
accept requirements, resolve documentation authority, or accept
implementation.

`semantic-artifact-review` is on demand. It checks one document against its
scope, document boundary, terminology, and direct traceability links. It does
not create a review lifecycle or accept the document.

## Failure Conditions

Nix evaluation fails in these cases:

- The selected profile does not resolve to Artifact-Driven Documentation.
- The selected profile does not resolve to the Polyrepo blueprint.
- The profile Agent Harness is enabled without an enabled client.
- The profile Delivery Workflow is enabled without Git hooks.
- A configured Polyrepo implementation expert has an invalid or empty write
  boundary.

## Verification

`services/agent/tests/test-module.sh` verifies profile selection, override
behavior, expert mapping, skill conditions, and invalid combinations.
`devenv eval` verifies the selected profile in this workspace.

## Related Specifications

- [Agent Harness Specification](../../agent-harness/specifications/agent-harness.md)
- [Delivery Workflow Specification](../../delivery-workflow/specifications/delivery-workflow.md)

## Decision

The [Concrete Workspace Profile Decision](../decisions/concrete-workspace-profile.md)
defines the selected composition model.
