{
  config,
  namespace,
  lib,
  ...
}:
let
  pkgs = config._module.args.pkgs;
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.agent.mcp.builtinServers.context7;
in
{
  options.${namespace}.agent.mcp.builtinServers.context7 = {
    enable = utils.mkBoolOpt {
      default = false;
      description = "Enable the built-in Context7 MCP server";
    };
    package = utils.mkPackOpt {
      default = pkgs.context7-mcp;
      description = "Context7 MCP package; set a user-provided package to override the project default";
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [ cfg.package ];
    ${namespace}.agent.mcp.servers.context7 = {
      enable = lib.mkDefault true;
      command = lib.mkDefault [ "context7-mcp" ];
      environment.CONTEXT7_API_KEY.secret = lib.mkDefault "CONTEXT7_API_KEY";
    };
  };
}
