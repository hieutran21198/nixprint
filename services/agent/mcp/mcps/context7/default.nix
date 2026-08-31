{
  config,
  namespace,
  lib,
  ...
}:
let
  pkgs = config._module.args.pkgs;
  inherit (config.${namespace}) utils;
  server = config.${namespace}.agent.mcp.servers.context7 or { enable = false; };
  cfg = config.${namespace}.agent.mcp.mcps.context7;
in
{
  options.${namespace}.agent.mcp.mcps.context7.package = utils.mkPackOpt {
    default = pkgs.context7-mcp;
    description = "Context7 MCP package; set a user-provided package to override the project default";
  };

  config = lib.mkIf server.enable {
    packages = [ cfg.package ];
  };
}
