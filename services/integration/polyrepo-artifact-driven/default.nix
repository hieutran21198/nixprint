{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.integration.polyrepo-artifact-driven;
in
{
  options.${namespace}.integration.polyrepo-artifact-driven.build.enabled = utils.mkBoolOpt {
    readOnly = true;
    default =
      config.${namespace}.blueprint.use == "polyrepo"
      && config.${namespace}.documentation.model == "artifact-driven";
    description = "Enable Polyrepo and Artifact-Driven Documentation integration";
  };

  config = lib.mkIf cfg.build.enabled {
    ${namespace}.file = {
      "." = {
        enable = true;
        entries = {
          "AGENTS.md" = {
            enable = true;
            src = {
              path = ./assets/file/AGENTS.md;
              copyMode = "seed";
            };
          };
          "README.md" = {
            enable = true;
            src = {
              path = ./assets/file/README.md;
              copyMode = "seed";
            };
          };
        };
      };
    };
  };
}
