# Documentation Growth

## Purpose

This document defines how centralized documentation grows without losing clear
boundaries.

## Focused Documents

A document MUST be split when it has more than one independent responsibility,
audience, lifecycle, or approval path. A document MUST NOT be split only because
it reaches an arbitrary length.

A document SHOULD remain whole when its content is read, reviewed, and changed
as one unit.

When a document is split, its former location MUST remain an index that links
to the focused documents.

## New Documents

Each new document MUST have one clear purpose. Its parent `README.md` MUST link
to it.

Documentation MUST NOT create empty folders or template documents before a
cohesive change requires them.

## History

Accepted decisions MUST preserve their historical content. A later accepted
decision MUST identify the earlier decision that it supersedes. It MUST NOT
replace it.
