{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  agentHarnessOptions = import ../agent/harness/options.nix { inherit lib utils; };
  deliveryWorkflowOptions = import ../delivery-workflow/options.nix { inherit lib utils; };
in
{
  options.${namespace}.composition = {
    use = utils.mkEnumOpt {
      values = [
        "unset"
        "artifact-polyrepo-workspace"
      ];
      default = "unset";
      description = "Select a concrete workspace composition profile";
    };

    agent = lib.mkOption {
      type = agentHarnessOptions.configurationType;
      default = { };
      description = "Agent Harness settings owned by the selected composition profile";
    };

    deliveryWorkflow = lib.mkOption {
      type = deliveryWorkflowOptions.configurationType;
      default = { };
      description = "Delivery Workflow settings owned by the selected composition profile";
    };
  };
}
