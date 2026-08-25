# Artifact-Driven Delivery Workflow Integration Research

## Status

This document records reviewed research. It is not governance and has no
normative authority.

## Scope

This research describes an Artifact-Driven Development workflow with four
phases:

1. Requirement.
2. Specifications and architecture decision records (ADRs).
3. Tasks and implementation plan.
4. Implementation.

It covers the connection between Git hosting, continuous integration and
continuous delivery (CI/CD), and an execution system. It does not prescribe an
execution-system state model or a release lifecycle.

## Core Workflow

Use one review unit for each pull request (PR) or merge request (MR). A review
unit has one ticket, one workflow phase, and one explicit completion outcome.
It can include the specification and ADR artifacts that are accepted together.

```text
Phases 1–3

Draft artifact
  -> sync ticket as Draft
  -> create PR/MR
  -> merge to the acceptance branch: ticket Ready
  -> explicit rejection: ticket Archived

Phase 4

Task ticket Ready
  -> implementation starts: ticket In Progress
  -> implement
  -> create PR/MR
  -> merge to the acceptance branch: implementation accepted
  -> rejection, close, or rework: ticket remains In Progress
```

An accepted PR/MR is one that merged into the configured, protected acceptance
branch. An accepted implementation merge defines the implementation acceptance
boundary. The execution system controls later states, including `Done`.

### Rejection Semantics

`Changes requested` is not rejection. It asks the author to revise the same
review unit. The ticket must remain in its current state.

Explicit rejection is a provider-independent delivery decision. The integration
maps authorized provider evidence to that decision. An unmerged close event is
not always rejection. GitHub emits a closed PR event for both merged and
unmerged PRs; the receiver must inspect whether the PR was merged. GitLab
similarly distinguishes `merge` and `close` actions in its MR webhook.
Bitbucket Cloud has a separate rejected pull-request event.

Possible implementations include an authorized label, command, or native
provider decline event. This research does not prescribe one mechanism. Only
an explicit rejection decision can archive a phase 1–3 ticket. A phase 4
rejection, close, or rework outcome leaves the task ticket `In Progress`.

Sources: [GitHub pull-request webhook events](https://docs.github.com/en/webhooks/webhook-events-and-payloads), [GitLab merge-request webhook events](https://docs.gitlab.com/user/project/integrations/webhook_events/), [Bitbucket Cloud webhooks](https://support.atlassian.com/bitbucket-cloud/docs/manage-webhooks/).

## Responsibility Boundary

| System | Owns | Does not decide |
| --- | --- | --- |
| Version control | Branches, commits, changed files, PR/MR review, merge result, and immutable merge commit. | Ticket status or deployment completion. |
| CI | Validation of the proposed artifact or implementation, and the evidence for merge checks. | Acceptance or rejection of the business/work item. |
| CD | Build promotion and deployment evidence after a merge. | Post-implementation ticket state. |
| Execution system | Ticket identity, state model, assignment, priority, scheduling, and work history. | Whether Git content is accepted. |
| Integration layer | Correlation, event verification, outcome classification, and the permitted ticket transition. | Repository review policy, CI result, or artifact content. |

Use protected acceptance branches and required approvals and checks. This makes
a merge a reliable acceptance event rather than a direct push. GitHub supports
required reviews and status checks. GitLab supports approval rules and a
successful-pipeline merge check. Bitbucket Cloud supports merge checks for
approvals, unresolved tasks, and successful builds.

Sources: [GitHub protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches), [GitLab approval rules](https://docs.gitlab.com/user/project/merge_requests/approvals/rules/), [GitLab successful-pipeline merge check](https://docs.gitlab.com/user/project/merge_requests/auto_merge/), [Bitbucket Cloud merge checks](https://support.atlassian.com/bitbucket-cloud/docs/suggest-or-require-checks-before-a-merge/).

## Provider-Independent Integration Model

The model uses semantic roles. An adapter maps each role to a provider API or
native automation. The model does not depend on a provider issue type, field,
or webhook name.

```text
Artifact repository              Integration layer                 Execution system

artifact + PR/MR metadata  ->    correlate review unit        ->   create or update ticket
PR/MR and CI events        ->    verify and classify outcome  ->   transition ticket
scheduled reconciliation   ->    repair missed event handling ->   retain ticket history
```

### Review-Unit Record

The integration needs a durable record for each review unit. Store at least:

- Ticket canonical URL and provider identifier.
- Phase: `requirement`, `specs-adrs`, `tasks-plan`, or `implementation`.
- Artifact paths for phases 1–3, or task identifier for phase 4.
- Repository, PR/MR URL and identifier, source revision, and acceptance branch.
- Expected ticket state and permitted outcome.
- Rejection decision evidence, when phase is 1–3.

Put the ticket URL or key and the phase in the PR/MR description. A PR/MR
template is sufficient. The integration should write a link back to the PR/MR
on the ticket. This creates navigation in both directions without copying the
artifact body into the ticket.

### Adapter Contract

Each provider adapter implements these operations:

1. Create or update the ticket as `Draft` for phases 1–3.
2. Attach the ticket to the PR/MR and register the review-unit record.
3. Receive PR/MR, review, and CI events, then read the current PR/MR state.
4. Classify a terminal outcome as accepted, explicitly rejected, or neither.
5. Perform only the transition allowed by the phase table.
6. Reconcile registered PRs/MRs and tickets after missed deliveries.

The integration should make the ticket update conditional on its expected
current state. This prevents a duplicate or late event from applying an
incorrect transition.

### Transition Table

| Phase | Ticket before PR/MR | Accepted event | Rejected event | Ticket after event |
| --- | --- | --- | --- | --- |
| Requirement | Draft | Merge to acceptance branch | Explicit rejection | Ready / Archived |
| Specs + ADRs | Draft | Merge to acceptance branch | Explicit rejection | Ready / Archived |
| Tasks + implementation plan | Draft | Merge to acceptance branch | Explicit rejection | Ready / Archived |
| Implementation | In Progress | Merge to acceptance branch | Rejected, closed, or rework | Implementation accepted / In Progress |

Do not transition a ticket from a branch push, PR/MR creation, approval, or
passing CI alone. Those events show progress but do not provide a terminal
outcome in this model.

## Provider Mapping

| Provider | Git and CI/CD connection | Execution-system mapping |
| --- | --- | --- |
| GitHub | Use a PR to a protected branch and required status checks. Listen for `pull_request` events; determine acceptance from the merged result, not a closed event alone. | GitHub Issues can be tickets. In GitHub Projects, use a single-select `Status` field that maps the workflow semantics and any post-implementation states. Do not use an issue-closing keyword for this workflow because it only provides GitHub's coarse closed state and closes on merge. |
| GitLab | Use an MR, approval rules, and a successful-pipeline merge check. Its MR webhook provides open, approval, merged, and closed actions. | GitLab Issues or an external execution system can be tickets. The adapter maps the configured status field and permitted transitions. |
| Bitbucket Cloud | Use a PR, branch restrictions, merge checks, and Pipelines or another build-status provider. Its webhooks include created, merged, and declined PR events. | Jira is the closest native mapping. Jira Automation has PR-created, PR-merged, and PR-declined triggers after source-control integration. Use the same phase table in the automation rule or adapter. |
| Jira | Jira consumes source-control development events and enforces the configured ticket workflow. Automation can transition a work item, but the target transition must exist in that workflow. | Map the workflow semantics to the configured state model. The automation must distinguish accepted merge from explicit rejection. |
| Linear | Linear links GitHub PRs and GitLab MRs to issues and can automate status updates from those events. | Map the workflow semantics to the configured state model. Limit native automations to the phase-table transitions, or use the integration layer where native rules cannot distinguish a close from a rejection. |

GitHub Projects supports custom single-select fields. This permits a project to
map the workflow semantics and additional states even though a GitHub Issue
itself has only its open or closed state. GitHub's linked-issue closing keywords
close an issue when a PR merges to the default branch, so they should not
control the ticket state here.

Sources: [GitHub status checks](https://docs.github.com/en/pull-requests/reference/status-checks), [GitHub Projects single-select fields](https://docs.github.com/en/issues/planning-and-tracking-with-projects/understanding-fields/about-single-select-fields), [GitHub PR-to-issue linking](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue), [Jira automation triggers](https://support.atlassian.com/cloud-automation/docs/jira-automation-triggers/), [Jira workflow transitions](https://support.atlassian.com/jira-software-cloud/docs/transition-an-issue/), [Linear GitHub integration](https://linear.app/docs/github-integration), [Linear GitLab integration](https://linear.app/docs/gitlab).

## CI/CD Design

For phases 1–3, CI should validate the artifact before review and merge. The
checks can verify document structure, links, identifiers, ADR fields, task and
plan traceability, and generated artifacts. CI reports results to the PR/MR.

For phase 4, CI should validate the implementation through the applicable
tests, static analysis, security checks, and build. Required checks protect the
acceptance branch. CD starts after the accepted merge and records its result
against the merge commit or release.

An accepted implementation merge defines the implementation acceptance boundary.
It does not require a `Done` transition. The execution system MAY transition a
ticket to `Done` after testing, QA, UAT, or release validation.

## Reliability Requirements and Limitations

The workflow needs the following controls to remain reliable.

- Verify webhook signatures or provider authentication. Give the integration
  only the permissions required to read PR/MR state and transition tickets.
- Treat deliveries as at-least-once and potentially out of order. Deduplicate
  by provider delivery identifier, retain the event timestamp, and re-read the
  current PR/MR before a ticket update. GitHub documents that deliveries can be
  out of order and are not automatically redelivered after failure.
- Use the merge commit and configured target branch as the acceptance proof.
  An approval, passing check, or auto-merge request is not a merge.
- Keep one designated review unit per required ticket transition. If several
  PRs/MRs relate to one ticket, designate the one that can complete it or make
  completion wait for all registered required reviews. Otherwise an unrelated
  merge can complete the ticket early.
- Do not auto-archive from a PR/MR close, a failed pipeline, a changed review,
  or a missing webhook. Archive only after an explicit rejection decision.
- Run reconciliation for non-terminal review units. Reconciliation must use
  the provider's current PR/MR state and preserve the same transition rules.
- Keep an operational audit record of the source event, review-unit record,
  observed PR/MR state, attempted transition, and result. The ticket and PR/MR
  links remain the human traceability path.

Native integrations are useful when their event semantics match the table. They
are not sufficient when they automatically close a ticket on any merge, cannot
distinguish an unmerged close from rejection, or cannot apply a conditional
transition. Use a small adapter in those cases.

Sources: [GitHub webhook delivery failures](https://docs.github.com/en/webhooks/using-webhooks/handling-failed-webhook-deliveries), [GitHub webhook ordering](https://docs.github.com/en/webhooks/testing-and-troubleshooting-webhooks/troubleshooting-webhooks), [Linear review synchronization limitations](https://linear.app/docs/diffs).

## Recommended Adoption Order

1. Map the workflow semantics to the execution-system state model.
2. Protect each acceptance branch with review and CI requirements.
3. Add a PR/MR template with ticket, phase, artifact paths or task, and a
   rejection decision declaration.
4. Implement the adapter for ticket sync, PR/MR correlation, and terminal
   transitions.
5. Enable CI checks for documentation and implementation.
6. Add webhook verification, durable event processing, and reconciliation
   before relying on automatic status transitions.
