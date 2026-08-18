{ ... }:
let
  namespace = "workspace";
  nsImporter = import ./libs/nix-utils/_importer.nix { inherit namespace; };
in
{
  imports = nsImporter [
    ./libs
    ./services
  ];
}
