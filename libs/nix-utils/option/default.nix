{
  namespace,
  lib,
  ...
}:
let
  inherit (lib) types;

  mkPrimOpt =
    primType:
    {
      description ? "",
      readOnly ? false,
      nullable ? false,
      default ? null,
      ...
    }:
    lib.mkOption (
      {
        inherit readOnly;
        type = with types; if nullable then (nullOr primType) else primType;
        description = if description != "" then description else "Value to be set";
      }
      // (lib.optionalAttrs (default != null || nullable) {
        inherit default;
      })
    );

in
{
  ${namespace}.utils = {
    inherit mkPrimOpt;
    mkBoolOpt = inputs: mkPrimOpt types.bool inputs;
    mkPathOpt = inputs: mkPrimOpt types.path inputs;
    mkStrOpt = inputs: mkPrimOpt types.str inputs;
    mkIntOpt = inputs: mkPrimOpt types.int inputs;
    mkFloatOpt = inputs: mkPrimOpt types.float inputs;
    mkPackOpt = inputs: mkPrimOpt types.package inputs;
    mkEnumOpt =
      {
        values ? [ ],
        ...
      }@inputs:
      mkPrimOpt (types.enum values) inputs;
    mkListOpt =
      {
        ofType ? types.anything,
        ...
      }@inputs:
      mkPrimOpt (types.listOf ofType) inputs;
    mkAttrsOpt =
      {
        ofType ? types.anything,
        ...
      }@inputs:
      mkPrimOpt (types.attrsOf ofType) inputs;
  };
}
