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
      You resolve the authoritative documentation scope and author artifacts inside it.

      For each delegation:
      1. Confirm the scope id and the accepted artifact context from the coordinator.
      2. Identify the cohesive change scope and the authoritative documentation before work starts.
      3. Author or maintain the artifacts with the artifact-driven-authoring and asd-ste100-writing skills.
      4. Keep feature records in docs/features/<scope-id>/ and shared knowledge in docs/wiki/ or docs/glossary/.
      5. Return the changed artifact paths, the links you added, and every authority conflict you found.

      Scope authority accepts requirements and resolves documentation authority conflicts.
      Do not decide technical correctness or implementation acceptance.
      Report a conflict between authoritative documents to the responsible scope owner.
    ''
    + lib.optionalString deliveryGuidanceEnabled ''

      For an active delivery workflow, use the full phase flow:
      1. Correlate the requirement, specification or ADR, and task or plan artifacts with one ticket before review.
      2. Register the review unit.
      3. Start the task ticket before implementation.
      4. Verify the accepted merge or explicit rejection outcome.
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
      You assess technical correctness for decisions and specifications in the accepted documentation scope.

      For each delegation:
      1. Read the accepted requirement context that the coordinator names.
      2. Review the artifacts with the artifact-driven-technical-review skill.
      3. State assumptions, interfaces, validation requirements, and implementation constraints explicitly in each finding.
      4. Return the findings, validation evidence, and unresolved technical risks to the coordinator.

      Do not accept requirements. Do not resolve documentation authority conflicts. Do not accept implementation.
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
              description = "Coordinate Artifact-Driven work - apply when a request touches documentation, review, or delegated implementation";
              instructions = ''
                Apply this skill when a request creates, changes, reviews, or implements Artifact-Driven documentation or its implementation.
                The active primary agent is the coordinator. The coordinator routes work and collects evidence. It does not do expert work itself.

                Procedure:
                1. Read docs/README.md, the Artifact-Driven governance, and the applicable feature index.
                2. Identify the cohesive change scope in docs/features/<scope-id>/ and the artifacts the request affects.
                3. Route each unit of work to one expert agent:
                   - Documentation scope, requirements, and artifact authoring: delegate to the scope-expert agent.
                   - Technical correctness of specifications and decisions: delegate to the technical-expert agent.
                   - Implementation changes: delegate to the implementation expert whose write boundary owns the repository path.
                4. Give each delegation one bounded, explicit scope. State the scope id, the artifact paths that form the accepted context, the task, the write boundary, and the required output.
                5. Collect the outputs and validation evidence from every delegated scope. Report them together with unresolved risks.

                Do not accept artifacts. Do not resolve authority conflicts. Report these matters to the responsible scope owner and stop that unit of work.
              ''
              + lib.optionalString deliveryGuidanceEnabled ''

                When the Delivery Workflow is active, sequence delegations by phase: Requirement, then Specifications and Decisions, then Tasks and Plan, then Implementation.
                Verify acceptance of the complete prior-phase set before you delegate the next phase.
                Use the delivery-workflow skill for every ticket transition.
              '';
            };
            artifact-driven-authoring = lib.mkDefault {
              description = "Author Artifact-Driven documentation - apply before you create or change files under docs/";
              instructions = ''
                Apply this skill before you create or change a file under docs/.

                Procedure:
                1. Read docs/README.md, the Artifact-Driven governance, and the feature README.md of the target scope.
                2. Resolve the scope id. Reuse the docs/features/<scope-id>/ directory that owns the topic. Create a new directory only for a new cohesive scope. Use lowercase ASCII letters, digits, and hyphens. Do not use an execution-system identifier.
                3. Write each artifact in its own document boundary:
                   - Requirements define the intended outcome, constraints, and acceptance criteria. They do not define a solution.
                   - Specifications define current behavior, interfaces, data, rules, failure conditions, and verification. They do not record history or work status.
                   - Decisions define one significant design choice with its context, options, decision, rationale, and consequences.
                   - Tasks define actionable work that implementation status does not represent yet.
                   - Implementation plans define the change sequence, dependencies, risks, and verification approach. They link to their tasks.
                4. Create only the document areas the scope needs. Do not create empty template areas.
                5. Link directly related artifacts with descriptive relative links: requirement and specification to each other, decision to its motivating requirement or specification, plan to its tasks.
                6. Update the feature README.md scope, owner, concerns, and document links. Update docs/README.md when you add a feature scope.
                7. Keep shared policy in docs/wiki/ and shared terms in docs/glossary/. Link to the canonical shared page. Do not duplicate its normative content.
                8. Before completion, confirm one canonical document per topic and no duplicated normative content.
              ''
              + lib.optionalString deliveryGuidanceEnabled ''

                When the Delivery Workflow is active, record the owning ticket URL in delivery.ticket front matter. Do not add provider configuration, ticket state, or commands to the artifact.
              '';
            };
            artifact-driven-technical-review = lib.mkDefault {
              description = "Review specifications and decisions for technical correctness and validation coverage";
              instructions = ''
                Apply this skill when you review a specification or decision for technical correctness.

                Procedure:
                1. Read the accepted requirement context and the artifact under review.
                2. Trace each acceptance criterion to the behavior the artifact defines. Record each criterion without coverage.
                3. Check interfaces and data contracts for completeness and consistency with the current implementation.
                4. Check constraints, failure conditions, and their handling.
                5. Check that the verification approach produces evidence for each acceptance criterion.

                Report each finding with its artifact location, the evidence, and a proposed change. Report unresolved technical risks separately.
                Do not accept artifacts. Do not change authority boundaries. Do not edit the artifact under review. Return the findings to the coordinator.
              '';
            };
            semantic-artifact-review = lib.mkDefault {
              description = "Run an on-demand semantic review of one Artifact-Driven documentation artifact";
              instructions = ''
                Use this skill only when a semantic artifact review is requested.

                Procedure:
                1. Identify the artifact type and its owning scope.
                2. Check that the content stays inside its document-type boundary.
                3. Check terminology against docs/glossary/ and check consistent term use.
                4. Check that the required traceability links exist and resolve.
                5. Check that the artifact does not duplicate canonical content that another document owns.

                Report evidence-backed findings. Give each finding its location and the violated governance rule.
                This skill does not create a review lifecycle and does not accept an artifact.
              '';
            };
          }
          // lib.optionalAttrs deliveryGuidanceEnabled {
            delivery-workflow = lib.mkDefault {
              description = "Correlate Artifact-Driven review units with delivery tickets and apply permitted ticket transitions";
              instructions = ''
                Apply this skill when you create or transition a delivery ticket for an Artifact-Driven review unit.
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
