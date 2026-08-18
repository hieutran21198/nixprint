{
  config,
  namespace,
  ...
}:
let
  inherit (config.${namespace}) utils;
in
{
  options.${namespace}.blueprint = {
    use = utils.mkEnumOpt {
      values = [
        "unset"
        "polyrepo"
      ];
      default = "unset";
      description = "Select the blueprint to use for project";
    };
  };
}
