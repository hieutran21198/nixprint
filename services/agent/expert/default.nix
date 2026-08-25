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
        };
      };
      default = { };
      description = "Provider-neutral expert catalog";
    };
  };

  config = lib.mkIf harness.build.enabled {
    ${namespace}.agent.harness.build = {
      codex.experts = lib.mkIf harness.clients.codex.enable cfg.experts;
      claude.experts = lib.mkIf harness.clients.claude.enable cfg.experts;
      opencode.experts = lib.mkIf harness.clients.opencode.enable cfg.experts;
    };
  };
}
