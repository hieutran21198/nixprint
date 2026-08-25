{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.integration.polyrepo-agent;
  harness = config.${namespace}.agent.harness;
  polyrepoEnabled = config.${namespace}.blueprint.polyrepo.build.enabled;

  implementationExpert = _: expert: {
    inherit (expert) description persistentInstructions defaultSkills;
  };

  bounded = expert: expert.repository != "" || expert.implementationArea != "";
  boundedAssertions = lib.mapAttrsToList (name: expert: {
    assertion = bounded expert;
    message = "workspace.integration.polyrepo-agent.implementationExperts.${name} requires repository or implementationArea";
  }) cfg.implementationExperts;
in
{
  options.${namespace}.integration.polyrepo-agent = {
    implementationExperts = utils.mkAttrsOpt {
      ofType = lib.types.submodule {
        options = {
          description = utils.mkStrOpt {
            description = "When the coordinator should use this implementation expert";
          };
          repository = utils.mkStrOpt {
            default = "";
            description = "Repository that bounds this implementation expert";
          };
          implementationArea = utils.mkStrOpt {
            default = "";
            description = "Other bounded implementation area for this expert";
          };
          persistentInstructions = utils.mkStrOpt {
            description = "Persistent implementation instructions for this expert";
          };
          defaultSkills = utils.mkListOpt {
            ofType = lib.types.str;
            default = [ ];
            description = "Portable workflow skill preferences for this implementation expert";
          };
        };
      };
      default = { };
      description = "Configured Polyrepo implementation experts";
    };

    build.enabled = utils.mkBoolOpt {
      readOnly = true;
      default = harness.build.enabled && polyrepoEnabled;
      description = "Enable Polyrepo and agent integration";
    };
  };

  config = {
    assertions =
      lib.optional (cfg.implementationExperts != { }) {
        assertion = polyrepoEnabled;
        message = "workspace.integration.polyrepo-agent.implementationExperts requires the Polyrepo blueprint";
      }
      ++ boundedAssertions;

    ${namespace}.agent.expert.experts = lib.mkIf cfg.build.enabled (
      lib.mapAttrs implementationExpert cfg.implementationExperts
    );
  };
}
