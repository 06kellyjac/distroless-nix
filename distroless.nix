{ fetchurl }:
rec {
  # https://github.com/GoogleContainerTools/distroless/blob/main/checksums.bzl
  snapshot = "20211026T205805Z";
  packagesList = fetchurl {
    url = "https://snapshot.debian.org/archive/debian/${snapshot}/dists/buster/main/binary-amd64/Packages.xz";
    sha256 = "sha256-Yh1QU8wS6vxojixvGs6eQhrYSMVxp21r81KBg+7BhvE=";
  };
}
