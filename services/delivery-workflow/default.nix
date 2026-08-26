{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.delivery-workflow;
  deliveryWorkflowOptions = import ./options.nix { inherit lib utils; };

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
  options.${namespace}.delivery-workflow = deliveryWorkflowOptions.configurationOptions // {
    build.enabled = utils.mkBoolOpt {
      readOnly = true;
      default = cfg.enable;
      description = "Enable delivery-workflow file generation";
    };
  };

  config = {
    assertions = lib.optionals cfg.build.enabled [
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
