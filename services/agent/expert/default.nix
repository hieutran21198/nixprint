{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.agent.expert;
  harness = config.${namespace}.agent.harness;
  hasGlob =
    value:
    lib.any (marker: lib.hasInfix marker value) [
      "*"
      "?"
      "["
      "]"
    ];
  relativePath =
    value:
    value != ""
    && value != "."
    && !(lib.hasPrefix "/" value)
    && !(lib.hasPrefix "~" value)
    && !(lib.elem ".." (lib.splitString "/" value));
  leadingLiteralSegments =
    segments:
    if segments == [ ] || hasGlob (builtins.head segments) then
      [ ]
    else
      [ (builtins.head segments) ] ++ leadingLiteralSegments (builtins.tail segments);
  literalGlobPrefix =
    value: lib.concatStringsSep "/" (leadingLiteralSegments (lib.splitString "/" value));
  globContainedBy =
    paths: glob:
    let
      prefix = literalGlobPrefix glob;
    in
    prefix != "" && lib.any (path: prefix == path || lib.hasPrefix "${path}/" prefix) paths;
  expertAssertions = lib.flatten (
    lib.mapAttrsToList (name: expert: [
      {
        assertion = lib.all (path: relativePath path && !hasGlob path) expert.writePaths;
        message = "workspace.agent.expert.experts.${name}.writePaths must contain non-root, repository-relative paths without glob patterns or parent traversal";
      }
      {
        assertion = builtins.length expert.writePaths == builtins.length (lib.unique expert.writePaths);
        message = "workspace.agent.expert.experts.${name}.writePaths must not contain duplicates";
      }
      {
        assertion = lib.all (glob: relativePath glob && hasGlob glob) expert.writeGlobs;
        message = "workspace.agent.expert.experts.${name}.writeGlobs must contain repository-relative glob patterns without parent traversal";
      }
      {
        assertion = builtins.length expert.writeGlobs == builtins.length (lib.unique expert.writeGlobs);
        message = "workspace.agent.expert.experts.${name}.writeGlobs must not contain duplicates";
      }
      {
        assertion = lib.all (glob: globContainedBy expert.writePaths glob) expert.writeGlobs;
        message = "workspace.agent.expert.experts.${name}.writeGlobs must narrow a declared writePath";
      }
    ]) cfg.experts
  );
in
{
  options.${namespace}.agent.expert = {
    experts = utils.mkAttrsOpt {
      ofType = lib.types.submodule {
        options = {
          description = utils.mkStrOpt {
            description = "When the coordinator should use this expert";
          };
          persistentInstructions = utils.mkStrOpt {
            description = "Persistent operating instructions for this expert";
          };
          defaultSkills = utils.mkListOpt {
            ofType = lib.types.str;
            default = [ ];
            description = "Portable workflow skill preferences for this expert";
          };
          writePaths = utils.mkListOpt {
            ofType = lib.types.str;
            default = [ ];
            description = "Repository-relative files or directory roots that this expert can modify";
          };
          writeGlobs = utils.mkListOpt {
            ofType = lib.types.str;
            default = [ ];
            description = "Optional repository-relative edit patterns that narrow writePaths for supported clients";
          };
        };
      };
      default = { };
      description = "Provider-neutral expert catalog";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf harness.build.enabled {
      ${namespace}.agent.harness.build = {
        experts = cfg.experts;
        codex.experts = lib.mkIf harness.clients.codex.enable cfg.experts;
        claude.experts = lib.mkIf harness.clients.claude.enable cfg.experts;
        opencode.experts = lib.mkIf harness.clients.opencode.enable cfg.experts;
      };
    })
    {
      assertions = expertAssertions;
      warnings = lib.optionals (harness.build.enabled && harness.clients.codex.enable) (
        lib.filter (warning: warning != "") (
          lib.mapAttrsToList (
            name: expert:
            lib.optionalString (expert.writeGlobs != [ ])
              "workspace.agent.expert.experts.${name}.writeGlobs is not a portable Codex write boundary. Codex will enforce writePaths only. writeGlobs are emitted as additional edit policy for Claude Code and OpenCode. Use directory roots or explicit files in writePaths for required enforcement."
          ) cfg.experts
        )
      );
    }
  ];
}
