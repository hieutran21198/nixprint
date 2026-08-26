{
  config,
  namespace,
  lib,
  ...
}:
let
  pkgs = config._module.args.pkgs;
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.agent.harness;
  harnessOptions = import ./options.nix { inherit lib utils; };

  enabledClient = name: cfg.enable && cfg.clients.${name}.enable;
  enabledAnyClient = lib.any enabledClient [
    "codex"
    "claude"
    "opencode"
  ];
  boundaryRequired = cfg.implementationBoundary.mode == "required";

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

  writeGuidance =
    name: expert:
    lib.optionalString (expert.writePaths != [ ]) ''

      Write boundary: ${builtins.concatStringsSep ", " expert.writePaths}.
      ${lib.optionalString (
        expert.writeGlobs != [ ]
      ) "Supported-client edit patterns: ${builtins.concatStringsSep ", " expert.writeGlobs}."}
      ${lib.optionalString boundaryRequired "Start implementation work with `devenv shell -- workspace-agent-run ${name} -- <client command>` so the required write boundary is enforced."}
    '';

  claudeHook =
    name: expert:
    lib.optionalString (expert.writePaths != [ ]) ''
      hooks:
        PreToolUse:
          - matcher: "Write|Edit"
            hooks:
              - type: command
                command: ${builtins.toJSON "bash \"$CLAUDE_PROJECT_DIR/.agents/bin/validate-write\" ${name}"}
    '';

  claudeExpertDocument = name: expert: {
    enable = true;
    src = {
      text = ''
        ---
        name: ${builtins.toJSON name}
        description: ${builtins.toJSON expert.description}
        skills: ${builtins.toJSON expert.defaultSkills}
        ${claudeHook name expert}---

        ${expert.persistentInstructions}${writeGuidance name expert}${skillGuidance expert}
      '';
      copyMode = "copy";
    };
  };

  opencodePermissions =
    expert:
    let
      patterns =
        if expert.writeGlobs != [ ] then
          expert.writeGlobs
        else
          lib.concatMap (path: [
            path
            "${path}/*"
          ]) expert.writePaths;
    in
    lib.optionalString (expert.writePaths != [ ]) (
      "permissions:\n  - action: edit\n    resource: \"*\"\n    effect: deny\n"
      + lib.concatMapStrings (
        pattern: "  - action: edit\n    resource: ${builtins.toJSON pattern}\n    effect: allow\n"
      ) patterns
    );

  opencodeExpertDocument = name: expert: {
    enable = true;
    src = {
      text = ''
        ---
        description: ${builtins.toJSON expert.description}
        mode: subagent
        ${opencodePermissions expert}---

        ${expert.persistentInstructions}${writeGuidance name expert}${skillGuidance expert}
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
        developer_instructions = "${expert.persistentInstructions}${writeGuidance name expert}${skillGuidance expert}";
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

  expertShellCase = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: expert: ''
      ${lib.escapeShellArg name})
        write_paths=(${lib.concatMapStringsSep " " lib.escapeShellArg expert.writePaths})
        ;;
    '') cfg.build.experts
  );

  claudeValidatorScript = ''
    set -euo pipefail

    expert="''${1:?expected expert id}"
    input="$(${pkgs.coreutils}/bin/cat)"
    file_path="$(printf '%s' "$input" | ${pkgs.jq}/bin/jq -r '.tool_input.file_path // empty')"

    if [ -z "$file_path" ]; then
      echo "Blocked: the write request has no file path" >&2
      exit 2
    fi

    root="$(${pkgs.git}/bin/git -C "$PWD" rev-parse --show-toplevel)"
    root="$(${pkgs.coreutils}/bin/realpath "$root")"
    target="$(${pkgs.coreutils}/bin/realpath -m "$file_path")"

    case "$target" in
      "$root"/*) relative_path="''${target#"$root"/}" ;;
      *)
        echo "Blocked: $file_path is outside the repository" >&2
        exit 2
        ;;
    esac

    case "$expert" in
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: expert: ''
        ${lib.escapeShellArg name})
          write_paths=(${lib.concatMapStringsSep " " lib.escapeShellArg expert.writePaths})
          write_globs=(${lib.concatMapStringsSep " " lib.escapeShellArg expert.writeGlobs})
          ;;
      '') cfg.build.experts
    )}
      *)
        echo "Blocked: unknown expert $expert" >&2
        exit 2
        ;;
    esac

    allowed=0
    if [ "''${#write_globs[@]}" -gt 0 ]; then
      for pattern in "''${write_globs[@]}"; do
        if [[ "$relative_path" == $pattern ]]; then
          allowed=1
          break
        fi
      done
    else
      for path in "''${write_paths[@]}"; do
        if [[ "$relative_path" == "$path" || "$relative_path" == "$path"/* ]]; then
          allowed=1
          break
        fi
      done
    fi

    if [ "$allowed" -ne 1 ]; then
      echo "Blocked: $relative_path is outside the $expert write boundary" >&2
      exit 2
    fi
  '';

  runnerScript = ''
    set -euo pipefail

    if [ "$#" -lt 3 ] || [ "$2" != "--" ]; then
      echo "Usage: workspace-agent-run <expert-id> -- <client command...>" >&2
      exit 64
    fi

    expert="$1"
    shift 2
    root="$(${pkgs.git}/bin/git -C "$PWD" rev-parse --show-toplevel)"
    root="$(${pkgs.coreutils}/bin/realpath "$root")"

    case "$expert" in
    ${expertShellCase}
      *)
        echo "Unknown implementation expert: $expert" >&2
        exit 64
        ;;
    esac

    if [ "''${#write_paths[@]}" -eq 0 ]; then
      echo "Implementation expert $expert has no writePaths" >&2
      exit 64
    fi

    bwrap_args=(
      --die-with-parent
      --unshare-user
      --uid 0
      --gid 0
      --disable-userns
      --ro-bind / /
      --dev-bind /dev /dev
      --proc /proc
      --tmpfs /tmp
    )

    for path in "''${write_paths[@]}"; do
      target="$root/$path"
      if [ ! -e "$target" ]; then
        echo "Declared write path does not exist: $path. Declare an existing parent directory to create new files." >&2
        exit 64
      fi

      target="$(${pkgs.coreutils}/bin/realpath "$target")"
      case "$target" in
        "$root"/*) ;;
        *)
          echo "Declared write path escapes the repository: $path" >&2
          exit 64
          ;;
      esac
      bwrap_args+=(--bind "$target" "$target")
    done

    exec ${pkgs.bubblewrap}/bin/bwrap "''${bwrap_args[@]}" --chdir "$root" -- "$@"
  '';
in
{
  options.${namespace}.agent.harness = harnessOptions.configurationOptions // {
    build = {
      enabled = utils.mkBoolOpt {
        readOnly = true;
        default = cfg.enable && enabledAnyClient;
        description = "Enable AI-agent harness file generation";
      };
      experts = utils.mkAttrsOpt {
        ofType = lib.types.anything;
        default = { };
        description = "Generated client-neutral expert metadata";
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

  config = lib.mkMerge [
    {
      assertions =
        lib.optional cfg.enable {
          assertion = enabledAnyClient;
          message = "workspace.agent.harness requires at least one enabled client";
        }
        ++ lib.optional boundaryRequired {
          assertion = cfg.build.enabled;
          message = "workspace.agent.harness.implementationBoundary.mode = required requires an enabled harness client";
        }
        ++ lib.optional boundaryRequired {
          assertion = pkgs.stdenv.hostPlatform.isLinux;
          message = "workspace.agent.harness.implementationBoundary.mode = required is supported only on Linux";
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
          (lib.mkIf enabledAnyClient {
            ".agents" = {
              enable = true;
              entries = {
                "skills" = {
                  enable = true;
                  entries = skillEntries;
                };
                "bin" = {
                  enable = true;
                  entries."validate-write" = {
                    enable = true;
                    src = {
                      text = claudeValidatorScript;
                      copyMode = "copy";
                    };
                  };
                };
              };
            };
          })
        ]
      );
    }
    (lib.mkIf (cfg.build.enabled && boundaryRequired) {
      packages = [ pkgs.bubblewrap ];
      scripts.workspace-agent-run.exec = runnerScript;
    })
  ];
}
