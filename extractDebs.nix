{ stdenvNoCC, fetchurl, vmTools, dpkg, lib, xz, fakeroot, util-linux }:
{ name, packages, debDistro, packagesList }:
let
  n = name;
in
stdenvNoCC.mkDerivation rec {
  name = n + "-" + debDistro.name;

  src =
    let
      expr = vmTools.debClosureGenerator {
        inherit (debDistro) name urlPrefix;
        packagesLists = [ packagesList ];
        packages = [ packages ];
      };
    in
    import expr {
      inherit fetchurl;
    };

  debs = (lib.intersperse "|" src);

  buildCommand = ''
    mkdir unpacked
    PATH="$PATH:${lib.makeBinPath [ dpkg xz fakeroot ]}"
    echo "unpacking debs"
    for i in $src; do
      echo $i
      # some debs have permissions issues and need a fakeroot
      fakeroot dpkg-deb --root-owner-group --extract $i ./unpacked
    done

    # mkdir $out
    # cp ./unpacked $out/original -r

    fakeroot bash -c '
      # Misc. files/directories assumed by various packages.
      echo "initialising Dpkg DB..."
      touch ./unpacked/etc/shells
      touch ./unpacked/var/lib/dpkg/status
      touch ./unpacked/var/lib/dpkg/available
      touch ./unpacked/var/lib/dpkg/diversions

      # Now install the .debs.  This is basically just to register
      # them with dpkg and to make their pre/post-install scripts
      # run.
      echo "installing Debs..."

      export DEBIAN_FRONTEND=noninteractive

      oldIFS="$IFS"
      IFS="|"
      for component in $debs; do
        IFS="$oldIFS"
        echo
        echo ">>> INSTALLING COMPONENT: $component"
        debs=
        for i in $component; do
          debs="$debs $i";
        done

        # Create a fake start-stop-daemon script, as done in debootstrap.
        mv "./unpacked/sbin/start-stop-daemon" "./unpacked/sbin/start-stop-daemon.REAL"
        echo "#!/bin/true" > "./unpacked/sbin/start-stop-daemon"
        chmod 755 "./unpacked/sbin/start-stop-daemon"

        dpkg --root=./unpacked --install --force-all $debs < /dev/null || true
        # Move the real start-stop-daemon back into its place.
        mv "./unpacked/sbin/start-stop-daemon.REAL" "./unpacked/sbin/start-stop-daemon"
      done

      rm ./unpacked/.debug || true
    '

    # cp ./unpacked $out/postinst -r

    mv ./unpacked $out
  '';
}
