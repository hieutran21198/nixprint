{
  lib,
  namespace,
  config,
  ...
}:
let
  inherit (config.${namespace}) utils;
in
{
  options.${namespace}.blueprint.polyrepo.artifact-driven = {
    build = {
      enabled = utils.mkBoolOpt {
        readOnly = true;
        default =
          config.${namespace}.blueprint.use == "polyrepo"
          && config.${namespace}.blueprint.polyrepo.workflow == "artifact-driven";
      };
    };
  };

  config =
    let
      opts = config.${namespace}.blueprint.polyrepo.artifact-driven;
    in
    lib.mkIf opts.build.enabled {
      ${namespace}.blueprint.polyrepo = {
        file = {
          "docs".entries = {
            "README.md" = {
              # patch README.md file.
              src.path = lib.mkForce ./assets/file/docs/README.md;
            };
          };
          ".".entries = {
            "AGENTS.md" = {
              src.path = lib.mkForce ./assets/file/AGENTS.md;
            };
          };
        };
      };
    };
}
