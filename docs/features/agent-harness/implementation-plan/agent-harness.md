---
delivery:
    ticket: https://github.com/hieutran21198/nixprint/issues/5
---
# Agent Harness Implementation Plan

## Inputs

- [Requirements](../requirements/agent-harness.md).
- [Specification](../specifications/agent-harness.md).
- [Provider-Neutral Harness Decision](../decisions/provider-neutral-harness.md).
- [Tasks](../tasks/agent-harness.md).

## Change Sequence

1. Inspect the Agent Harness modules and evaluation tests against AH-1.
2. Preserve implemented behavior in the canonical documents.
3. Rewrite the Agent service README against the same model.
4. Search the former records for any remaining valid constraint or interface.
5. Delete the former records after the search has no unpreserved behavior.
6. Run the verification defined by AH-5.

## Dependencies

The Artifact-Polyrepo Workspace plan owns composition-specific expert mapping.
The Delivery Workflow plan owns the `delivery-workflow` skill semantics.

## Risks and Controls

- A client-specific detail can be lost during consolidation. Compare every
  generated file mapping with `services/agent/harness/default.nix`.
- Native policies can be mistaken for the shared enforcement boundary. Keep
  the Linux Bubblewrap runner separate from Claude Code and OpenCode policy.
- Old expert terminology can survive in navigation. Search all documentation
  and service READMEs after deletion.

## Verification

- Run `bash services/agent/tests/test-module.sh`.
- Run `devenv eval`.
- Run Markdown lint on changed documents.
- Validate all relative links.
- Confirm that the three former feature directory names have no remaining
  references.
