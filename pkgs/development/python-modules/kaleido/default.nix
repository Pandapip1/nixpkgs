{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchgit,
  buildPythonPackage,
  callPackage,
  wheel,
  ninja,
  setuptools,
  gn,
  nss,
  nspr,
  sqlite,
  expat,
  glibc,
}:

buildPythonPackage rec {
  pname = "kaleido";
  version = "0.2.1";
  pyproject = true;

  src = stdenv.mkDerivation {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "plotly";
      repo = "Kaleido";
      tag = "v${version}";
      hash = "sha256-/ZDPZCbm/y5ycQ4KaPuptR/FIcdP7gUjWHURBXlr+1w=";
    };
  };

  postPatch = ''
    cd repos
    fetch --nohooks chromium
    cd ..
  '';

  build-system = [ wheel setuptools ninja gn ];

  buildInputs = [
    nss
    nspr
    sqlite
    expat
    glibc
  ];

  postPatch = ''
    echo "${version}" > repos/kaleido/version
    cp repos/linux_scripts/args_x64.gn repos/linux_scripts/args_x86_64.gn
    cp repos/linux_scripts/args_arm64.gn repos/linux_scripts/args_aarch64.gn
  '';

  dontConfigure = true;

  preBuild = ''
    export KALEIDO_ARCH=$(echo $system | cut -d- -f1)
    echo "Detected architecture: $KALEIDO_ARCH"

    mkdir -p out/Kaleido_linux_$KALEIDO_ARCH

    # Write out/Kaleido_linux_$KALEIDO_ARCH/args.gn
    cp repos/linux_scripts/args_$KALEIDO_ARCH.gn out/Kaleido_linux_$KALEIDO_ARCH/args.gn
    cd out/Kaleido_linux_$KALEIDO_ARCH
    ls -la .
    gn gen . --root=args.gn
    cd ../..

    # Copy kaleido/kaleido.cc to src/headless/app/kaleido.cc
    rm -rf headless/app/scopes
    mkdir -p headless/app
    cp -r repos/kaleido/cc/* headless/app/

    # Perform build, result will be out/Kaleido_linux_$KALEIDO_ARCH/kaleido
    ninja -C out/Kaleido_linux_$KALEIDO_ARCH -j 16 kaleido

    if [ ! -f "out/Kaleido_linux_$KALEIDO_ARCH/kaleido" ]
    then
      echo "Error: Kaleido executable was not built";
      exit 1
    fi

    # First build up kaledo_minimal directory with core kaleido files
    rm -rf repos/build/kaleido_minimal
    mkdir -p repos/build/kaleido_minimal/bin
    cp out/Kaleido_linux_$KALEIDO_ARCH/kaleido /repos/build/kaleido_minimal/bin
    cp -r out/Kaleido_linux_$KALEIDO_ARCH/swiftshader/ /repos/build/kaleido_minimal/bin

    # version
    cp /repos/kaleido/version /repos/build/kaleido_minimal/

    # license
    cp /repos/kaleido/LICENSE.txt /repos/build/kaleido_minimal/
    cp /repos/kaleido/README.md /repos/build/kaleido_minimal/
    cp /repos/CREDITS.html /repos/build/kaleido_minimal/

    # Copy kaleido_minimal/ directory to kaleido/
    rm -rf /repos/build/kaleido
    cp -r /repos/build/kaleido_minimal/ /repos/build/kaleido/

    # fonts
    mkdir -p /repos/build/kaleido/etc/
    cp -r /etc/fonts/ /repos/build/kaleido/etc/fonts
    mkdir -p /repos/build/kaleido/xdg
    cp -r /usr/share/fonts/ /repos/build/kaleido/xdg/

    # mathjax
    unzip /repos/vendor/Mathjax-2.7.5.zip -d /repos/build/kaleido/etc/
    mv /repos/build/kaleido/etc/Mathjax-2.7.5 /repos/build/kaleido/etc/mathjax

    # Add full launch script
    cp repos/linux_scripts/launch_script repos/build/kaleido/kaleido

    # Add minimal launch script
    cp repos/linux_scripts/minimal_launch_script repos/build/kaleido_minimal/kaleido

    # cd to the build directory
    cd repos/kaleido/py
  '';

  pythonImportsCheck = [ "kaleido" ];

  passthru.tests = lib.optionalAttrs (!stdenv.hostPlatform.isDarwin) {
    kaleido = callPackage ./tests.nix { };
  };

  meta = {
    description = "Fast static image export for web-based visualization libraries with zero dependencies";
    homepage = "https://github.com/plotly/Kaleido";
    changelog = "https://github.com/plotly/Kaleido/releases";
    platforms = lib.platforms.all;
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ pandapip1 ];
  };
}
