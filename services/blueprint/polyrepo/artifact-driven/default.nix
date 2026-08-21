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
            "templates" = {
              enable = true;
              src = {
                path = ./assets/file/docs/templates;
                copyMode = "copy";
              };
            };
            "wiki" = {
              entries = {
                "README.md" = {
                  enable = true;
                  src.path = lib.mkForce ./assets/file/docs/wiki/README.md;
                };
                "governance".entries = {
                  "artifact-driven" = {
                    enable = true;
                    src = {
                      path = ./assets/file/docs/wiki/governance/artifact-driven;
                      copyMode = "seed";
                    };
                  };
                };
              };
            };
            "glossary" = {
              enable = true;
              entries = {
                "README.md" = {
                  enable = true;
                  src.path = lib.mkForce ./assets/file/docs/glossary/README.md;
                };
                "entries" = {
                  enable = true;
                  entries = { };
                };
              };
            };
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
