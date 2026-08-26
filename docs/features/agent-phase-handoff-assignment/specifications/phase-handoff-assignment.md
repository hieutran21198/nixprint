# Agent Phase Handoff Assignment Specification

This specification satisfies the
[requirement](../requirements/phase-handoff-assignment.md).

## Role Mapping

| Phase | Artifact owner | GitHub Issue assignee |
| --- | --- | --- |
| Requirement | Requirement owner | Requirement owner |
| Specifications and ADRs | Technical lead | Technical lead |
| Tasks and plan | Technical lead | Selected builder |
| Implementation | Technical lead | Existing builder |

An Issue assignee identifies GitHub work responsibility. It does not transfer
artifact ownership or acceptance authority.

## Command Interface

`dw assignees` prints every eligible repository Issue assignee. It reads every
GitHub result page and sorts the usernames.

`dw draft --phase requirement` accepts one to ten `--assignee` values. It is
the only command that creates a root ticket.

`dw handoff --predecessor <issue> --phase specs-adrs|tasks-plan` accepts one to
ten `--assignee` values. It creates a Draft child ticket only after it verifies
the Ready predecessor and its phase.

Each child ticket has this `dw:ticket` record data:

```yaml
version: 1
phase: specs-adrs
predecessor:
  url: "<canonical predecessor ticket URL>"
  phase: requirement
```

`dw start --issue <issue>` accepts only a Ready `tasks-plan` ticket with one or
more existing assignees. It changes the Project status to `In Progress`. It
does not accept assignment flags and does not change assignees.

## Validation and Failure Behavior

The commands reject a missing, duplicate, ineligible, or over-ten assignment
list before they create an Issue or change Project status.

`dw handoff` rejects a predecessor with the wrong phase or a status other than
Ready. It rejects an existing child record with a different predecessor link,
predecessor phase, or child phase. It rejects more than one linked child.

A retry finds the existing correctly linked child. It retains current
collaborators and verifies that each supplied assignee is present. A retry does
not create another child ticket.
