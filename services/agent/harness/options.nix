{ lib, utils }:
let
  clientModule = lib.types.submodule {
    options.enable = utils.mkBoolOpt {
      default = false;
      description = "Enable this AI-agent client for the project";
    };
  };

  configurationOptions = {
    enable = utils.mkBoolOpt {
      default = false;
      description = "Enable project AI-agent harness configuration";
    };

    clients = {
      codex = lib.mkOption {
        type = clientModule;
        default = { };
        description = "Codex project client configuration";
      };
      claude = lib.mkOption {
        type = clientModule;
        default = { };
        description = "Claude Code project client configuration";
      };
      opencode = lib.mkOption {
        type = clientModule;
        default = { };
        description = "OpenCode project client configuration";
      };
    };
  };
in
{
  inherit configurationOptions;
  configurationType = lib.types.submodule { options = configurationOptions; };
}
