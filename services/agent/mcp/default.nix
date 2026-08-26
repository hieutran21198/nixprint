{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  cfg = config.${namespace}.agent.mcp;
  harness = config.${namespace}.agent.harness;

  environmentValue = lib.types.either lib.types.str (
    lib.types.submodule {
      options.secret = utils.mkStrOpt {
        description = "SecretSpec environment variable name";
      };
    }
  );

  isSecret = value: builtins.isAttrs value && value ? secret;
  literalEnvironment = environment: lib.filterAttrs (_: value: !isSecret value) environment;
  secretEnvironmentNames =
    environment:
    lib.mapAttrsToList (_: value: value.secret) (
      lib.filterAttrs (_: value: isSecret value) environment
    );
  requiredSecrets = lib.unique (
    lib.concatMap (server: secretEnvironmentNames server.environment) (builtins.attrValues cfg.servers)
  );
  claudeSecretReference =
    secret:
    builtins.concatStringsSep "" [
      "\${"
      secret
      "}"
    ];

  codexServer =
    _: server:
    {
      command = builtins.head server.command;
      args = lib.tail server.command;
    }
    // lib.optionalAttrs (server.cwd != null) { cwd = toString server.cwd; }
    // lib.optionalAttrs (literalEnvironment server.environment != { }) {
      env = literalEnvironment server.environment;
    }
    // lib.optionalAttrs (secretEnvironmentNames server.environment != [ ]) {
      env_vars = secretEnvironmentNames server.environment;
    };

  claudeServer =
    _: server:
    {
      command = builtins.head server.command;
      args = lib.tail server.command;
    }
    // lib.optionalAttrs (server.cwd != null) { cwd = toString server.cwd; }
    // lib.optionalAttrs (server.environment != { }) {
      env = lib.mapAttrs (
        _: value: if isSecret value then claudeSecretReference value.secret else value
      ) server.environment;
    };

  opencodeServer =
    _: server:
    {
      type = "local";
      command = server.command;
      enabled = true;
    }
    // lib.optionalAttrs (server.cwd != null) { cwd = toString server.cwd; }
    // lib.optionalAttrs (server.environment != { }) {
      environment = lib.mapAttrs (
        _: value: if isSecret value then "{env:${value.secret}}" else value
      ) server.environment;
    };
in
{
  options.${namespace}.agent.mcp = {
    servers = utils.mkAttrsOpt {
      ofType = lib.types.submodule {
        options = {
          command = utils.mkListOpt {
            ofType = lib.types.str;
            default = [ ];
            description = "Local MCP stdio command, including arguments";
          };
          cwd = utils.mkPathOpt {
            nullable = true;
            default = null;
            description = "Optional MCP process working directory";
          };
          environment = utils.mkAttrsOpt {
            ofType = environmentValue;
            default = { };
            description = "MCP environment values or SecretSpec environment-variable references";
          };
        };
      };
      default = { };
      description = "Agent-neutral local MCP server definitions";
    };
  };

  config = lib.mkIf harness.build.enabled {
    assertions =
      lib.mapAttrsToList (name: server: {
        assertion = server.command != [ ];
        message = "workspace.agent.mcp.servers.${name}.command is required";
      }) cfg.servers
      ++ lib.optional (requiredSecrets != [ ]) {
        assertion = config.secretspec.enable;
        message = "workspace.agent.mcp requires Devenv SecretSpec for declared secret environment variables";
      }
      ++ lib.map (secret: {
        assertion = builtins.hasAttr secret config.secretspec.secrets;
        message = "workspace.agent.mcp requires SecretSpec secret '${secret}'";
      }) requiredSecrets;

    env = lib.mkIf config.secretspec.enable (
      lib.genAttrs requiredSecrets (secret: config.secretspec.secrets.${secret} or "")
    );

    ${namespace}.agent.harness.build = {
      codex.mcp = lib.mkIf harness.clients.codex.enable (lib.mapAttrs codexServer cfg.servers);
      claude.mcp = lib.mkIf harness.clients.claude.enable (lib.mapAttrs claudeServer cfg.servers);
      opencode.mcp = lib.mkIf harness.clients.opencode.enable (lib.mapAttrs opencodeServer cfg.servers);
    };
  };
}
