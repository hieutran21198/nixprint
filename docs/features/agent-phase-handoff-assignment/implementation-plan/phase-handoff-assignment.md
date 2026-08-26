# Agent Phase Handoff Assignment Implementation Plan

This plan implements the [task definitions](../tasks/phase-handoff-assignment.md).

## Sequence

1. Add delivery-ticket record parsing for phase and predecessor data.
2. Add Issue discovery, child-link lookup, and assignment confirmation.
3. Restrict `dw draft` and add `dw handoff`.
4. Validate the task ticket before `dw start` changes Project status.
5. Update governance, Agent instructions, service documentation, and indexes.
6. Run focused tests, Nix evaluation, documentation validation, and diff checks.

## Risks

- A GitHub user can lose assignment eligibility between discovery and write.
- A command can fail after GitHub creates a child Issue but before it writes an
  artifact ticket URL.
- A repository can contain an incorrect or duplicate predecessor link.

## Verification

Test Issue-assignee pagination, valid handoffs, predecessor records, failure
cases, retry safety, and Phase-4 assignment reuse. Evaluate the generated
Agent skill with the delivery workflow enabled.
