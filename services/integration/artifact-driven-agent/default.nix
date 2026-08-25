{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.integration.artifact-driven-agent;
  harness = config.${namespace}.agent.harness;
  deliveryWorkflowEnabled =
    cfg.build.enabled
    && config.${namespace}.integration.artifact-driven-delivery-workflow.build.enabled;
in
{
  options.${namespace}.integration.artifact-driven-agent.build.enabled = utils.mkBoolOpt {
    readOnly = true;
    default = harness.build.enabled && config.${namespace}.documentation.model == "artifact-driven";
    description = "Enable Artifact-Driven Documentation and agent integration";
  };

  config = lib.mkIf cfg.build.enabled {
    ${namespace}.agent = {
      expert.experts = {
        scope-expert = lib.mkDefault {
          description = "Resolve the authoritative documentation scope and requirement acceptance boundary";
          persistentInstructions = ''
            Identify the cohesive change scope and the authoritative documentation before work starts.
            Scope authority accepts requirements and resolves documentation authority conflicts.
            Keep feature records in docs/features/<scope-id>/ and shared knowledge in docs/wiki/ or docs/glossary/.
            Do not decide technical correctness or implementation acceptance.
            Escalate a conflict between authoritative documents to the responsible scope owner.
          ''
          + lib.optionalString deliveryWorkflowEnabled ''
            For an active delivery workflow, use the full phase flow: correlate the requirement, specification or ADR, and task or plan artifacts with one ticket before review; register the review unit; start the task ticket before implementation; and verify the accepted merge or explicit rejection outcome.
          '';
          defaultSkills = [
            "artifact-driven-authoring"
            "artifact-driven-coordination"
          ]
          ++ lib.optional deliveryWorkflowEnabled "delivery-workflow";
        };
        technical-expert = lib.mkDefault {
          description = "Assess technical correctness of decisions and specifications";
          persistentInstructions = ''
            Assess technical correctness for decisions and specifications in the accepted documentation scope.
            State assumptions, interfaces, validation requirements, and implementation constraints clearly.
            Do not accept requirements, resolve documentation authority conflicts, or accept implementation.
            Return validation evidence and unresolved technical risks to the coordinator.
          '';
          defaultSkills = [
            "artifact-driven-technical-review"
            "artifact-driven-coordination"
          ];
        };
      };

      skill.skills = {
        artifact-driven-coordination = lib.mkDefault {
          description = "Coordinate Artifact-Driven work across explicit authority and implementation scopes";
          instructions = ''
            The active primary agent is the coordinator.
            Identify the relevant authority from accepted artifact context before delegation.
            Delegate only a bounded, explicit scope to an expert.
            Do not accept artifacts or resolve authority conflicts. Escalate those matters to the responsible scope owner.
            Route accepted artifact context to a bounded implementation scope.
            Collect and report validation evidence from every delegated scope.
          '';
        };
        artifact-driven-authoring = lib.mkDefault {
          description = "Create and maintain Artifact-Driven documentation in its authoritative location";
          instructions = ''
            Start from docs/README.md and the relevant governance documents.
            Keep requirements, specifications, decisions, tasks, and implementation plans in their distinct feature-document boundaries.
            Keep shared policy in docs/wiki/ and defined terms in docs/glossary/.
            Link directly related artifacts with relative descriptive links.
          '';
        };
        artifact-driven-technical-review = lib.mkDefault {
          description = "Review decisions and specifications for technical correctness and validation coverage";
          instructions = ''
            Review technical decisions and specifications against the accepted requirement context.
            Check interfaces, constraints, failure cases, and verification evidence.
            Report findings and proposed changes. Do not accept artifacts or change authority boundaries.
          '';
        };
        semantic-artifact-review = lib.mkDefault {
          description = "On-demand semantic review of an Artifact-Driven documentation artifact";
          instructions = ''
            Use this skill only when a semantic artifact review is requested.
            Check the artifact against its authoritative scope, document boundary, terminology, and direct traceability links.
            Report evidence-backed findings. This skill does not create a review lifecycle or accept an artifact.
          '';
        };
      }
      // lib.optionalAttrs deliveryWorkflowEnabled {
        delivery-workflow = lib.mkDefault {
          description = "Correlate Artifact-Driven review units with delivery tickets";
          instructions = ''
            Use this skill when Artifact-Driven Documentation and the delivery workflow are both active.
            For phases 1-3, create or reuse one Draft ticket, record its canonical URL in every review artifact under delivery.ticket front matter, then register the review unit on the pull request.
            For phase 4, start the Ready task ticket before implementation and register the implementation review unit.
            Verify the current pull request and ticket state before a transition. An accepted merge advances only the permitted ticket state. Archive phases 1-3 only after an explicit rejection. Keep an implementation ticket In Progress after rejection, close, or rework.
          '';
        };
      };
    };
  };
}
