{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.agent.harness;
  harnessOptions = import ./options.nix { inherit lib utils; };

  enabledClient = name: cfg.enable && cfg.clients.${name}.enable;
  enabledAnyClient = lib.any enabledClient [
    "codex"
    "claude"
    "opencode"
  ];

  skillDocument = name: skill: {
    enable = true;
    src = {
      text = ''
        ---
        name: ${builtins.toJSON name}
        description: ${builtins.toJSON skill.description}
        ---

        ${skill.instructions}
      '';
      copyMode = "copy";
    };
  };

  skillEntries = lib.mapAttrs (name: skill: {
    enable = true;
    entries."SKILL.md" = skillDocument name skill;
  }) cfg.build.skills;

  skillGuidance =
    expert:
    if expert.defaultSkills == [ ] then
      ""
    else
      ''

        Default workflow skills: ${builtins.concatStringsSep ", " expert.defaultSkills}.
        Use these skills when they are relevant. They are workflow preferences, not permission boundaries.
      '';

  claudeExpertDocument = name: expert: {
    enable = true;
    src = {
      text = ''
        ---
        name: ${builtins.toJSON name}
        description: ${builtins.toJSON expert.description}
        skills: ${builtins.toJSON expert.defaultSkills}
        ---

        ${expert.persistentInstructions}${skillGuidance expert}
      '';
      copyMode = "copy";
    };
  };

  opencodeExpertDocument = _: expert: {
    enable = true;
    src = {
      text = ''
        ---
        description: ${builtins.toJSON expert.description}
        mode: subagent
        ---

        ${expert.persistentInstructions}${skillGuidance expert}
      '';
      copyMode = "copy";
    };
  };

  codexExpertDocument = name: expert: {
    enable = true;
    src = {
      toml = {
        inherit name;
        inherit (expert) description;
        developer_instructions = "${expert.persistentInstructions}${skillGuidance expert}";
      };
      copyMode = "copy";
    };
  };

  codexExpertEntries = lib.mapAttrs' (
    name: expert: lib.nameValuePair "${name}.toml" (codexExpertDocument name expert)
  );
  claudeExpertEntries = lib.mapAttrs' (
    name: expert: lib.nameValuePair "${name}.md" (claudeExpertDocument name expert)
  );
  opencodeExpertEntries = lib.mapAttrs' (
    name: expert: lib.nameValuePair "${name}.md" (opencodeExpertDocument name expert)
  );
in
{
  options.${namespace}.agent.harness = harnessOptions.configurationOptions // {
    build = {
      enabled = utils.mkBoolOpt {
        readOnly = true;
        default = cfg.enable && enabledAnyClient;
        description = "Enable AI-agent harness file generation";
      };
      codex = {
        mcp = utils.mkAttrsOpt {
          ofType = lib.types.anything;
          default = { };
          description = "Generated Codex MCP configuration";
        };
        experts = utils.mkAttrsOpt {
          ofType = lib.types.anything;
          default = { };
          description = "Generated Codex expert configuration";
        };
      };
      claude = {
        mcp = utils.mkAttrsOpt {
          ofType = lib.types.anything;
          default = { };
          description = "Generated Claude Code MCP configuration";
        };
        experts = utils.mkAttrsOpt {
          ofType = lib.types.anything;
          default = { };
          description = "Generated Claude Code expert configuration";
        };
      };
      opencode = {
        mcp = utils.mkAttrsOpt {
          ofType = lib.types.anything;
          default = { };
          description = "Generated OpenCode MCP configuration";
        };
        experts = utils.mkAttrsOpt {
          ofType = lib.types.anything;
          default = { };
          description = "Generated OpenCode expert configuration";
        };
      };
      skills = utils.mkAttrsOpt {
        ofType = lib.types.anything;
        default = { };
        description = "Generated agent-neutral skill configuration";
      };
    };
  };

  config = {
    assertions = lib.optional cfg.enable {
      assertion = enabledAnyClient;
      message = "workspace.agent.harness requires at least one enabled client";
    };

    ${namespace}.file = lib.mkIf cfg.build.enabled (
      lib.mkMerge [
        (lib.mkIf (enabledClient "codex") {
          ".codex" = {
            enable = true;
            entries = {
              "config.toml" = {
                enable = true;
                src = {
                  toml = {
                    mcp_servers = cfg.build.codex.mcp;
                    skills.config = lib.mapAttrsToList (name: _: {
                      enabled = true;
                      path = ".agents/skills/${name}/SKILL.md";
                    }) cfg.build.skills;
                  };
                  copyMode = "copy";
                };
              };
              "agents" = {
                enable = true;
                entries = codexExpertEntries cfg.build.codex.experts;
              };
            };
          };
        })
        (lib.mkIf (enabledClient "claude") {
          ".mcp.json" = {
            enable = true;
            src = {
              json = {
                mcpServers = cfg.build.claude.mcp;
              };
              copyMode = "copy";
            };
          };
          ".claude" = {
            enable = true;
            entries = {
              "agents" = {
                enable = true;
                entries = claudeExpertEntries cfg.build.claude.experts;
              };
              "skills" = {
                enable = true;
                entries = skillEntries;
              };
            };
          };
          "CLAUDE.md" = {
            enable = true;
            src = {
              text = "@AGENTS.md\n";
              copyMode = "copy";
            };
          };
        })
        (lib.mkIf (enabledClient "opencode") {
          ".opencode" = {
            enable = true;
            entries = {
              "opencode.json" = {
                enable = true;
                src = {
                  json = {
                    "$schema" = "https://opencode.ai/config.json";
                    mcp.servers = cfg.build.opencode.mcp;
                  };
                  copyMode = "copy";
                };
              };
              "agents" = {
                enable = true;
                entries = opencodeExpertEntries cfg.build.opencode.experts;
              };
            };
          };
        })
        (lib.mkIf (enabledClient "codex" || enabledClient "opencode") {
          ".agents" = {
            enable = true;
            entries = {
              "skills" = {
                enable = true;
                entries = skillEntries;
              };
            };
          };
        })
      ]
    );
  };
}
