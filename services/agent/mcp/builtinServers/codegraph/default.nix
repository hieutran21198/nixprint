{
  config,
  namespace,
  lib,
  ...
}:
let
  pkgs = config._module.args.pkgs;
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.agent.mcp.builtinServers.codegraph;
in
{
  options.${namespace}.agent.mcp.builtinServers.codegraph = {
    enable = utils.mkBoolOpt {
      default = false;
      description = "Enable the built-in Codegraph MCP server";
    };
    package = utils.mkPackOpt {
      default = pkgs.codegraph;
      description = "Codegraph MCP package; set a user-provided package to override the project default";
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [ cfg.package ];
    ${namespace}.agent.mcp.servers.codegraph = {
      enable = lib.mkDefault true;
      command = lib.mkDefault [
        "codegraph"
        "serve"
        "--mcp"
      ];
      cwd = lib.mkDefault config.git.root;
    };
  };
}
