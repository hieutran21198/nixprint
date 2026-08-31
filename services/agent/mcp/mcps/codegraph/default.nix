{
  config,
  namespace,
  lib,
  ...
}:
let
  pkgs = config._module.args.pkgs;
  inherit (config.${namespace}) utils;
  server = config.${namespace}.agent.mcp.servers.codegraph or { enable = false; };
  cfg = config.${namespace}.agent.mcp.mcps.codegraph;
in
{
  options.${namespace}.agent.mcp.mcps.codegraph.package = utils.mkPackOpt {
    default = pkgs.codegraph;
    description = "Codegraph MCP package; set a user-provided package to override the project default";
  };

  config = lib.mkIf server.enable {
    packages = [ cfg.package ];
  };
}
