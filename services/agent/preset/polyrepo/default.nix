{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.agent.expert.polyrepo;
  harness = config.${namespace}.agent.harness;
  polyrepoEnabled = config.${namespace}.blueprint.polyrepo.build.enabled;
  active = harness.build.enabled && polyrepoEnabled;

  implementationExpert = _: expert: {
    inherit (expert) description persistentInstructions defaultSkills;
  };

  bounded = expert: expert.repository != "" || expert.implementationArea != "";
  boundedAssertions = lib.mapAttrsToList (name: expert: {
    assertion = bounded expert;
    message = "workspace.agent.expert.polyrepo.implementationExperts.${name} requires repository or implementationArea";
  }) cfg.implementationExperts;
in
{
  options.${namespace}.agent.expert.polyrepo.implementationExperts = utils.mkAttrsOpt {
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

  config = {
    assertions =
      lib.optional (cfg.implementationExperts != { }) {
        assertion = polyrepoEnabled;
        message = "workspace.agent.expert.polyrepo.implementationExperts requires the Polyrepo blueprint";
      }
      ++ boundedAssertions;

    ${namespace}.agent.expert.experts = lib.mkIf active (
      lib.mapAttrs implementationExpert cfg.implementationExperts
    );
  };
}
