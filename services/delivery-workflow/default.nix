{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.delivery-workflow;

  stateModule = lib.types.submodule {
    options = {
      id = utils.mkStrOpt {
        default = "";
        description = "GitHub Project single-select option ID";
      };
      name = utils.mkStrOpt {
        default = "";
        description = "GitHub Project single-select option name";
      };
      sources = utils.mkListOpt {
        ofType = lib.types.str;
        default = [ ];
        description = "Project option IDs that can transition to this state";
      };
    };
  };

  stateConfiguration = state: {
    inherit (state) id name sources;
  };

  workflowSource =
    path:
    builtins.replaceStrings [ "cirius/delivery-workflow@v1" ] [ cfg.action.ref ] (
      builtins.readFile path
    );
in
{
  options.${namespace}.delivery-workflow = {
    enable = utils.mkBoolOpt {
      default = false;
      description = "Enable the GitHub delivery-workflow integration";
    };

    github = {
      repository = utils.mkStrOpt {
        default = "";
        description = "GitHub repository in owner/repository form";
      };
      project = {
        owner = utils.mkStrOpt {
          default = "";
          description = "GitHub user or organization that owns the Project";
        };
        ownerType = utils.mkEnumOpt {
          values = [
            "organization"
            "user"
          ];
          default = "organization";
          description = "GitHub Project owner type";
        };
        number = utils.mkIntOpt {
          default = 0;
          description = "GitHub Project number";
        };
        id = utils.mkStrOpt {
          default = "";
          description = "GitHub Project node ID";
        };
        statusField = utils.mkStrOpt {
          default = "Status";
          description = "GitHub Project single-select status field name";
        };
        statusFieldId = utils.mkStrOpt {
          default = "";
          description = "GitHub Project single-select status field ID";
        };
      };
    };

    acceptanceBranch = utils.mkStrOpt {
      default = "main";
      description = "Protected branch that accepts delivery-workflow pull requests";
    };

    authorizerTeams = utils.mkListOpt {
      ofType = lib.types.str;
      default = [ ];
      description = "GitHub teams that can explicitly reject phases 1-3";
    };

    authorizerUsers = utils.mkListOpt {
      ofType = lib.types.str;
      default = [ ];
      description = "GitHub users that can explicitly reject phases 1-3";
    };

    states = {
      draft = lib.mkOption {
        type = stateModule;
        default = { };
        description = "Configured Draft workflow semantic";
      };
      ready = lib.mkOption {
        type = stateModule;
        default = { };
        description = "Configured Ready workflow semantic";
      };
      inProgress = lib.mkOption {
        type = stateModule;
        default = { };
        description = "Configured In Progress workflow semantic";
      };
      archived = lib.mkOption {
        type = stateModule;
        default = { };
        description = "Configured Archived workflow semantic";
      };
      implementationAccepted = lib.mkOption {
        type = stateModule;
        default = { };
        description = "Configured implementation-acceptance workflow semantic";
      };
    };

    action.ref = utils.mkStrOpt {
      default = "cirius/delivery-workflow@v1";
      description = "Pinned GitHub Action reference for the dw command";
    };

    build.enabled = utils.mkBoolOpt {
      readOnly = true;
      default = cfg.enable;
      description = "Enable delivery-workflow file generation";
    };
  };

  config = {
    assertions =
      lib.optional cfg.enable {
        assertion = config.${namespace}.documentation.model == "artifact-driven";
        message = "workspace.delivery-workflow.enable requires workspace.documentation.model = \"artifact-driven\"";
      }
      ++ lib.optionals cfg.build.enabled [
        {
          assertion = cfg.github.repository != "";
          message = "workspace.delivery-workflow.github.repository is required";
        }
        {
          assertion = cfg.github.project.owner != "" && cfg.github.project.number > 0;
          message = "workspace.delivery-workflow.github.project.owner and number are required";
        }
        {
          assertion = cfg.github.project.id != "" && cfg.github.project.statusFieldId != "";
          message = "workspace.delivery-workflow.github.project.id and statusFieldId are required";
        }
        {
          assertion = cfg.authorizerTeams != [ ] || cfg.authorizerUsers != [ ];
          message = "workspace.delivery-workflow requires an authorizer team or user";
        }
        {
          assertion = cfg.github.project.ownerType != "user" || cfg.authorizerUsers != [ ];
          message = "a user-owned Project requires workspace.delivery-workflow.authorizerUsers";
        }
        {
          assertion = lib.all (state: state.id != "" && state.sources != [ ]) [
            cfg.states.draft
            cfg.states.ready
            cfg.states.inProgress
            cfg.states.archived
            cfg.states.implementationAccepted
          ];
          message = "workspace.delivery-workflow.states must define an ID and sources for every semantic";
        }
      ];

    ${namespace}.file = lib.mkIf cfg.build.enabled {
      ".dw" = {
        enable = true;
        entries = {
          "config.yaml" = {
            enable = true;
            src = {
              yaml = {
                version = 1;
                github = {
                  inherit (cfg.github) repository;
                  project = {
                    inherit (cfg.github.project) owner number id;
                    owner_type = cfg.github.project.ownerType;
                    status_field = cfg.github.project.statusField;
                    status_field_id = cfg.github.project.statusFieldId;
                  };
                };
                acceptance_branch = cfg.acceptanceBranch;
                authorizer_teams = cfg.authorizerTeams;
                authorizer_users = cfg.authorizerUsers;
                states = {
                  draft = stateConfiguration cfg.states.draft;
                  ready = stateConfiguration cfg.states.ready;
                  in_progress = stateConfiguration cfg.states.inProgress;
                  archived = stateConfiguration cfg.states.archived;
                  implementation_accepted = stateConfiguration cfg.states.implementationAccepted;
                };
              };
              copyMode = "seed";
            };
          };
        };
      };
      ".github" = {
        enable = true;
        entries = {
          "workflows" = {
            enable = true;
            entries = {
              "dw-validate.yml" = {
                enable = true;
                src = {
                  text = workflowSource ./examples/github/.github/workflows/dw-validate.yml;
                  copyMode = "seed";
                };
              };
              "dw-transition.yml" = {
                enable = true;
                src = {
                  text = workflowSource ./examples/github/.github/workflows/dw-transition.yml;
                  copyMode = "seed";
                };
              };
              "dw-reconcile.yml" = {
                enable = true;
                src = {
                  text = workflowSource ./examples/github/.github/workflows/dw-reconcile.yml;
                  copyMode = "seed";
                };
              };
            };
          };
        };
      };
    };
  };
}
