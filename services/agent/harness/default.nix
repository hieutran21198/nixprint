{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.agent.harness;

  clientModule = lib.types.submodule {
    options.enable = utils.mkBoolOpt {
      default = false;
      description = "Enable this AI-agent client for the project";
    };
  };

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

  claudeRoleDocument = name: role: {
    enable = true;
    src = {
      text = ''
        ---
        name: ${builtins.toJSON name}
        description: ${builtins.toJSON role.description}
        skills: ${builtins.toJSON role.skills}
        ---

        ${role.instructions}
      '';
      copyMode = "copy";
    };
  };

  opencodeRoleDocument = _: role: {
    enable = true;
    src = {
      text = ''
        ---
        description: ${builtins.toJSON role.description}
        mode: subagent
        ---

        ${role.instructions}
      '';
      copyMode = "copy";
    };
  };

  codexRoleDocument = _: role: {
    enable = true;
    src = {
      toml = role;
      copyMode = "copy";
    };
  };

  codexRoleEntries = lib.mapAttrs' (
    name: role: lib.nameValuePair "${name}.toml" (codexRoleDocument name role)
  );
  claudeRoleEntries = lib.mapAttrs' (
    name: role: lib.nameValuePair "${name}.md" (claudeRoleDocument name role)
  );
  opencodeRoleEntries = lib.mapAttrs' (
    name: role: lib.nameValuePair "${name}.md" (opencodeRoleDocument name role)
  );
in
{
  options.${namespace}.agent.harness = {
    enable = utils.mkBoolOpt {
      default = false;
      description = "Enable project AI-agent harness configuration";
    };

    clients = {
      codex = lib.mkOption {
        type = clientModule;
        default = { };
        description = "Codex project client configuration";
      };
      claude = lib.mkOption {
        type = clientModule;
        default = { };
        description = "Claude Code project client configuration";
      };
      opencode = lib.mkOption {
        type = clientModule;
        default = { };
        description = "OpenCode project client configuration";
      };
    };

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
        roles = utils.mkAttrsOpt {
          ofType = lib.types.anything;
          default = { };
          description = "Generated Codex role configuration";
        };
      };
      claude = {
        mcp = utils.mkAttrsOpt {
          ofType = lib.types.anything;
          default = { };
          description = "Generated Claude Code MCP configuration";
        };
        roles = utils.mkAttrsOpt {
          ofType = lib.types.anything;
          default = { };
          description = "Generated Claude Code role configuration";
        };
      };
      opencode = {
        mcp = utils.mkAttrsOpt {
          ofType = lib.types.anything;
          default = { };
          description = "Generated OpenCode MCP configuration";
        };
        roles = utils.mkAttrsOpt {
          ofType = lib.types.anything;
          default = { };
          description = "Generated OpenCode role configuration";
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
                      path = ".agents/skills/${name}/SKILL.md";
                    }) cfg.build.skills;
                  };
                  copyMode = "copy";
                };
              };
              "agents" = {
                enable = true;
                entries = codexRoleEntries cfg.build.codex.roles;
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
                entries = claudeRoleEntries cfg.build.claude.roles;
              };
              "skills" = {
                enable = true;
                entries = skillEntries;
              };
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
                entries = opencodeRoleEntries cfg.build.opencode.roles;
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
