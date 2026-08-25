let
  lib = import <nixpkgs/lib>;
  namespace = "workspace";
  nsImporter = import ../../../libs/nix-utils/_importer.nix { inherit namespace; };
  evaluation = lib.evalModules {
    specialArgs = { inherit namespace; };
    modules = [
      {
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
      }
      {
        imports = nsImporter [
          ../../../libs
          ../../../services
        ];

        secretspec = {
          enable = true;
          secrets.DOCUMENTATION_TOKEN = "test-token";
        };

        workspace.agent = {
          harness = {
            enable = true;
            clients = {
              codex.enable = true;
              claude.enable = true;
              opencode.enable = true;
            };
          };

          mcp.servers.documentation = {
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

          role.roles.reviewer = {
            description = "Review changes without making edits";
            instructions = "Inspect the change and report only actionable findings.";
            skills = [ "review-guidance" ];
          };

          skill.skills.review-guidance = {
            description = "Review project changes for correctness and missing tests";
            instructions = "Check behavior, security, and test coverage.";
          };
        };
      }
    ];
  };
  cfg = evaluation.config;
  files = cfg.files;
in
assert cfg.workspace.agent.harness.build.enabled;
assert lib.all (entry: entry.assertion) cfg.assertions;
assert
  cfg.workspace.agent.harness.build.codex.mcp.documentation.env_vars == [ "DOCUMENTATION_TOKEN" ];
assert
  cfg.workspace.agent.harness.build.claude.mcp.documentation.env.DOCUMENTATION_TOKEN
  == "\${DOCUMENTATION_TOKEN}";
assert
  cfg.workspace.agent.harness.build.opencode.mcp.documentation.environment.DOCUMENTATION_TOKEN
  == "{env:DOCUMENTATION_TOKEN}";
assert
  files.".codex/config.toml".toml.mcp_servers.documentation.env_vars == [ "DOCUMENTATION_TOKEN" ];
assert
  files.".mcp.json".json.mcpServers.documentation.env.DOCUMENTATION_TOKEN
  == "\${DOCUMENTATION_TOKEN}";
assert
  files.".opencode/opencode.json".json.mcp.servers.documentation.environment.DOCUMENTATION_TOKEN
  == "{env:DOCUMENTATION_TOKEN}";
assert
  files.".codex/agents/reviewer.toml".toml.developer_instructions
  == "Inspect the change and report only actionable findings.";
assert lib.hasInfix "mode: subagent" files.".opencode/agents/reviewer.md".text;
assert lib.hasInfix "name: \"review-guidance\""
  files.".agents/skills/review-guidance/SKILL.md".text;
assert cfg.env.DOCUMENTATION_TOKEN == "test-token";
assert !(lib.hasInfix "test-token" (builtins.toJSON files));
true
