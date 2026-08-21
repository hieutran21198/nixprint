{
  config,
  namespace,
  ...
}:
let
  inherit (config.${namespace}) utils;
in
{
  options.${namespace}.dev-management = {
    use = utils.mkEnumOpt {
      values = [
        "unset"
        "gh-issue"
        "linear"
      ];
      default = "unset";
      description = "Development management tool to use for project";
    };
  };
}
