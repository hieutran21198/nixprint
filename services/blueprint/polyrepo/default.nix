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
  options.${namespace}.blueprint.polyrepo = {
    file = utils.mkFileEntry {
      default = { };
      description = "Polyrepo file entry";
    };

    build = {
      enabled = utils.mkBoolOpt {
        readOnly = true;
        default = config.${namespace}.blueprint.use == "polyrepo";
        description = "Enable polyrepo build";
      };
    };
  };

  config =
    let
      inherit (config.${namespace}.blueprint) polyrepo;
    in
    lib.mkIf polyrepo.build.enabled {
      ${namespace} = {
        blueprint.polyrepo = {
          # setup initial files
          file = {
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
            "docs" = {
              enable = true;
              description = "Documentation directory";
              entries = {
                "wiki" = {
                  enable = true;
                  description = "Centralized project knowledge";
                  entries = {
                    "governance" = {
                      enable = true;
                      description = "Project governance";
                      entries = {
                        "polyrepo.md" = {
                          enable = true;
                          src = {
                            path = ./assets/file/docs/wiki/governance/polyrepo.md;
                            copyMode = "seed";
                          };
                        };
                      };
                    };
                  };
                };
              };
            };
            "libs" = {
              enable = true;
              description = "Shared libraries";
              entries = {
                "README.md" = {
                  enable = true;
                  src = {
                    path = ./assets/file/libs/README.md;
                    copyMode = "seed";
                  };
                };
              };
            };
            "apps" = {
              enable = true;
              description = "Application directory";
              entries = {
                "README.md" = {
                  enable = true;
                  src = {
                    path = ./assets/file/apps/README.md;
                    copyMode = "seed";
                  };
                };
              };
            };
            "services" = {
              enable = true;
              description = "Service directory";
              entries = {
                "README.md" = {
                  enable = true;
                  src = {
                    path = ./assets/file/services/README.md;
                    copyMode = "seed";
                  };
                };
              };
            };
            "deployment" = {
              enable = true;
              description = "Deployment directory";
              entries = {
                "README.md" = {
                  enable = true;
                  src = {
                    path = ./assets/file/deployment/README.md;
                    copyMode = "seed";
                  };
                };
              };
            };
          };
        };

        # merge service configuration
        inherit (polyrepo) file;
      };
    };
}
