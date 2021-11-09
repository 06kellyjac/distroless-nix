{ lib, distroless }:
rec {
  # packages = builtins.fromJSON distroless;
  # debian-10.9-buster-amd64 -> amd64_debian10
  nameToBundle = name:
    let
      splitName = builtins.split "-" name;
      fullVer = builtins.elemAt splitName 2;
      arch = builtins.elemAt splitName 6;
    in
    "${arch}_debian${lib.versions.major fullVer}";

  # allDistrolessPackages = packagesFrom pkgs.vmTools.debDistros.debian10x86_64.name;
  packagesFrom = name: builtins.attrNames (builtins.fromJSON (builtins.readFile "${distroless}/package_bundle_${nameToBundle name}.versions"));
}
