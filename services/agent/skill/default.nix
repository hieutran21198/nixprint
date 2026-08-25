{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.agent.skill;
  harness = config.${namespace}.agent.harness;
in
{
  options.${namespace}.agent.skill = {
    skills = utils.mkAttrsOpt {
      ofType = lib.types.submodule {
        options = {
          description = utils.mkStrOpt {
            description = "When an agent should load this skill";
          };
          instructions = utils.mkStrOpt {
            description = "Agent Skills-compatible skill content";
          };
        };
      };
      default = { };
      description = "Agent-neutral project skill definitions";
    };
  };

  config = lib.mkIf harness.build.enabled {
    ${namespace}.agent.harness.build.skills = cfg.skills;
  };
}
