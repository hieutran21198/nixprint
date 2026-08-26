# Artifact-Driven Documentation Governance

## Purpose

This governance defines the canonical model for centralized project
documentation. It helps developers and AI agents find, create, review, and
maintain current project knowledge.

## Normative Terms

- `MUST` defines a mandatory rule.
- `MUST NOT` defines a prohibited rule.
- `SHOULD` defines a recommended rule.
- `SHOULD NOT` defines a discouraged rule.
- `MAY` defines an optional rule.

## Writing Standard

Project documentation MUST use ASD-STE100 principles. Writers MUST:

- Use short and direct sentences.
- Use one main idea in each sentence.
- Use active voice when possible.
- Use the same term for the same concept.
- Avoid vague language and unnecessary synonyms.
- Define abbreviations and domain-specific terms when required.
- Preserve technical meaning when they simplify text.

## Documentation Areas

```text
docs/
├── features/
│   └── <scope-id>/
│       ├── requirements/
│       ├── specifications/
│       ├── decisions/
│       ├── tasks/
│       └── implementation-plan/
├── wiki/
└── glossary/
```

`docs/features/` contains one record for each cohesive feature scope.
`docs/wiki/` contains system-wide knowledge and governance.
`docs/glossary/` contains shared terms and abbreviations.

A feature MUST create only the document areas that its current scope needs.
It MUST NOT contain empty template areas.

## Feature Identifiers

A feature directory name MUST:

- Be unique in `docs/features/`.
- Use lowercase ASCII letters, digits, and hyphens.
- Describe one cohesive current scope.
- Not use an execution-system identifier.

Rename or replace a feature identifier when the implemented semantic boundary
changes. Do not keep an obsolete identifier only to preserve documentation
history.

## Feature Documents

### Requirements

Requirements define the intended outcome, constraints, and acceptance
criteria. They state what the feature needs. They do not define a solution or
task sequence.

### Specifications

Specifications define current behavior, interfaces, data, rules, failure
conditions, and verification. They satisfy related requirements. They do not
record change history or work status.

### Decisions

Decisions define a significant current design choice. Each decision states its
context, considered options, decision, rationale, and consequences. It does not
duplicate the full specification.

### Tasks

Tasks define actionable work that is not yet represented by implementation
status. The execution system owns work status.

### Implementation Plans

Implementation plans define an approved change sequence, dependencies, risks,
and verification approach. They link to their task definitions. They do not
duplicate execution-system status.

## Canonical Current Model

Each topic MUST have one canonical document. Authority follows document type
and scope:

- A feature directory owns its cohesive feature record.
- The wiki owns system-wide knowledge and governance.
- The glossary owns shared definitions.

Each scope MUST have a responsible owner. The owner keeps its canonical
documents aligned with accepted behavior and resolves conflicts.

Only accepted changes have governance authority. Rejected changes MUST NOT
revise the canonical model.

Canonical documents describe the current accepted system. Update them in place
when accepted behavior changes. Fold patches and breaking changes into the
current concept after their behavior is implemented. Delete superseded
documents after their valid behavior, constraints, and interfaces are
preserved.

Git and the execution system retain change history. Canonical documentation
MUST NOT keep obsolete decisions, terminology, aliases, or redirect pages only
to expose that history.

When documentation and implementation disagree, inspect the implementation
and its tests. Reconstruct the current intended behavior. Do not change the
implementation only to preserve an obsolete document. Preserve a compatibility
artifact only when a released downstream consumer still uses it.

## Shared Knowledge

Move knowledge to the wiki only when it governs or explains more than one
feature scope. Possible future reuse is not sufficient.

Move shared terms and abbreviations to the glossary. The glossary MUST NOT
contain detailed behavior or design rationale.

A feature MAY explain how shared governance applies to it. It MUST link to the
canonical shared page and MUST NOT duplicate its normative content.

## Navigation and Traceability

`docs/README.md` MUST index project knowledge. Each populated major area MUST
have a `README.md`.

Each feature `README.md` MUST state:

- Its cohesive scope.
- Its scope owner.
- Included and excluded concerns.
- Links to its current documents.

Documentation MUST use descriptive relative links. Requirements and
specifications MUST link to each other when both exist. Decisions MUST link to
their motivating requirement or specification. An implementation plan MUST
link to its tasks.

Before documentation work starts, read `docs/README.md`, this governance,
and the applicable feature index.

## Growth

Split a document only when content has an independent responsibility,
audience, lifecycle, or acceptance path. Do not split a document because of
length alone.

Keep related content together when readers review and change it as one unit.
When a focused document replaces part of a larger page, update the parent
index and remove duplicate content.

## Delivery

[Delivery Workflow Governance](delivery-workflow.md) defines the optional
review and implementation delivery lifecycle.

[Polyrepo Governance](../../polyrepo.md) defines the boundary between
centralized project knowledge and implementation repositories.
