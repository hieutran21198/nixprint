{ lib, utils }:
let
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

  configurationOptions = {
    enable = utils.mkBoolOpt {
      default = false;
      description = "Enable the GitHub delivery-workflow integration";
    };

    install = utils.mkBoolOpt {
      default = false;
      description = "Install the dw command without generating delivery-workflow files";
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
      classification = {
        requirement = utils.mkStrOpt {
          default = "Requirement";
          description = "Active Requirement label or Issue Type";
        };
        specification = utils.mkStrOpt {
          default = "Specification";
          description = "Active Specification label or Issue Type";
        };
        decision = utils.mkStrOpt {
          default = "Decision";
          description = "Active Decision label or Issue Type";
        };
        task = utils.mkStrOpt {
          default = "Task";
          description = "Active Task label or Issue Type";
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
      accepted = lib.mkOption {
        type = stateModule;
        default = { };
        description = "Configured Accepted workflow semantic";
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

    phase4.autoTransition = utils.mkBoolOpt {
      default = true;
      description = "Automatically accept implementation tickets after merge";
    };

    action.ref = utils.mkStrOpt {
      default = "cirius/delivery-workflow@v1";
      description = "Pinned GitHub Action reference for the dw command";
    };
  };
in
{
  inherit configurationOptions;
  configurationType = lib.types.submodule { options = configurationOptions; };
}
