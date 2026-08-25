let
  lib = import <nixpkgs/lib>;
  namespace = "workspace";
  nsImporter = import ../../../libs/nix-utils/_importer.nix { inherit namespace; };

  baseModule = {
    options.assertions = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
    };
    options.files = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
    };
    options.git-hooks = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
    };
    options.env = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
    options.secretspec = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          secrets = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
          };
        };
      };
      default = { };
    };

    imports = nsImporter [
      ../../../libs
      ../../../services
    ];

    config.secretspec = {
      enable = true;
      secrets.DOCUMENTATION_TOKEN = "test-token";
    };
  };

  evaluate =
    module:
    (lib.evalModules {
      specialArgs = { inherit namespace; };
      modules = [
        baseModule
        module
      ];
    }).config;

  standardMcp = {
    command = [
      "npx"
      "-y"
      "@example/documentation-mcp"
    ];
    cwd = ./.;
    environment = {
      LOG_LEVEL = "info";
      DOCUMENTATION_TOKEN.secret = "DOCUMENTATION_TOKEN";
    };
  };

  deliveryWorkflow = {
    enable = true;
    github = {
      repository = "example/repository";
      project = {
        owner = "example";
        number = 1;
        id = "project-node";
        statusFieldId = "status-field";
      };
    };
    authorizerTeams = [ "delivery-maintainers" ];
    states = {
      draft = {
        id = "draft";
        sources = [ "draft" ];
      };
      ready = {
        id = "ready";
        sources = [ "ready" ];
      };
      inProgress = {
        id = "in-progress";
        sources = [ "in-progress" ];
      };
      archived = {
        id = "archived";
        sources = [ "archived" ];
      };
      implementationAccepted = {
        id = "accepted";
        sources = [ "accepted" ];
      };
    };
  };

  full = evaluate {
    workspace.agent = {
      harness = {
        enable = true;
        clients = {
          codex.enable = true;
          claude.enable = true;
          opencode.enable = true;
        };
      };
      mcp.servers.documentation = standardMcp;
      expert.experts.reviewer = {
        description = "Review changes without making edits";
        persistentInstructions = "Inspect the change and report only actionable findings.";
        defaultSkills = [ "review-guidance" ];
      };
      skill.skills.review-guidance = {
        description = "Review project changes for correctness and missing tests";
        instructions = "Check behavior, security, and test coverage.";
      };
    };
  };

  artifactOnly = evaluate {
    workspace.documentation.model = "artifact-driven";
    workspace.agent.harness = {
      enable = true;
      clients.codex.enable = true;
    };
  };

  artifactWithoutHarness = evaluate {
    workspace.documentation.model = "artifact-driven";
  };

  artifactDeliveryWithoutHarness = evaluate {
    workspace.documentation.model = "artifact-driven";
    workspace.delivery-workflow = deliveryWorkflow;
  };

  artifactDeliveryWithHarness = evaluate {
    workspace.documentation.model = "artifact-driven";
    workspace.delivery-workflow = deliveryWorkflow;
    workspace.agent.harness = {
      enable = true;
      clients.codex.enable = true;
    };
  };

  invalidDeliveryWorkflow = evaluate {
    workspace.delivery-workflow = deliveryWorkflow;
  };

  polyrepoOnly = evaluate {
    workspace.blueprint.use = "polyrepo";
    workspace.agent.harness = {
      enable = true;
      clients.claude.enable = true;
    };
    workspace.integration.polyrepo-agent.implementationExperts.agent-service = {
      description = "Implement bounded changes in the agent service";
      implementationArea = "services/agent/harness";
      persistentInstructions = "Change only services/agent and report its validation evidence.";
      defaultSkills = [ "nix-module" ];
    };
  };

  combined = evaluate {
    workspace.documentation.model = "artifact-driven";
    workspace.blueprint.use = "polyrepo";
    workspace.agent.harness = {
      enable = true;
      clients = {
        codex.enable = true;
        claude.enable = true;
        opencode.enable = true;
      };
    };
    workspace.integration.polyrepo-agent.implementationExperts.agent-service = {
      description = "Implement bounded changes in the agent service";
      repository = "services/agent";
      persistentInstructions = "Change only services/agent and report its validation evidence.";
      defaultSkills = [ "nix-module" ];
    };
  };

  unboundedPolyrepo = evaluate {
    workspace.blueprint.use = "polyrepo";
    workspace.agent.harness = {
      enable = true;
      clients.codex.enable = true;
    };
    workspace.integration.polyrepo-agent.implementationExperts.unbounded = {
      description = "Invalid Polyrepo implementation expert";
      persistentInstructions = "This declaration must fail validation.";
    };
  };

  outsidePolyrepo = evaluate {
    workspace.integration.polyrepo-agent.implementationExperts.agent-service = {
      description = "Invalid Polyrepo implementation expert";
      repository = "services/agent";
      persistentInstructions = "This declaration must fail validation.";
    };
  };

  legacyPolyrepoOption = builtins.tryEval (
    (evaluate {
      workspace.agent.expert.polyrepo.implementationExperts.agent-service = {
        description = "Obsolete Polyrepo implementation expert";
        repository = "services/agent";
        persistentInstructions = "This declaration must fail evaluation.";
      };
    }).workspace.agent.expert.experts
  );

  polyrepoWithoutHarness = evaluate {
    workspace.blueprint.use = "polyrepo";
    workspace.integration.polyrepo-agent.implementationExperts.agent-service = {
      description = "Implement bounded changes in the agent service";
      repository = "services/agent";
      persistentInstructions = "Change only services/agent and report its validation evidence.";
      defaultSkills = [ "nix-module" ];
    };
  };

  codexOnly = evaluate {
    workspace.agent = {
      harness = {
        enable = true;
        clients.codex.enable = true;
      };
      expert.experts.reviewer = {
        description = "Review changes";
        persistentInstructions = "Review only the requested change.";
      };
    };
  };
in
assert full.workspace.agent.harness.build.enabled;
assert lib.all (entry: entry.assertion) full.assertions;
assert
  full.workspace.agent.harness.build.codex.mcp.documentation.env_vars == [ "DOCUMENTATION_TOKEN" ];
assert
  full.workspace.agent.harness.build.claude.mcp.documentation.env.DOCUMENTATION_TOKEN
  == "\${DOCUMENTATION_TOKEN}";
assert
  full.workspace.agent.harness.build.opencode.mcp.documentation.environment.DOCUMENTATION_TOKEN
  == "{env:DOCUMENTATION_TOKEN}";
assert
  full.files.".codex/config.toml".toml.mcp_servers.documentation.env_vars
  == [ "DOCUMENTATION_TOKEN" ];
assert lib.all (skill: skill.enabled) full.files.".codex/config.toml".toml.skills.config;
assert
  full.files.".mcp.json".json.mcpServers.documentation.env.DOCUMENTATION_TOKEN
  == "\${DOCUMENTATION_TOKEN}";
assert
  full.files.".opencode/opencode.json".json.mcp.servers.documentation.environment.DOCUMENTATION_TOKEN
  == "{env:DOCUMENTATION_TOKEN}";
assert lib.hasInfix "Default workflow skills: review-guidance."
  full.files.".codex/agents/reviewer.toml".toml.developer_instructions;
assert lib.hasInfix "skills: [\"review-guidance\"]" full.files.".claude/agents/reviewer.md".text;
assert lib.hasInfix "mode: subagent" full.files.".opencode/agents/reviewer.md".text;
assert lib.hasInfix "name: \"review-guidance\""
  full.files.".agents/skills/review-guidance/SKILL.md".text;
assert full.workspace.agent.skill.skills ? asd-ste100-writing;
assert lib.hasInfix "name: \"asd-ste100-writing\""
  full.files.".agents/skills/asd-ste100-writing/SKILL.md".text;
assert full.files."CLAUDE.md".text == "@AGENTS.md\n";
assert full.env.DOCUMENTATION_TOKEN == "test-token";
assert !(lib.hasInfix "test-token" (builtins.toJSON full.files));
assert artifactOnly.workspace.agent.expert.experts ? scope-expert;
assert artifactOnly.workspace.agent.expert.experts ? technical-expert;
assert artifactOnly.workspace.agent.skill.skills ? semantic-artifact-review;
assert lib.elem "asd-ste100-writing"
  artifactOnly.workspace.agent.expert.experts.scope-expert.defaultSkills;
assert artifactOnly.workspace.integration.artifact-driven-agent.build.enabled;
assert !(artifactWithoutHarness.workspace.agent.expert.experts ? scope-expert);
assert !(artifactWithoutHarness.workspace.agent.skill.skills ? semantic-artifact-review);
assert !artifactWithoutHarness.workspace.integration.artifact-driven-agent.build.enabled;
assert !artifactOnly.workspace.integration.artifact-driven-delivery-workflow.build.enabled;
assert
  artifactDeliveryWithoutHarness.workspace.integration.artifact-driven-delivery-workflow.build.enabled;
assert !(artifactDeliveryWithoutHarness.workspace.agent.expert.experts ? scope-expert);
assert !artifactDeliveryWithoutHarness.workspace.integration.artifact-driven-agent.build.enabled;
assert artifactDeliveryWithoutHarness.files ? ".dw/config.yaml";
assert artifactDeliveryWithoutHarness.files ? ".github/workflows/dw-validate.yml";
assert artifactDeliveryWithoutHarness.files ? ".github/workflows/dw-transition.yml";
assert artifactDeliveryWithoutHarness.files ? ".github/workflows/dw-reconcile.yml";
assert
  artifactDeliveryWithHarness.workspace.integration.artifact-driven-delivery-workflow.build.enabled;
assert artifactDeliveryWithHarness.workspace.agent.skill.skills ? delivery-workflow;
assert lib.hasInfix "delivery-workflow"
  artifactDeliveryWithHarness.files.".codex/agents/scope-expert.toml".toml.developer_instructions;
assert lib.hasInfix "delivery.ticket front matter"
  artifactDeliveryWithHarness.files.".agents/skills/delivery-workflow/SKILL.md".text;
assert !(lib.all (entry: entry.assertion) invalidDeliveryWorkflow.assertions);
assert polyrepoOnly.workspace.agent.expert.experts ? agent-service;
assert !(polyrepoOnly.workspace.agent.expert.experts ? scope-expert);
assert polyrepoOnly.workspace.integration.polyrepo-agent.build.enabled;
assert !(polyrepoWithoutHarness.workspace.agent.expert.experts ? agent-service);
assert !polyrepoWithoutHarness.workspace.integration.polyrepo-agent.build.enabled;
assert combined.workspace.agent.expert.experts ? scope-expert;
assert combined.workspace.agent.expert.experts ? technical-expert;
assert combined.workspace.agent.expert.experts ? agent-service;
assert combined.workspace.integration.artifact-driven-agent.build.enabled;
assert combined.workspace.integration.polyrepo-agent.build.enabled;
assert combined.files.".codex/agents/scope-expert.toml".toml.name == "scope-expert";
assert lib.hasInfix
  "skills: [\"artifact-driven-authoring\",\"asd-ste100-writing\",\"artifact-driven-coordination\"]"
  combined.files.".claude/agents/scope-expert.md".text;
assert lib.hasInfix "Default workflow skills: nix-module."
  combined.files.".opencode/agents/agent-service.md".text;
assert combined.files."CLAUDE.md".text == "@AGENTS.md\n";
assert !(lib.all (entry: entry.assertion) unboundedPolyrepo.assertions);
assert !(lib.all (entry: entry.assertion) outsidePolyrepo.assertions);
assert !legacyPolyrepoOption.success;
assert !(codexOnly.files ? ".mcp.json");
assert !(codexOnly.files ? ".claude/agents/reviewer.md");
assert !(codexOnly.files ? ".opencode/agents/reviewer.md");
true
