{ dockerTools, callPackage }:
{ name, debDistro, packages, imageParams }:
let
  extractDebs = callPackage ./extractDebs.nix { };
  dl = callPackage ./distroless.nix { };
  inherit (dl) packagesList;
in
dockerTools.buildImage {
  inherit name;
  contents = [ (extractDebs { inherit name packages debDistro packagesList; }) ];
} // imageParams
