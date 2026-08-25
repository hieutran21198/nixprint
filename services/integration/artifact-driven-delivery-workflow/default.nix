{
  config,
  namespace,
  ...
}:
{
  options.${namespace}.integration.artifact-driven-delivery-workflow.build.enabled =
    config.${namespace}.utils.mkBoolOpt
      {
        readOnly = true;
        default =
          config.${namespace}.documentation.model == "artifact-driven"
          && config.${namespace}.delivery-workflow.build.enabled;
        description = "Enable Artifact-Driven Documentation and Delivery Workflow integration";
      };
}
