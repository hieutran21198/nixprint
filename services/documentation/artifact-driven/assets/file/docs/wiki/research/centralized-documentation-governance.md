# Centralized Documentation Governance Research

## Status

This document records reviewed research. It is not governance and has no
normative authority.

## Documentation Structure

Problem: A single documentation area makes feature records and shared knowledge
difficult to find.

Practices: Diátaxis separates documentation by user need and purpose. Write the
Docs recommends an explicit taxonomy and easy navigation.

Alternatives: One wiki is simple but loses scope. Root folders by document type
split feature records. Feature folders with shared wiki and glossary preserve
both boundaries.

Accepted direction: Use feature folders for cohesive changes, a wiki for shared
knowledge, and a glossary for canonical terminology.

Sources: [Diátaxis](https://diataxis.fr/), [Write the Docs](https://www.writethedocs.org/guide/index.html).

## Feature Documents

Problem: Requirements, design, decisions, plans, and tasks can become mixed.

Practices: NASA recommends bidirectional requirement and design traceability.
Microsoft defines focused decision records with context, options, and
consequences.

Alternatives: Combine plans and tasks, put decisions in specifications, or keep
five focused document types. The five-type model adds links but preserves clear
responsibility.

Accepted direction: Separate requirements, specifications, decisions,
implementation plans, and task definitions. Tasks define work. The execution
system owns work status.

Sources: [NASA traceability](https://swehb.nasa.gov/spaces/7150/pages/16449675/SWE-059%2B-%2BBidirectional%2BTraceability%2BBetween%2BSoftware%2BRequirements%2Band%2BSoftware%2BDesign), [Microsoft ADR guidance](https://learn.microsoft.com/en-us/azure/well-architected/architect-role/architecture-decision-record), [implementation plans](https://www.atlassian.com/work-management/strategic-planning/implementation-plan).

## Shared Knowledge

Problem: Feature documents can duplicate system knowledge and terminology.

Practices: NASA requires consistent terminology and encourages a project
glossary. Style guides act as shared references.

Alternatives: Keep features self-contained, move all knowledge to the wiki, or
promote only real multi-feature knowledge. The last option avoids both
duplication and premature generalization.

Accepted direction: Promote knowledge to the wiki only when it has real
multi-feature scope. Centralize shared terms and abbreviations in the glossary.

Sources: [NASA glossary guidance](https://www.nasa.gov/reference/system-engineering-handbook-appendix/), [Write the Docs style guides](https://www.writethedocs.org/guide/writing/style-guides/).

## Ownership and Authority

Problem: Conflicting documents and unrecorded decisions remove accountability.

Practices: ADR guidance recommends a single source of truth, clear ownership,
and immutable accepted decisions that later decisions supersede.

Alternatives: The latest edit wins, implementation wins, or authority follows
document type and scope. Scope-based authority prevents both duplicate and
implementation-led authority.

Accepted direction: Use scope-level ownership. Only accepted changes have
governance authority. Rejected changes do not alter canonical documentation.

Sources: [Microsoft ADR guidance](https://learn.microsoft.com/en-us/azure/well-architected/architect-role/architecture-decision-record), [AWS ADR process](https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/adr-process.html).

## Navigation and Traceability

Problem: A folder structure alone does not show document relationships.

Practices: Clear indexes and descriptive links aid navigation. NASA recommends
bidirectional traceability and unique requirement references.

Alternatives: A central traceability matrix is comprehensive but costly. No
links require inference. Layered indexes plus direct links are maintainable.

Accepted direction: Use parent indexes, a feature README, and direct links
between related documents. Do not require a central traceability matrix.

Sources: [Google technical writing](https://developers.google.com/tech-writing/two/large-docs), [NASA requirements management](https://www.nasa.gov/reference/6-2-requirements-management/).

## Growth and Maintainability

Problem: Documentation can become large, vague, and difficult to maintain.

Practices: Short connected documents support progressive disclosure. Clear
purpose boundaries improve maintenance.

Alternatives: Split by arbitrary length, never split, or split by independent
responsibility. The last option keeps related information together while
allowing focused growth.

Accepted direction: Split documents by independent responsibility, audience,
lifecycle, or approval path. Use stable `kebab-case` feature identifiers. Do
not use global sequences or execution-system identifiers.

Sources: [Google large documents](https://developers.google.com/tech-writing/two/large-docs), [Diátaxis](https://docs.divio.com/documentation-system/introduction/).
