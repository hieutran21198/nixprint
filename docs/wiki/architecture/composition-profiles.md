# Workspace Composition Profiles

## Model

Core domains are isolated modules. A composition profile is a concrete
application use case that wraps selected domains. It is not a chain of
pairwise integrations and it does not encode participant combinations in its
directory path.

`artifact-polyrepo-workspace` owns the combined behavior of Artifact-Driven
Documentation, Polyrepo, optional Agent Harness, and optional Delivery
Workflow.

## Ownership

Core domains own their schemas, state, generated files, and direct validation.
The profile owns only the use-case selection, the override policy, and
invariants that exist because the use case combines domains. The Polyrepo
blueprint owns its implementation-expert declarations. Agent Harness maps
experts to native client files.

## Configuration

Select `workspace.composition.use`. Place profile-owned Agent Harness and
Delivery Workflow settings below `workspace.composition`. The profile applies
them at higher priority than ordinary direct settings. With `use = "unset"`,
configure domains directly.

Future profiles are added only for a supported concrete workspace use case.
They do not depend on another profile.
