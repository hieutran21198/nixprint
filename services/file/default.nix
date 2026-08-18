{
  config,
  namespace,
  lib,
  ...
}:
let
  inherit (config.${namespace}) utils;
  entryModule = lib.types.submodule (
    { name, config, ... }: {
      options = {
        enable = utils.mkBoolOpt {
          description = "Enable the folder module";
          default = false;
        };
        description = utils.mkStrOpt {
          nullable = true;
          default = null;
          description = "Folder/file module description";
        };

        src = {
          path = utils.mkPathOpt {
            nullable = true;
            default = null;
            description = "Source file path";
          };
          json = utils.mkAnyOpt {
            nullable = true;
            default = null;
            description = "Source JSON object";
          };
          yaml = utils.mkAnyOpt {
            nullable = true;
            default = null;
            description = "Source YAML object";
          };
          toml = utils.mkAnyOpt {
            nullable = true;
            default = null;
            description = "Source TOML object";
          };
          ini = utils.mkAnyOpt {
            nullable = true;
            default = null;
            description = "Source INI object";
          };
          text = utils.mkStrOpt {
            nullable = true;
            default = null;
            description = "Source text content";
          };

          copyMode = utils.mkEnumOpt {
            values = [
              "seed"
              "copy"
              "symlink"
            ];
            default = "copy";
          };
        };

        # if entry module has null entries then it is file.
        # else it is folder.
        entries = utils.mkAttrsOpt {
          ofType = entryModule;
          nullable = true;
          default = null;
          description = "Folder/file module entries";
        };

        # built module output
        build = {
          type = utils.mkEnumOpt {
            values = [
              "folder"
              "file"
              "no-output"
            ];
            readOnly = true;
          };
          files = utils.mkAttrsOpt {
            readOnly = true;
            description = "Files to be created relative to this entry";
            ofType = lib.types.anything;
          };
        };
      };
      config =
        let
          subConfig = config;
          sourceFields = {
            path = subConfig.src.path;
            json = subConfig.src.json;
            yaml = subConfig.src.yaml;
            toml = subConfig.src.toml;
            ini = subConfig.src.ini;
            text = subConfig.src.text;
          };
          devenvSourceFields = lib.filterAttrs (_: value: value != null) {
            source = sourceFields.path;
            inherit (sourceFields)
              json
              yaml
              toml
              ini
              text
              ;
          };
          prefixFiles =
            prefix: lib.mapAttrs' (fileName: file: lib.nameValuePair "${prefix}/${fileName}" file);
        in
        {
          build.type =
            if !subConfig.enable then
              "no-output"
            else if subConfig.entries != null then
              "folder"
            else if devenvSourceFields != { } then
              "file"
            else
              "no-output";

          build.files =
            if !subConfig.enable then
              { }
            else
              assert lib.assertMsg (name != "") "Entry name needs to be specified";
              assert lib.assertMsg (
                subConfig.entries == null || lib.all (source: source == null) (builtins.attrValues sourceFields)
              ) "Folder entry '${name}' cannot define source content";
              if subConfig.entries != null then
                lib.mkMerge (
                  lib.mapAttrsToList (childName: child: prefixFiles name child.build.files) subConfig.entries
                )
              else if devenvSourceFields != { } then
                {
                  "${name}" = devenvSourceFields // {
                    copyMode = subConfig.src.copyMode;
                  };
                }
              else
                { };
        };
    }
  );
in
{
  options.${namespace}.file = utils.mkAttrsOpt {
    ofType = entryModule;
    default = { };
    description = "Folder/file module entries";
  };
  config = {
    # register utilities
    ${namespace}.utils = {
      mkFileEntry =
        {
          default ? { },
          description ? "",
          ...
        }:
        utils.mkAttrsOpt {
          ofType = entryModule;
          inherit default description;
        };
    };

    files = lib.mkMerge (lib.mapAttrsToList (_: entry: entry.build.files) config.${namespace}.file);
  };
}
