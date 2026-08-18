{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.git;
in
{
  options.${namespace}.git = {
    hooks = {
      enable = utils.mkBoolOpt {
        default = true;
        description = "Enable prek-managed Git pre-commit hooks through devenv's git-hooks integration.";
      };
    };

    build = {
      rootDir = utils.mkPathOpt {
        readOnly = true;
        default = config.git.root;
        description = "The root directory of the git repository.";
      };
    };
  };

  config = lib.mkIf cfg.hooks.enable {
    git-hooks = {
      enable = true;
      hooks = {
        check-added-large-files.enable = lib.mkDefault true;
        check-json.enable = lib.mkDefault true;
        check-merge-conflicts.enable = lib.mkDefault true;
        check-toml.enable = lib.mkDefault true;
        check-yaml.enable = lib.mkDefault true;
        detect-aws-credentials.enable = lib.mkDefault true;
        detect-private-keys.enable = lib.mkDefault true;
        end-of-file-fixer.enable = lib.mkDefault true;
        markdownlint = {
          enable = lib.mkDefault true;
          settings.configuration = lib.mkDefault {
            MD013 = false; # Line length is project-specific.
            MD033 = false; # Permit inline HTML when Markdown needs it.
          };
        };
        nixfmt-rfc-style.enable = lib.mkDefault true;
        trim-trailing-whitespace.enable = lib.mkDefault true;
      };
    };
  };
}
