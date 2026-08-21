{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (config.${namespace}) utils;
in
{
  options.${namespace}.dev-management.linear = {
    build = {
      enabled = utils.mkBoolOpt {
        readOnly = true;
        default = config.${namespace}.dev-management.use == "linear";
      };
    };
  };

  config = { };
}
