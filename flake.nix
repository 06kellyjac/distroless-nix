{
  description = "Flake utils demo";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.distroless = { url = "github:GoogleContainerTools/distroless"; flake = false; };

  outputs = { self, nixpkgs, flake-utils, distroless }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        mylib = pkgs.callPackage ./lib.nix { inherit distroless; };
        inherit (mylib) nameToBundle packagesFrom;

        extractDebs = pkgs.callPackage ./extractDebs.nix { };

        dl = pkgs.callPackage ./distroless.nix { };
        buildDebImage = pkgs.callPackage ./buildDebImage.nix { };
      in
      rec {
        packages.distroless = buildDebImage {
          name = "distroless-test";
          debDistro = pkgs.vmTools.debDistros.debian10x86_64;
          packages = [
            "base-files"
            "netbase"
            "tzdata"
            "ca-certificates"
          ];
          imageParams = {
            fakeRootCommands = ''
              mkdir -p ./home/nonroot
              chown 65532 ./home/nonroot
              mkdir -p ./tmp
              chmod 01777 ./tmp
            '';
            config = {
              Env = [
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
                "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
              ];
            };
          };
        };
        packages.debs = (extractDebs {
          name = "debs";
          debDistro = pkgs.vmTools.debDistros.debian10x86_64;
          # packages = [ allDistrolessPackages ];
          packages = [
            "base-files"
            "netbase"
            "tzdata"
            "ca-certificates"
          ];
          packagesList = dl.packagesList;
        });
      }
    );
}
