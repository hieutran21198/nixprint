let
  lib = import <nixpkgs/lib>;
  pkgs = import <nixpkgs> { };
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
    options.warnings = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    options.packages = lib.mkOption {
      type = lib.types.listOf lib.types.anything;
      default = [ ];
    };
    options.scripts = lib.mkOption {
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

    config._module.args.pkgs = pkgs;
  };

  evaluate =
    module:
    (lib.evalModules {
      specialArgs = { inherit namespace pkgs; };
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
      accepted = {
        id = "accepted";
        sources = [ "accepted" ];
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
        implementationBoundary.mode = "required";
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

  profileBase = evaluate {
    workspace.composition.use = "artifact-polyrepo-workspace";
  };

  profileAgent = evaluate {
    workspace.composition = {
      use = "artifact-polyrepo-workspace";
      agent = {
        enable = true;
        clients = {
          codex.enable = true;
          claude.enable = true;
          opencode.enable = true;
        };
      };
    };
    workspace.blueprint.polyrepo.implementationExperts.agent-service = {
      description = "Implement bounded changes in the agent service";
      writePaths = [ "services/agent" ];
      writeGlobs = [ "services/agent/**/*.nix" ];
      persistentInstructions = "Change only services/agent and report its validation evidence.";
      defaultSkills = [ "nix-module" ];
    };
  };

  profileDeliveryWithoutAgent = evaluate {
    workspace.composition = {
      use = "artifact-polyrepo-workspace";
      deliveryWorkflow = deliveryWorkflow;
    };
  };

  profileDeliveryWithAgent = evaluate {
    workspace.composition = {
      use = "artifact-polyrepo-workspace";
      agent = {
        enable = true;
        clients.codex.enable = true;
      };
      deliveryWorkflow = deliveryWorkflow;
    };
  };

  profileOverridesDirectEnabledAgent = evaluate {
    workspace.agent.harness = {
      enable = true;
      clients.codex.enable = true;
    };
    workspace.composition.use = "artifact-polyrepo-workspace";
  };

  profileOverridesDirectDisabledAgent = evaluate {
    workspace.agent.harness.enable = false;
    workspace.composition = {
      use = "artifact-polyrepo-workspace";
      agent = {
        enable = true;
        clients.codex.enable = true;
      };
    };
  };

  profileOverridesDirectDelivery = evaluate {
    workspace.delivery-workflow = deliveryWorkflow;
    workspace.composition.use = "artifact-polyrepo-workspace";
  };

  profileOverridesDirectTopology = evaluate {
    workspace.documentation.model = "unset";
    workspace.blueprint.use = "unset";
    workspace.composition.use = "artifact-polyrepo-workspace";
  };

  profileAgentWithoutClient = evaluate {
    workspace.composition = {
      use = "artifact-polyrepo-workspace";
      agent.enable = true;
    };
  };

  profileDeliveryWithoutGit = evaluate {
    workspace.git.hooks.enable = false;
    workspace.composition = {
      use = "artifact-polyrepo-workspace";
      deliveryWorkflow = deliveryWorkflow;
    };
  };

  directConfiguration = evaluate {
    workspace.documentation.model = "artifact-driven";
    workspace.blueprint.use = "polyrepo";
    workspace.agent.harness = {
      enable = true;
      clients.codex.enable = true;
    };
    workspace.delivery-workflow = deliveryWorkflow;
  };

  unboundedPolyrepo = evaluate {
    workspace.blueprint.use = "polyrepo";
    workspace.blueprint.polyrepo.implementationExperts.unbounded = {
      description = "Invalid Polyrepo implementation expert";
      writePaths = [ ];
      persistentInstructions = "This declaration must fail validation.";
    };
  };

  outsidePolyrepo = evaluate {
    workspace.blueprint.polyrepo.implementationExperts.agent-service = {
      description = "Invalid Polyrepo implementation expert";
      writePaths = [ "services/agent" ];
      persistentInstructions = "This declaration must fail validation.";
    };
  };

  legacyIntegrationOption = builtins.tryEval (
    (evaluate {
      workspace.integration.polyrepo-agent.implementationExperts.agent-service = {
        description = "Obsolete integration declaration";
        repository = "services/agent";
        persistentInstructions = "This declaration must fail evaluation.";
      };
    }).workspace.agent.expert.experts
  );

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

  claudeOpenCodeOnly = evaluate {
    workspace.agent.harness = {
      enable = true;
      clients = {
        claude.enable = true;
        opencode.enable = true;
      };
    };
    workspace.agent.expert.experts.nix-expert = {
      description = "Implement Nix modules";
      writePaths = [ "services/agent" ];
      writeGlobs = [ "services/agent/**/*.nix" ];
      persistentInstructions = "Change only Nix modules.";
    };
  };

  invalidWritePath = evaluate {
    workspace.blueprint.use = "polyrepo";
    workspace.blueprint.polyrepo.implementationExperts.invalid = {
      description = "Invalid path";
      writePaths = [ "../outside" ];
      persistentInstructions = "This declaration must fail validation.";
    };
  };

  invalidWriteGlob = evaluate {
    workspace.blueprint.use = "polyrepo";
    workspace.blueprint.polyrepo.implementationExperts.invalid = {
      description = "Invalid glob";
      writePaths = [ "services/agent" ];
      writeGlobs = [ "libs/**/*.nix" ];
      persistentInstructions = "This declaration must fail validation.";
    };
  };

  invalidGenericExpert = evaluate {
    workspace.agent = {
      harness = {
        enable = true;
        clients.codex.enable = true;
      };
      expert.experts.invalid = {
        description = "Invalid direct expert";
        writePaths = [ "../outside" ];
        persistentInstructions = "This declaration must fail validation.";
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
assert full.scripts ? workspace-agent-run;
assert lib.hasInfix "--ro-bind / /" full.scripts.workspace-agent-run.exec;
assert lib.elem pkgs.bubblewrap full.packages;
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
assert profileBase.workspace.composition.artifactPolyrepoWorkspace.build.enabled;
assert profileBase.workspace.documentation.model == "artifact-driven";
assert profileBase.workspace.blueprint.use == "polyrepo";
assert profileBase.workspace.file.".".entries ? "AGENTS.md";
assert profileBase.workspace.file.".".entries ? "README.md";
assert !profileBase.workspace.agent.harness.build.enabled;
assert !(profileBase.workspace.agent.expert.experts ? scope-expert);
assert profileAgent.workspace.agent.expert.experts ? scope-expert;
assert profileAgent.workspace.agent.expert.experts ? technical-expert;
assert profileAgent.workspace.agent.expert.experts ? agent-service;
assert profileAgent.workspace.agent.skill.skills ? semantic-artifact-review;
assert lib.elem "asd-ste100-writing"
  profileAgent.workspace.agent.expert.experts.scope-expert.defaultSkills;
assert profileAgent.files.".codex/agents/scope-expert.toml".toml.name == "scope-expert";
assert lib.hasInfix
  "skills: [\"artifact-driven-authoring\",\"asd-ste100-writing\",\"artifact-driven-coordination\"]"
  profileAgent.files.".claude/agents/scope-expert.md".text;
assert lib.hasInfix "Default workflow skills: nix-module."
  profileAgent.files.".opencode/agents/agent-service.md".text;
assert lib.hasInfix "permissions:" profileAgent.files.".opencode/agents/agent-service.md".text;
assert lib.hasInfix "services/agent/**/*.nix"
  profileAgent.files.".opencode/agents/agent-service.md".text;
assert lib.hasInfix "PreToolUse" profileAgent.files.".claude/agents/agent-service.md".text;
assert lib.hasInfix "validate-write" profileAgent.files.".claude/agents/agent-service.md".text;
assert lib.hasInfix "Write boundary: services/agent."
  profileAgent.files.".codex/agents/agent-service.toml".toml.developer_instructions;
assert lib.hasInfix "writeGlobs is not a portable Codex write boundary" (
  builtins.concatStringsSep "\n" profileAgent.warnings
);
assert profileDeliveryWithoutAgent.files ? ".dw/config.yaml";
assert profileDeliveryWithoutAgent.files ? ".github/workflows/dw-validate.yml";
assert !(profileDeliveryWithoutAgent.workspace.agent.skill.skills ? delivery-workflow);
assert profileDeliveryWithAgent.workspace.agent.skill.skills ? delivery-workflow;
assert lib.hasInfix "delivery-workflow"
  profileDeliveryWithAgent.files.".codex/agents/scope-expert.toml".toml.developer_instructions;
assert lib.hasInfix "delivery.ticket front matter"
  profileDeliveryWithAgent.files.".agents/skills/delivery-workflow/SKILL.md".text;
assert lib.hasInfix "--classification requirement"
  profileDeliveryWithAgent.files.".agents/skills/delivery-workflow/SKILL.md".text;
assert lib.hasInfix "root Requirement"
  profileDeliveryWithAgent.files.".agents/skills/delivery-workflow/SKILL.md".text;
assert lib.hasInfix "complete Phase 2 set"
  profileDeliveryWithAgent.files.".agents/skills/delivery-workflow/SKILL.md".text;
assert lib.hasInfix "classification task"
  profileDeliveryWithAgent.files.".agents/skills/delivery-workflow/SKILL.md".text;
assert !profileOverridesDirectEnabledAgent.workspace.agent.harness.enable;
assert !profileOverridesDirectEnabledAgent.workspace.agent.harness.build.enabled;
assert profileOverridesDirectDisabledAgent.workspace.agent.harness.build.enabled;
assert !profileOverridesDirectDelivery.workspace.delivery-workflow.enable;
assert !(profileOverridesDirectDelivery.files ? ".dw/config.yaml");
assert profileOverridesDirectTopology.workspace.documentation.model == "artifact-driven";
assert profileOverridesDirectTopology.workspace.blueprint.use == "polyrepo";
assert !(lib.all (entry: entry.assertion) profileAgentWithoutClient.assertions);
assert !(lib.all (entry: entry.assertion) profileDeliveryWithoutGit.assertions);
assert directConfiguration.workspace.composition.use == "unset";
assert directConfiguration.workspace.agent.harness.build.enabled;
assert directConfiguration.workspace.delivery-workflow.build.enabled;
assert !(directConfiguration.workspace.agent.expert.experts ? scope-expert);
assert !(lib.all (entry: entry.assertion) unboundedPolyrepo.assertions);
assert !(lib.all (entry: entry.assertion) outsidePolyrepo.assertions);
assert !(lib.all (entry: entry.assertion) invalidWritePath.assertions);
assert !(lib.all (entry: entry.assertion) invalidWriteGlob.assertions);
assert !(lib.all (entry: entry.assertion) invalidGenericExpert.assertions);
assert !legacyIntegrationOption.success;
assert !(codexOnly.files ? ".mcp.json");
assert !(codexOnly.files ? ".claude/agents/reviewer.md");
assert !(codexOnly.files ? ".opencode/agents/reviewer.md");
assert claudeOpenCodeOnly.warnings == [ ];
true
