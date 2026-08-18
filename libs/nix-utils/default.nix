{
  namespace,
  lib,
  ...
}:
{
  options.${namespace} = {
    utils = lib.mkOption {
      type = with lib.types; attrsOf anything;
      description = "Utilities for ${namespace}";
    };
  };
}
