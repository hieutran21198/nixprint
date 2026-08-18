{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
in
{
  options.${namespace}.workflow.artifact-driven = {
    file = utils.mkFileEntry {
      default = {
        "docs" = {
          enable = true;
          entries = {
            "README.md" = {
              enable = true;
              src = {
                path = ./assets/file/docs/README.md;
                copyMode = "seed";
              };
            };
          };
        };
      };
      description = "Artifact-driven workflow build file entry";
    };

    build = {
      enabled = utils.mkBoolOpt {
        readOnly = true;
        default = config.${namespace}.workflow.use == "artifact-driven";
      };
    };
  };

  config =
    let
      opts = config.${namespace}.workflow.artifact-driven;
    in
    lib.mkIf opts.build.enabled {
      ${namespace} = {
        inherit (opts) file;
      };
    };
}
