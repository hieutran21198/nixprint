# GitHub Delivery Workflow Starter Requirement

## Outcome

Provide a usable GitHub adapter for the Artifact-Driven Delivery Workflow.

## Constraints

- Support one repository and one user-owned or organization GitHub Project.
- Treat configured Project values as workflow semantics. Do not require a
  status name.
- Use GitHub Actions for merge handling and reconciliation.
- Use an explicit, team-authorized rejection command for phases 1–3.
- Do not control post-implementation testing, QA, UAT, or release validation.

## Acceptance Criteria

- The tool creates Draft tickets for phases 1–3.
- The tool registers one review unit in each PR.
- A verified accepted merge applies only the permitted configured transition.
- A phase 4 task moves to In Progress when implementation starts.
- An unmerged implementation PR does not change ticket status.
- Operators can select the implementation-acceptance Project value during
  configuration.
