{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.documentation;
in
{
  options.${namespace}.documentation = {
    model = utils.mkEnumOpt {
      values = [
        "unset"
        "artifact-driven"
      ];
      default = "unset";
      description = "Select the centralized documentation model";
    };
    file = utils.mkFileEntry {
      default = { };
      description = "Centralized documentation file entry";
    };
    build.enabled = utils.mkBoolOpt {
      readOnly = true;
      default = cfg.model != "unset";
      description = "Enable the centralized documentation build";
    };
  };

  config = lib.mkIf cfg.build.enabled {
    ${namespace}.file = cfg.file;
  };
}
