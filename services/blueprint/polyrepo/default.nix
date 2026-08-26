{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  hasGlob =
    value:
    lib.any (marker: lib.hasInfix marker value) [
      "*"
      "?"
      "["
      "]"
    ];
  relativePath =
    value:
    value != ""
    && value != "."
    && !(lib.hasPrefix "/" value)
    && !(lib.hasPrefix "~" value)
    && !(lib.elem ".." (lib.splitString "/" value));
  unique = values: builtins.length values == builtins.length (lib.unique values);
  leadingLiteralSegments =
    segments:
    if segments == [ ] || hasGlob (builtins.head segments) then
      [ ]
    else
      [ (builtins.head segments) ] ++ leadingLiteralSegments (builtins.tail segments);
  literalGlobPrefix =
    value: lib.concatStringsSep "/" (leadingLiteralSegments (lib.splitString "/" value));
  globContainedBy =
    paths: glob:
    let
      prefix = literalGlobPrefix glob;
    in
    prefix != "" && lib.any (path: prefix == path || lib.hasPrefix "${path}/" prefix) paths;
  implementationExpertModule = lib.types.submodule {
    options = {
      description = utils.mkStrOpt {
        description = "When the coordinator should use this implementation expert";
      };
      writePaths = utils.mkListOpt {
        ofType = lib.types.str;
        description = "Non-empty repository-relative files or directory roots that bound this implementation expert";
      };
      writeGlobs = utils.mkListOpt {
        ofType = lib.types.str;
        default = [ ];
        description = "Optional repository-relative edit patterns that narrow writePaths for supported clients";
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
      implementationAssertions = lib.flatten (
        lib.mapAttrsToList (name: expert: [
          {
            assertion = expert.writePaths != [ ];
            message = "workspace.blueprint.polyrepo.implementationExperts.${name} requires a non-empty writePaths list";
          }
          {
            assertion = unique expert.writePaths;
            message = "workspace.blueprint.polyrepo.implementationExperts.${name}.writePaths must not contain duplicates";
          }
          {
            assertion = lib.all (path: relativePath path && !hasGlob path) expert.writePaths;
            message = "workspace.blueprint.polyrepo.implementationExperts.${name}.writePaths must contain non-root, repository-relative paths without glob patterns or parent traversal";
          }
          {
            assertion = unique expert.writeGlobs;
            message = "workspace.blueprint.polyrepo.implementationExperts.${name}.writeGlobs must not contain duplicates";
          }
          {
            assertion = lib.all (glob: relativePath glob && hasGlob glob) expert.writeGlobs;
            message = "workspace.blueprint.polyrepo.implementationExperts.${name}.writeGlobs must contain repository-relative glob patterns without parent traversal";
          }
          {
            assertion = lib.all (glob: globContainedBy expert.writePaths glob) expert.writeGlobs;
            message = "workspace.blueprint.polyrepo.implementationExperts.${name}.writeGlobs must narrow a declared writePath";
          }
        ]) polyrepo.implementationExperts
      );
    in
    {
      assertions =
        lib.optional (polyrepo.implementationExperts != { }) {
          assertion = polyrepo.build.enabled;
          message = "workspace.blueprint.polyrepo.implementationExperts requires the Polyrepo blueprint";
        }
        ++ implementationAssertions;

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
