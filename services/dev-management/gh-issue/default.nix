{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (config.${namespace}) utils;
in
{
  options.${namespace}.dev-management.gh-issue = {
    build = {
      enabled = utils.mkBoolOpt {
        readOnly = true;
        default = config.${namespace}.dev-management.use == "gh-issue";
      };
    };
  };

  config =
    let
      opts = config.${namespace}.dev-management.gh-issue;
    in
    lib.mkIf opts.build.enabled {
      packages = with pkgs; [
        github-cli
      ];
    };
}
