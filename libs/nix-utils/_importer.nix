{ namespace, ... }:
folders:
let
  findDefaultNix =
    folder:
    let
      entries = builtins.readDir folder;
      subfolders = builtins.filter (name: entries.${name} == "directory") (builtins.attrNames entries);
    in
    (if builtins.pathExists (folder + "/default.nix") then [ (folder + "/default.nix") ] else [ ])
    ++ builtins.concatMap (name: findDefaultNix (folder + "/${name}")) subfolders;

  importWithNamespace =
    modulePath: args:
    let
      module = import modulePath;
    in
    if builtins.isFunction module then module (args // { inherit namespace; }) else module;
in
builtins.map importWithNamespace (builtins.concatMap findDefaultNix folders)
