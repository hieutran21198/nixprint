# Polyrepo Governance

## Purpose

Polyrepo Governance defines how the system organizes and governs multiple
repositories. It defines the boundary between centralized project knowledge
and repository implementation.

This governance gives developers and AI agents one consistent model.

## Why

A polyrepo system can become difficult to manage when project knowledge and
implementation rules have no clear boundary. This can disconnect requirements
from implementation. It can also duplicate documentation and make repository
responsibilities unclear.

Polyrepo Governance separates centralized project knowledge from repository
implementation. This separation helps developers and AI agents find the
correct location for a change.

## Goals

Polyrepo Governance has these goals:

- Define a common high-level model for a polyrepo system.
- Define repository categories and responsibilities.
- Define the boundary between centralized knowledge and implementation.
- Keep project knowledge and governance centralized.
- Keep implementation concerns in project repositories.
- Help developers and AI agents identify where a change belongs.

## Non-Goals

This governance does not define the internal lifecycle of an individual
repository. It does not define:

- Branching strategy.
- Release process.
- Versioning policy.
- Deployment lifecycle.
- Repository-specific development or review workflow.
- Application architecture or business logic.
- Service or deployment implementation.
- Tool-specific implementation details.

Each repository MAY define local implementation rules when required.

## Scope

This governance applies to repository categories, responsibilities, and
boundaries. It also applies to centralized knowledge, shared governance,
cross-repository relationships, and AI agent guidance.

## Canonical Location

This document MUST be stored at `docs/wiki/governance/polyrepo.md`. This file
is the canonical governance document for polyrepo organization.

## Writing Standard

All governance documentation MUST follow ASD-STE100 principles. Writers and
AI agents MUST use clear and controlled technical English. They MUST:

- Use short and direct sentences.
- Use one main idea in each sentence.
- Use active voice when possible.
- Use the same term for the same concept.
- Avoid unnecessary synonyms.
- Avoid vague words.
- Avoid unnecessary adjectives and adverbs.
- Avoid idioms and informal expressions.
- Define abbreviations before use.
- Define domain-specific terms when required.
- Use lists when they improve clarity.
- Use normative terms consistently.

Writers and AI agents MUST NOT change the meaning of a requirement to simplify
the language. Clarity has priority over style. Consistency has priority over
variation.

## Normative Terms

The terms in this document have these meanings:

- `MUST` defines a mandatory rule.
- `MUST NOT` defines a prohibited rule.
- `SHOULD` defines a recommended rule.
- `SHOULD NOT` defines a discouraged rule.
- `MAY` defines an optional rule.

## Workspace Responsibility

The workspace is the centralized source for project knowledge and governance.
It contains requirements, specifications, decisions, tasks, and implementation
plans.

System knowledge, repository knowledge, and governance MUST remain in the
workspace. The workspace defines shared knowledge, planning, and governance.

## Repository Responsibility

Project repositories contain implementation artifacts. They can contain source
code, build configuration, development configuration, and project-specific
rules. They can also contain naming, formatting, and spacing rules.

A repository boundary defines implementation ownership. It does not define
documentation ownership.

Project repositories MUST NOT duplicate centralized project knowledge or
governance.

## Repository Categories

The system uses these repository categories:

| Category | Responsibility |
| --- | --- |
| `apps` | Application projects, such as web and mobile applications. |
| `deployment` | Deployment concerns. |
| `docs` | Centralized knowledge and governance. |
| `libs` | Shared libraries used across projects. |
| `services` | Backend services. |

A repository MUST belong to one clear category. A repository MUST NOT accept
unrelated concerns without an explicit governance decision.

## Governance Principles

### Clear Responsibility

Each repository MUST have one clear primary implementation responsibility.

### Clear Boundaries

Repository boundaries MUST reflect implementation responsibilities. A
repository MUST NOT own a concern only because it is convenient to place the
concern there.

### Repository Autonomy

Each repository controls its implementation details and local project rules.
Polyrepo Governance MUST NOT define repository-specific lifecycle rules unless
those rules affect other repositories.

### Centralized Knowledge

System and repository knowledge and governance MUST remain centralized.
Implementation repositories MUST NOT duplicate this information. This rule
reduces conflicting and duplicated documentation.

### Consistent Navigation

Before implementation work starts, a developer or AI agent MUST be able to
determine:

- What the repository implements.
- What the repository does not implement.
- Where related project knowledge exists.
- Which repositories relate to the current repository.

## Expected Outcome

The workspace contains centralized knowledge, planning, and governance.
Project repositories contain implementation and local project rules.

Developers and AI agents can use these boundaries to determine where each
artifact belongs.
