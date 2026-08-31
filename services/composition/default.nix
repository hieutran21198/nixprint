{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  agentHarnessOptions = import ../agent/harness/options.nix { inherit lib utils; };
  deliveryWorkflowOptions = import ../delivery-workflow/options.nix { inherit lib utils; };
  cfg = config.${namespace}.composition;
  harness = config.${namespace}.agent.harness;
  polyrepo = config.${namespace}.blueprint.polyrepo;

  printText = text: "printf '%s\\n' ${lib.escapeShellArg text}";
  printList =
    values:
    if values == [ ] then [ (printText "- None.") ] else map (value: printText "- ${value}") values;
  expertDetail =
    label: values:
    if values == [ ] then
      [ (printText "  ${label}: none") ]
    else
      [ (printText "  ${label}:") ] ++ map (value: printText "    - ${value}") values;
  moduleRow =
    name: state: "printf '| %-29s | %-8s |\\n' ${lib.escapeShellArg name} ${lib.escapeShellArg state}";
  state = value: if value then "ENABLED" else "DISABLED";
  enabledClients = map (client: client.name) (
    lib.filter (client: client.enable) [
      {
        name = "codex";
        enable = harness.clients.codex.enable;
      }
      {
        name = "claude";
        enable = harness.clients.claude.enable;
      }
      {
        name = "opencode";
        enable = harness.clients.opencode.enable;
      }
    ]
  );
  expertCatalog = harness.build.experts;
  profileExperts = lib.optionals (cfg.use == "artifact-polyrepo-workspace") (
    lib.filter (record: record.expert != null) [
      {
        id = "scope-expert";
        role = "documentation scope";
        source = "profile";
        expert = lib.attrByPath [ "scope-expert" ] null expertCatalog;
      }
      {
        id = "technical-expert";
        role = "technical review";
        source = "profile";
        expert = lib.attrByPath [ "technical-expert" ] null expertCatalog;
      }
    ]
  );
  implementationExperts =
    map
      (id: {
        inherit id;
        role = "implementation";
        source = "polyrepo implementation";
        expert = expertCatalog.${id};
      })
      (
        lib.filter (id: builtins.hasAttr id expertCatalog) (
          lib.sort builtins.lessThan (builtins.attrNames polyrepo.implementationExperts)
        )
      );
  expertLines =
    record:
    [
      (printText "- ID: ${record.id}")
      (printText "  Role: ${record.role}")
      (printText "  Source: ${record.source}")
    ]
    ++ expertDetail "Clients" enabledClients
    ++ expertDetail "Skills" record.expert.defaultSkills
    ++ expertDetail "Write paths" record.expert.writePaths
    ++ expertDetail "Write globs" record.expert.writeGlobs;
  allAssertionsPass = lib.all (entry: entry.assertion) config.assertions;
  doctorScript = lib.concatStringsSep "\n" (
    [
      (printText "ARTIFACT-POLYREPO COMPOSITION DOCTOR")
      (printText "Configuration: ${if allAssertionsPass then "VALID" else "INVALID"}")
      ""
      (printText "Profile: ${cfg.use}")
      ""
      (printText "MODULES")
      (printText "+-------------------------------+----------+")
      (moduleRow "Module" "State")
      (printText "+-------------------------------+----------+")
      (moduleRow "Artifact-Driven Documentation" (
        state config.${namespace}.documentation.artifact-driven.build.enabled
      ))
      (moduleRow "Polyrepo blueprint" (state polyrepo.build.enabled))
      (moduleRow "Agent Harness" (state harness.build.enabled))
      (moduleRow "Delivery Workflow" (state config.${namespace}.delivery-workflow.build.enabled))
      (printText "+-------------------------------+----------+")
      ""
      (printText "AGENT CLIENTS")
    ]
    ++ (
      if harness.build.enabled then
        printList enabledClients
      else
        [ (printText "- None. Agent Harness is disabled.") ]
    )
    ++ [
      ""
      (printText "CHECKS")
    ]
    ++ map (
      entry: printText "[${if entry.assertion then "PASS" else "FAIL"}] ${entry.message}"
    ) config.assertions
    ++ [
      ""
      (printText "WARNINGS")
    ]
    ++ printList config.warnings
    ++ [
      ""
      (printText "EXPERTS")
    ]
    ++ (
      if !harness.build.enabled then
        [ (printText "- No experts matrix is available.") ]
      else if profileExperts ++ implementationExperts == [ ] then
        [ (printText "- None.") ]
      else
        lib.concatMap expertLines (profileExperts ++ implementationExperts)
    )
    ++ [
      ""
      (printText "RESULT: ${if allAssertionsPass then "VALID" else "INVALID"}")
      "exit ${if allAssertionsPass then "0" else "1"}"
    ]
  );
in
{
  options.${namespace}.composition = {
    use = utils.mkEnumOpt {
      values = [
        "unset"
        "artifact-polyrepo-workspace"
      ];
      default = "unset";
      description = "Select a concrete workspace composition profile";
    };

    agent = lib.mkOption {
      type = agentHarnessOptions.configurationType;
      default = { };
      description = "Agent Harness settings owned by the selected composition profile";
    };

    deliveryWorkflow = lib.mkOption {
      type = deliveryWorkflowOptions.configurationType;
      default = { };
      description = "Delivery Workflow settings owned by the selected composition profile";
    };
  };

  config.scripts.workspace-composition-doctor.exec = doctorScript;
}
