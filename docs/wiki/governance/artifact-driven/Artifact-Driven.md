# Artifact Driven Development Governance

## Purpose

This document defines the governance model for **Artifact-Driven Development (ADD)**.

In this model, development is driven by a chain of explicit, reviewable, and version-controlled artifacts.

The canonical lifecycle is:

```txt
Requirement
    ↓
Decisions / Specifications
    ↓
Tasks
    ↓
Implementation
```

Each phase produces artifacts that become the approved input for the next phase.

The repository is the **source of truth** for all governed artifacts and their lifecycle state.

External project-management systems may represent and synchronize workflow state, but they must not redefine the canonical content or state stored in the repository.

## Core Principles

### Artifact First

Every governed change MUST originate from an artifact.

Implementation MUST NOT become the source from which requirements, decisions, or specifications are reconstructed after the fact.

```txt
intent → artifact → review → acceptance → downstream work
```

### Git Is the Source of Truth

Governed artifacts MUST be stored and versioned in Git.

The repository determines:

- artifact content;
- artifact identity;
- artifact relationships;
- artifact lifecycle state;
- approved revisions;
- historical changes.

External systems MAY provide:

- backlog views;
- assignment;
- discussion;
- dashboards;
- notifications;
- workflow automation.

They MUST NOT override canonical repository state.

### One-Way Authority

Synchronization between Git and external management systems MUST preserve a single authority direction:

```txt
Git → external systems
```

External systems MAY request or initiate changes, but any governed state transition MUST ultimately be represented and accepted in Git.

A synchronization failure MUST NOT silently mutate canonical artifact state.

### Explicit Artifact Relationships

Every downstream artifact MUST reference its upstream artifact.

The minimum hierarchy is:

```txt
Requirement
└── Specification / Decision
    └── Task
        └── Implementation
```

Relationships MUST be traceable in both human-readable content and machine-readable metadata where applicable.

No governed artifact SHOULD exist without a known reason for its existence.

## Artifact Types

### Requirement

A requirement defines **what outcome is needed and why**.

Requirements SHOULD describe:

- problem;
- context;
- goals;
- constraints;
- expected behavior;
- acceptance criteria;
- non-goals.

Requirements MUST avoid prescribing implementation details unless those details are themselves business or system constraints.

A requirement corresponds conceptually to an **Epic** in the project-management layer.

### Decision

A decision records a significant design or architectural choice.

Decisions SHOULD capture:

- context;
- considered alternatives;
- selected option;
- rationale;
- consequences.

Architecture Decision Records MAY be used for decisions that have significant or long-lived architectural impact.

A decision MUST reference the requirement or specification that caused the decision to be made.

### Specification

A specification defines **how an accepted requirement is expected to behave or be realized at the system level**.

Specifications MAY describe:

- system behavior;
- interfaces;
- data models;
- invariants;
- state transitions;
- failure handling;
- security requirements;
- performance requirements;
- compatibility constraints.

Specifications MUST remain implementation-independent where practical.

A specification corresponds conceptually to a **Story** in the project-management layer.

### Task

A task defines a bounded piece of implementation work required to satisfy an accepted specification.

Tasks SHOULD be:

- independently understandable;
- implementation-oriented;
- small enough to review;
- objectively completable.

A task MUST reference its parent specification.

Tasks MAY include:

- affected components;
- implementation notes;
- validation requirements;
- dependencies.

### Implementation

Implementation consists of source code, configuration, migrations, tests, infrastructure, or other executable changes.

Every governed implementation MUST reference the task or artifact that authorizes the change.

Implementation MUST NOT silently introduce behavior outside the accepted upstream artifacts.

If implementation reveals that an upstream artifact is incomplete or incorrect, the upstream artifact MUST be amended rather than allowing the implementation to become the implicit specification.

## Artifact Lifecycle

Every governed artifact follows an explicit lifecycle.

The lifecycle determines whether an artifact is still being developed, has been approved through governance review, or is no longer active.

The canonical lifecycle states are:

```txt
Draft
  ├── accept → Accepted
  └── reject → Archived
```

Lifecycle state is governed by repository activity and repository-defined review rules.

External systems MAY mirror these states, but they MUST NOT independently determine canonical lifecycle state.

### Draft

A `Draft` artifact exists in the repository but has not yet been approved through governance review.

A draft artifact:

- MAY be created, revised, and reviewed;
- MAY be synchronized to an external project-management system;
- MAY receive an external representation before acceptance;
- MUST retain a canonical repository identity;
- MUST NOT authorize downstream governed work.

A draft artifact MAY be prepared using local tooling, dedicated artifact-management commands, or manual editing.

When external project-management integration is required, the draft MUST have a corresponding external ticket before entering governed review.

The external ticket identifier MUST be recorded in repository-controlled artifact metadata as part of the submitted change.

```txt
create draft
    ↓
create or locate external ticket
    ↓
record external ticket ID
    ↓
commit artifact
    ↓
open governed review
```

The method used to create or update the external representation is not authoritative.

Whether the external ticket is created manually or through tooling, the resulting linkage MUST be represented in Git before governed review begins.

The external identifier is an integration reference only.

It MUST NOT replace the canonical artifact identity.

For example:

```txt
REQ-001     canonical artifact identity
ENG-123     external project-management identity
```

Synchronization of a draft artifact is representational only.

It MUST NOT grant the external system authority over:

- artifact content;
- artifact identity;
- artifact relationships;
- lifecycle transitions;
- acceptance decisions.

Review automation MUST validate existing linkage and MUST NOT create, repair, or mutate governed linkage on behalf of the artifact author.

### Accepted

An `Accepted` artifact has passed the required governance review and its reviewed revision has been explicitly approved.

Acceptance represents a governance decision:

```txt
Draft
  ↓ authorized approval
Accepted
```

Acceptance approves the reviewed artifact revision.

Acceptance alone, however, MUST NOT authorize downstream governed work.

The accepted revision MUST also be present in the canonical branch before it may be used as authoritative input for the next lifecycle phase.

```txt
Accepted
    +
accepted revision merged
into canonical branch
    ↓
Downstream authorized
```

The minimum authorization chain is therefore:

```txt
Requirement accepted
and present in canonical branch
        ↓
Decision / Specification work

Specification accepted
and present in canonical branch
        ↓
Task planning

Task accepted
and present in canonical branch
        ↓
Implementation
```

This distinction separates governance approval from repository integration:

```txt
Acceptance = approved revision
Merge      = canonical availability
```

An accepted artifact that has not yet been merged remains approved but MUST NOT be treated as ready for downstream governed work.

External systems MAY represent an accepted artifact using workflow states such as `Accepted`, `Approved`, or an equivalent state.

A downstream-ready external state such as `Ready` SHOULD only be derived once the accepted revision is also present in the canonical branch.

External workflow transitions MUST NOT independently cause canonical acceptance or downstream authorization.

An accepted artifact SHOULD be treated as a reviewed revision.

Changes that materially alter its approved meaning MUST follow the repository's amendment or revision process rather than silently changing the artifact underneath downstream work.

### Archived

An `Archived` artifact is no longer active and MUST NOT authorize new downstream governed work.

A draft artifact normally becomes archived when its review is explicitly rejected or when the proposal is deliberately abandoned.

```txt
Draft
  ↓ rejected or abandoned
Archived
```

`Rejected` is therefore a lifecycle transition or review outcome rather than necessarily a persistent artifact state.

A request for revision does not by itself archive an artifact.

An artifact requiring further changes MAY remain in `Draft` until it is accepted, explicitly rejected, or abandoned.

Archived artifacts SHOULD remain available in repository history when they have participated in governed review.

Their external representations SHOULD be moved to an equivalent inactive state such as:

- `Archived`;
- `Cancelled`;
- `Rejected`;
- another system-specific inactive state.

Archiving an external representation MUST NOT remove or rewrite canonical repository history.

### Lifecycle Synchronization

When external project-management integration is enabled, lifecycle synchronization follows repository authority.

```txt
Git governance state
        ↓
synchronization
        ↓
external workflow state
```

The external system MAY expose additional operational states for assignment, prioritization, or workflow management.

Those states MUST NOT redefine the canonical artifact lifecycle.

For example, an external system MAY distinguish between:

```txt
Draft
In Review
Accepted
Blocked
Ready
```

while the canonical artifact lifecycle remains:

```txt
Draft
Accepted
Archived
```

Operational states MAY provide additional workflow context.

In particular, an external `Ready` state MAY represent the derived condition:

```txt
Accepted
+
merged into canonical branch
```

but it MUST NOT become an additional canonical artifact lifecycle state.

### Lifecycle Integrity

A governed artifact MUST NOT advance to `Accepted` unless all required acceptance checks and approvals have completed successfully.

Where external synchronization is required by repository policy, acceptance MUST NOT complete unless:

- the canonical artifact identity is valid;
- the external representation exists;
- the external identifier is recorded in repository-controlled metadata;
- the Git-to-external relationship can be validated;
- required upstream relationships are valid;
- required governance checks have passed;
- required review approval has been granted.

Review automation MUST validate these conditions but MUST NOT create or repair missing governed state.

A failed validation MUST leave the artifact in its existing canonical lifecycle state.

Acceptance MUST NOT by itself authorize downstream governed work.

Downstream authorization requires both:

```txt
Accepted revision
        +
present in canonical branch
```

A failed merge or an accepted revision that remains unmerged MUST therefore leave downstream work unauthorized.

A failed external synchronization MUST NOT silently cause acceptance, archival, merge readiness, or any other canonical lifecycle transition.

## Review & Acceptance

### Review Entry Conditions

A governed artifact MUST satisfy the required entry conditions before it is eligible for governance review.

Entry conditions establish whether the submitted artifact is structurally valid, traceable, and sufficiently complete to be reviewed.

At minimum, the submitted artifact MUST:

- have a valid canonical artifact identifier;
- satisfy all required external linkage requirements where project-management integration is enabled;
- reference all required upstream artifacts using valid canonical identifiers;
- conform to the required structure or schema for its artifact type;
- contain all sections or metadata required by repository policy;
- satisfy any upstream authorization constraints applicable to its lifecycle phase;
- identify a concrete revision that can be reviewed and approved.

Where a downstream artifact requires an upstream artifact to be accepted and present in the canonical branch, that condition MUST be satisfied before the downstream artifact enters governed review.

```txt
Draft
  ↓
validate review entry conditions
  ├── valid   → governed review may begin
  └── invalid → remain Draft
```

Failure to satisfy an entry condition MUST NOT by itself archive or reject the artifact.

The artifact MUST remain in `Draft` until the missing or invalid conditions are corrected, or until the artifact is explicitly rejected or abandoned.

Review automation MAY enforce entry conditions.

Such automation MUST report validation failures but MUST NOT silently create, repair, infer, or mutate governed artifact state on behalf of the author.

Passing review entry conditions indicates only that the artifact is eligible for review.

It MUST NOT imply acceptance, approval, merge readiness, or authorization of downstream work.

### Draft Artifact Preparation

A draft artifact MAY be prepared using local tooling, dedicated artifact-management commands, or manual editing.

When integration with an external project-management system is required, the draft MUST have a corresponding external ticket before entering governed review.

The external ticket identifier MUST be recorded in repository-controlled artifact metadata as part of the submitted change.

```txt
create draft
    ↓
create or locate external ticket
    ↓
record external ticket ID
    ↓
commit artifact
    ↓
open review
```

The method used to create or update the external representation is not authoritative.

Whether the ticket is created by tooling or manually, the repository MUST contain the resulting linkage before the artifact is submitted for review.

### Review Linkage Validation

Review automation MUST validate existing artifact linkage.

It MUST NOT create, repair, or mutate governed linkage on behalf of the artifact author.

When external project-management integration is required, review validation MUST confirm that:

- the canonical artifact identifier is valid;
- the required external ticket identifier is present;
- the referenced external ticket exists;
- the external ticket corresponds to the governed artifact;
- required upstream artifact references are valid.

If any required linkage is missing or invalid, the review check MUST fail.

```txt
artifact submitted for review
        ↓
validate identity and linkage
   ├── valid   → review may continue
   └── invalid → fail review gate
```

Review automation MUST NOT:

- create a missing external ticket;
- write a missing external identifier into the artifact;
- commit artifact changes;
- open a separate repair pull request or merge request;
- silently reconcile an invalid governed relationship.

Any required correction MUST be made explicitly in the artifact change and submitted through the normal review process.

### Review Authority

A governed artifact MUST be approved by a reviewer authorized for its artifact type before it may transition from `Draft` to `Accepted`.

The repository MUST define the required review authority for each governed artifact type.

Review authority MAY be assigned to one or more reviewers, roles, or groups.

```txt
Draft
  ↓
authorized review
  ├── approved     → Accepted
  └── not approved → remains Draft
```

Approval from a reviewer who is not part of the required review authority MUST NOT satisfy the acceptance requirement.

Where multiple approvals or multiple independent review authorities are required, all configured requirements MUST be satisfied before the artifact becomes `Accepted`.

```txt
required approval A
        +
required approval B
        ↓
Accepted
```

Automated validation MUST NOT substitute for required review approval.

Repository features MAY assist with reviewer assignment, discovery, or enforcement, but the required review authority MUST remain defined by repository governance.

### Acceptance

A governed artifact MAY transition from `Draft` to `Accepted` only when:

- all required review entry conditions are satisfied;
- all required automated validation has passed;
- all required review approvals have been granted by authorized reviewers.

```txt id="h6f2ql"
Draft
  ↓
entry conditions satisfied
  ↓
validation passed
  ↓
required approval granted
  ↓
Accepted
```

Acceptance applies to the reviewed artifact revision.

Acceptance does not by itself authorize downstream governed work.

The accepted revision MUST be merged into the canonical branch before it may be treated as authoritative input for the next lifecycle phase.

```txt id="0hxfpj"
Accepted
    +
merged into canonical branch
    ↓
Downstream authorized
```

An accepted artifact that has not been merged MUST remain unavailable for downstream governed work.

External systems MAY mirror acceptance, but they MUST NOT independently cause an artifact to become `Accepted`.

### Rejection and Revision

A review MAY request changes without rejecting the artifact.

When revision is required, the artifact MUST remain in `Draft`.

```txt id="8ddq4e"
Draft
  ↓ changes requested
Draft
```

The author MAY revise the artifact and submit the updated revision through the normal review process.

A draft artifact MAY transition to `Archived` only when it is explicitly rejected or deliberately abandoned.

```txt id="v7e86d"
Draft
  ├── changes requested → Draft
  ├── rejected          → Archived
  └── abandoned         → Archived
```

A failed validation, missing approval, or requested revision MUST NOT by itself archive the artifact.

Rejection or abandonment MUST NOT remove or rewrite governed repository history.

Where an external representation exists, its workflow state SHOULD be synchronized to an equivalent inactive state after the canonical artifact becomes `Archived`.

### Reviewed Revision Integrity

Review approval MUST apply only to the specific artifact revision that was reviewed.

A revision MUST NOT remain accepted if its governed content changes after the approval on which acceptance depends.

```txt
revision A
  ↓ reviewed
  ↓ approved
Accepted revision A
```

If the artifact is changed after approval:

```txt
revision A approved
        ↓
artifact changed
        ↓
revision B
        ↓
required validation and approval repeated
```

Any change that affects governed artifact content MUST invalidate the affected acceptance requirements unless repository policy can prove that the change is non-governed and does not alter the reviewed artifact revision.

Required automated checks MUST be rerun against the updated revision.

Required review approvals MUST be obtained again where the previous approval no longer applies.

Only the revision that satisfies the current validation and approval requirements MAY be treated as `Accepted`.

The revision merged into the canonical branch for downstream use MUST be the same accepted revision, or a repository-proven equivalent revision that introduces no governed content changes.

## Artifact Identity & Traceability

Every governed artifact MUST have a stable canonical identity.

Artifact identity establishes how governed artifacts are referenced, related, reviewed, synchronized, and traced throughout their lifecycle.

Canonical identity is owned by the repository.

External systems MAY provide additional identifiers, but those identifiers MUST NOT replace or redefine canonical artifact identity.

### Canonical Artifact Identity

Each governed artifact MUST have a unique canonical identifier.

The canonical identifier MUST remain stable for the lifetime of the artifact.

Moving, renaming, reorganizing, or relocating an artifact within the repository MUST NOT by itself change its canonical identity.

```txt
artifact moved or renamed
        ↓
canonical identity unchanged
```

A canonical identifier MUST identify one governed artifact unambiguously.

Duplicate or ambiguous canonical identifiers MUST be treated as invalid governance state.

The repository MAY define artifact-type-specific identifier formats.

The identifier format itself is repository policy and MUST NOT alter the identity semantics defined by this governance model.

### External Identity

An external project-management item MAY have its own system-specific identifier.

For example:

```txt
REQ-001     canonical artifact identity
ENG-123     external project-management identity
```

The external identifier is an integration reference only.

It MUST NOT:

- replace the canonical artifact identifier;
- become the authoritative identity of the artifact;
- determine artifact lifecycle state;
- redefine artifact relationships;
- prevent migration to another external system.

Where external integration is required, the relationship between the canonical artifact identifier and the external identifier MUST be explicit and traceable.

Multiple external representations MAY exist where repository policy permits them.

Each representation MUST remain linked to the same canonical artifact identity.

### Artifact Relationships

Relationships between governed artifacts MUST use canonical artifact identities.

Every downstream artifact MUST reference the upstream artifact that authorizes or explains its existence.

The minimum traceability chain is:

```txt
Requirement
    ↓
Decision / Specification
    ↓
Task
    ↓
Implementation
```

A relationship MUST identify its upstream artifact unambiguously.

Repository paths, filenames, external ticket identifiers, or display titles MUST NOT be used as the sole authoritative relationship identity where they can change independently of the artifact.

A broken, missing, or ambiguous required relationship MUST invalidate the affected governed linkage.

### Upstream and Downstream Traceability

A governed downstream artifact MUST be traceable to its required upstream authorization.

For example:

```txt
Task
  → Specification
      → Requirement
```

and:

```txt
Implementation
  → Task
      → Specification
          → Requirement
```

Where a Decision materially affects a Specification or Implementation path, that relationship MUST also be represented explicitly.

Traceability MUST allow a reviewer or automation to determine:

- why an artifact exists;
- which upstream artifact authorized it;
- which downstream artifacts depend on it;
- which accepted revision established the relevant relationship.

No governed artifact SHOULD exist as an isolated node without a traceable reason for its existence.

### Relationship Integrity

Artifact relationships MUST remain valid throughout governed review and downstream use.

Review validation MUST reject required relationships that reference:

- nonexistent artifacts;
- invalid canonical identifiers;
- ambiguous identities;
- artifacts that do not satisfy applicable upstream authorization requirements.

Relationship validation MUST NOT silently infer or repair missing governed relationships.

Any required correction MUST be represented explicitly in the repository and pass through the normal review process.

### Historical Traceability

Changes to artifact identity, relationships, acceptance, amendment, supersession, or archival MUST remain historically traceable through repository history.

Governance history SHOULD allow determination of:

- which artifact revision was reviewed;
- which revision was accepted;
- which upstream relationships applied to that revision;
- which downstream artifacts depended on it;
- whether the artifact was later amended, superseded, or archived.

Historical traceability MUST NOT require the current artifact revision to preserve obsolete relationships as active relationships.

Superseded or historical relationships MAY cease to be active, but their prior existence MUST remain recoverable from repository history.

### Traceability Integrity

Traceability is a governance requirement, not merely a documentation convenience.

A governed artifact MUST NOT be treated as valid downstream input if its required identity or relationship chain cannot be established.

```txt
valid canonical identity
        +
valid upstream relationships
        +
traceable authorization chain
        ↓
valid governed linkage
```

External systems MAY assist with navigation, visualization, indexing, or relationship discovery.

Such representations are derivative.

They MUST NOT override, repair, or redefine canonical artifact identity or repository-governed relationships.

## External System Governance

## Phase Governance

## Artifact Evolution

## Repository Policy
