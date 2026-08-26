{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  implementationExpertModule = lib.types.submodule {
    options = {
      description = utils.mkStrOpt {
        description = "When the coordinator should use this implementation expert";
      };
      repository = utils.mkStrOpt {
        default = "";
        description = "Repository that bounds this implementation expert";
      };
      implementationArea = utils.mkStrOpt {
        default = "";
        description = "Other bounded implementation area for this expert";
      };
      persistentInstructions = utils.mkStrOpt {
        description = "Persistent implementation instructions for this expert";
      };
      defaultSkills = utils.mkListOpt {
        ofType = lib.types.str;
        default = [ ];
        description = "Portable workflow skill preferences for this implementation expert";
      };
    };
  };
in
{
  options.${namespace}.blueprint.polyrepo = {
    implementationExperts = utils.mkAttrsOpt {
      ofType = implementationExpertModule;
      default = { };
      description = "Configured Polyrepo implementation experts";
    };

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
      rootGuidanceEnabled = config.${namespace}.documentation.model != "artifact-driven";
      bounded = expert: expert.repository != "" || expert.implementationArea != "";
      boundedAssertions = lib.mapAttrsToList (name: expert: {
        assertion = bounded expert;
        message = "workspace.blueprint.polyrepo.implementationExperts.${name} requires repository or implementationArea";
      }) polyrepo.implementationExperts;
    in
    {
      assertions =
        lib.optional (polyrepo.implementationExperts != { }) {
          assertion = polyrepo.build.enabled;
          message = "workspace.blueprint.polyrepo.implementationExperts requires the Polyrepo blueprint";
        }
        ++ boundedAssertions;

      ${namespace} = lib.mkIf polyrepo.build.enabled {
        blueprint.polyrepo = {
          # setup initial files
          file =
            (lib.optionalAttrs rootGuidanceEnabled {
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
            })
            // {
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
