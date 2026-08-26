{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.composition;
  profileEnabled = cfg.use == "artifact-polyrepo-workspace";
  agentEnabled = cfg.agent.enable;
  deliveryWorkflowEnabled = cfg.deliveryWorkflow.enable;
  harness = config.${namespace}.agent.harness;
  polyrepo = config.${namespace}.blueprint.polyrepo;

  enabledAnyClient = lib.any (client: client.enable) [
    cfg.agent.clients.codex
    cfg.agent.clients.claude
    cfg.agent.clients.opencode
  ];

  implementationExpert = _: expert: {
    inherit (expert)
      description
      persistentInstructions
      defaultSkills
      writePaths
      writeGlobs
      ;
  };

  deliveryGuidanceEnabled = harness.build.enabled && deliveryWorkflowEnabled;

  scopeExpert = {
    description = "Resolve the authoritative documentation scope and requirement acceptance boundary";
    persistentInstructions = ''
      Identify the cohesive change scope and the authoritative documentation before work starts.
      Scope authority accepts requirements and resolves documentation authority conflicts.
      Keep feature records in docs/features/<scope-id>/ and shared knowledge in docs/wiki/ or docs/glossary/.
      Do not decide technical correctness or implementation acceptance.
      Escalate a conflict between authoritative documents to the responsible scope owner.
    ''
    + lib.optionalString deliveryGuidanceEnabled ''
      For an active delivery workflow, use the full phase flow: correlate the requirement, specification or ADR, and task or plan artifacts with one ticket before review; register the review unit; start the task ticket before implementation; and verify the accepted merge or explicit rejection outcome.
    '';
    defaultSkills = [
      "artifact-driven-authoring"
      "asd-ste100-writing"
      "artifact-driven-coordination"
    ]
    ++ lib.optional deliveryGuidanceEnabled "delivery-workflow";
  };

  technicalExpert = {
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
in
{
  options.${namespace}.composition.artifactPolyrepoWorkspace.build.enabled = utils.mkBoolOpt {
    readOnly = true;
    default = profileEnabled;
    description = "Enable the Artifact-Polyrepo Workspace composition profile";
  };

  config = lib.mkIf profileEnabled (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = config.${namespace}.documentation.model == "artifact-driven";
            message = "workspace.composition.artifact-polyrepo-workspace requires Artifact-Driven Documentation";
          }
          {
            assertion = config.${namespace}.blueprint.use == "polyrepo";
            message = "workspace.composition.artifact-polyrepo-workspace requires the Polyrepo blueprint";
          }
          {
            assertion = !agentEnabled || enabledAnyClient;
            message = "workspace.composition.agent requires at least one enabled client";
          }
          {
            assertion = !deliveryWorkflowEnabled || config.${namespace}.git.hooks.enable;
            message = "workspace.composition.deliveryWorkflow requires workspace.git.hooks.enable";
          }
        ];

        ${namespace} = {
          documentation.model = lib.mkOverride 10 "artifact-driven";
          blueprint.use = lib.mkOverride 10 "polyrepo";
          agent.harness = lib.mkOverride 10 cfg.agent;
          delivery-workflow = lib.mkOverride 10 cfg.deliveryWorkflow;

          file."." = {
            enable = true;
            entries = {
              "AGENTS.md" = {
                enable = true;
                src = {
                  path = ./assets/file/AGENTS.md;
                  copyMode = "seed";
                };
              };
              "README.md" = {
                enable = true;
                src = {
                  path = ./assets/file/README.md;
                  copyMode = "seed";
                };
              };
            };
          };
        };
      }
      (lib.mkIf harness.build.enabled {
        ${namespace}.agent = {
          expert.experts = {
            scope-expert = lib.mkDefault scopeExpert;
            technical-expert = lib.mkDefault technicalExpert;
          }
          // lib.mapAttrs implementationExpert polyrepo.implementationExperts;

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
          // lib.optionalAttrs deliveryGuidanceEnabled {
            delivery-workflow = lib.mkDefault {
              description = "Correlate Artifact-Driven review units with delivery tickets";
              instructions = ''
                Use this skill when the Artifact-Polyrepo Workspace composition enables Agent Harness and Delivery Workflow.
                For Phase 1, run dw draft --classification requirement with the title, one description paragraph, all Requirement artifacts, and one to ten eligible assignees.
                For Phase 2, verify that the root Requirement is Accepted. Run dw handoff --requirement for each Specification and Decision ticket. Use the applicable classification and the same root Requirement.
                For Phase 3, verify acceptance of the complete Phase 2 set. Run dw handoff --requirement with classification task for each Task ticket.
                For phases 1-3, record each ticket URL in its artifacts under delivery.ticket front matter. Register the complete phase artifact set on one pull request. Assignment identifies GitHub work responsibility. It does not transfer artifact ownership or acceptance authority.
                For Phase 4, start an accepted Ready Task without a new assignment prompt. It reuses its existing builder assignment. Register the implementation pull request with the Task Issue.
                Verify the current pull request and ticket state before a transition. An accepted merge advances only the permitted ticket state. Archive phases 1-3 only after an explicit rejection. Keep an implementation ticket In Progress after rejection, close, or rework.
              '';
            };
          };
        };
      })
    ]
  );
}
