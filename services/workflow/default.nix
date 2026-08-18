{
  config,
  namespace,
  ...
}:
let
  inherit (config.${namespace}) utils;
in
{
  options.${namespace}.workflow = {
    use = utils.mkEnumOpt {
      values = [
        "unset"
        "artifact-driven"
        "spec-driven"
      ];
      default = "unset";
      description = "Select the workflow to use for project";
    };
  };
}
