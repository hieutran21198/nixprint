# Shared Knowledge

## Purpose

This document defines the boundary between feature knowledge and shared
knowledge.

## Feature Knowledge

Feature documentation MUST contain knowledge that is created for, changed by,
or limited to one cohesive change scope.

## Wiki Knowledge

The wiki MUST contain system-wide architecture, cross-feature policies, shared
workflows, integration knowledge, and governance.

Knowledge MUST move from a feature folder to the wiki when it governs,
describes, or constrains more than one cohesive change scope. Possible future
reuse is not sufficient.

## Glossary Knowledge

The glossary MUST contain canonical definitions of shared domain terms,
abbreviations, and approved names. It MUST NOT contain detailed behavior,
policy, or design rationale.

## Duplication

A feature document MAY explain how shared knowledge affects the feature. It
MUST link to the canonical shared document. It MUST NOT duplicate its normative
content.

A shared document MAY link to affected features. It MUST NOT duplicate their
change records.
