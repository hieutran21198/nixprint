{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.documentation.artifact-driven;
in
{
  options.${namespace}.documentation.artifact-driven.build.enabled = utils.mkBoolOpt {
    readOnly = true;
    default = config.${namespace}.documentation.model == "artifact-driven";
    description = "Enable the artifact-driven documentation model";
  };

  config = lib.mkIf cfg.build.enabled {
    ${namespace}.documentation.file = {
      "docs" = {
        enable = true;
        description = "Documentation directory";
        entries = {
          "README.md" = {
            enable = true;
            src = {
              path = ./assets/file/docs/README.md;
              copyMode = "seed";
            };
          };
          "wiki" = {
            enable = true;
            description = "Centralized project knowledge";
            entries = {
              "README.md" = {
                enable = true;
                src = {
                  path = ./assets/file/docs/wiki/README.md;
                  copyMode = "seed";
                };
              };
              "governance" = {
                enable = true;
                description = "Project governance";
                entries = {
                  "documentation" = {
                    enable = true;
                    description = "Documentation governance models";
                    entries = {
                      "README.md" = {
                        enable = true;
                        src = {
                          path = ./assets/file/docs/wiki/governance/documentation/README.md;
                          copyMode = "seed";
                        };
                      };
                      "artifact-driven" = {
                        enable = true;
                        description = "Artifact-driven documentation governance";
                        entries = {
                          "README.md" = {
                            enable = true;
                            src = {
                              path = ./assets/file/docs/wiki/governance/documentation/artifact-driven/README.md;
                              copyMode = "seed";
                            };
                          };
                          "delivery-workflow.md" = {
                            enable = true;
                            src = {
                              path = ./assets/file/docs/wiki/governance/documentation/artifact-driven/delivery-workflow.md;
                              copyMode = "seed";
                            };
                          };
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
