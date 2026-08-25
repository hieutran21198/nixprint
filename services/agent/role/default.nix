{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.agent.role;
  harness = config.${namespace}.agent.harness;

  codexRole = name: role: {
    inherit name;
    description = role.description;
    developer_instructions = role.instructions;
  };
in
{
  options.${namespace}.agent.role = {
    roles = utils.mkAttrsOpt {
      ofType = lib.types.submodule {
        options = {
          description = utils.mkStrOpt {
            description = "When the parent agent should use this role";
          };
          instructions = utils.mkStrOpt {
            description = "Role-specific operating instructions";
          };
          skills = utils.mkListOpt {
            ofType = lib.types.str;
            default = [ ];
            description = "Agent-neutral skill IDs preloaded by compatible clients";
          };
        };
      };
      default = { };
      description = "Agent-neutral named subagent roles";
    };
  };

  config = lib.mkIf harness.build.enabled {
    ${namespace}.agent.harness.build = {
      codex.roles = lib.mkIf harness.clients.codex.enable (lib.mapAttrs codexRole cfg.roles);
      claude.roles = lib.mkIf harness.clients.claude.enable cfg.roles;
      opencode.roles = lib.mkIf harness.clients.opencode.enable cfg.roles;
    };
  };
}
