{
  lib,
  stdenv,
  cmake,
  cups,
  ninja,
  python,
  pythonImportsCheckHook,
  moveBuildTree,
  shiboken6,
  llvmPackages,
  symlinkJoin,
}:
let
  packages =
    (with python.pkgs; [
      ninja
      packaging
      setuptools
    ])
    ++ (with python.pkgs.qt6; [
      # required
      qtbase

      # optional
      qt3d
      qtcharts
      qtconnectivity
      qtdatavis3d
      qtdeclarative
      qthttpserver
      qtmultimedia
      qtnetworkauth
      qtquick3d
      qtremoteobjects
      qtscxml
      qtsensors
      qtspeech
      qtsvg
      qtwebchannel
      qtwebsockets
      qtpositioning
      qtlocation
      qtshadertools
      qtserialport
      qtserialbus
      qtgraphs
      qttools
    ])
    # qtwebengine fails under darwin
    # see https://github.com/NixOS/nixpkgs/pull/312987
    ++ lib.optionals (!(stdenv.hostPlatform.isDarwin)) (with python.pkgs.qt6; [ qtwebengine ]);
  # Many PySide6 build files expect all qt tools and libexec tools to be in the same directory
  # TODO: For some reason when using qt_linked as the sole dependency, a lot of failures happen.
  # For stability, this should probably be the case but troubleshooting will be needed
  qt_linked = symlinkJoin {
    name = "qt_linked";
    paths = packages;
  };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "pyside6";

  inherit (shiboken6) version src;

  sourceRoot = "pyside-setup-everywhere-src-${finalAttrs.version}/sources/pyside6";

  # Qt Designer plugin moved to a separate output to reduce downstream closure size
  outputs = [
    "out"
    "devtools"
  ];

  postPatch =
    ''
      # Don't ignore optional Qt modules
      substituteInPlace cmake/PySideHelpers.cmake \
        --replace-fail \
          'string(FIND "''${_module_dir}" "''${_core_abs_dir}" found_basepath)' \
          'set (found_basepath 0)'
    ''
    # TODO: Why does this need to be here?
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      substituteInPlace cmake/PySideHelpers.cmake \
        --replace-fail \
          "Designer" ""
    '';

  # "Couldn't find libclang.dylib You will likely need to add it manually to PATH to ensure the build succeeds."
  env = lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    LLVM_INSTALL_DIR = "${lib.getLib llvmPackages.libclang}/lib";
  };

  nativeBuildInputs = [
    cmake
    ninja
    python
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [ moveBuildTree ];
  buildInputs =
    lib.optionals stdenv.hostPlatform.isDarwin (
      python.pkgs.qt6.darwinVersionInputs
      ++ [
        qt_linked
        cups
      ]
    )
    ++ lib.optionals (!(stdenv.hostPlatform.isDarwin)) packages;
  propagatedBuildInputs = [ shiboken6 ];
  nativeCheckInputs = [ pythonImportsCheckHook ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_TESTS" false)
    (lib.cmakeFeature "QT6_INSTALL_PREFIX" qt_linked.outPath)
  ];

  dontWrapQtApps = true;

  postInstall = ''
    cd ../../..
    ${python.pythonOnBuildForHost.interpreter} setup.py egg_info --build-type=pyside6
    cp -r PySide6.egg-info $out/${python.sitePackages}/
    sed -i "1i Provides-Dist: PySide6_Essentials==$version" "$out/${python.sitePackages}/PySide6.egg-info/PKG-INFO"

    mkdir -p "$devtools"
    moveToOutput "${python.pkgs.qt6.qtbase.qtPluginPrefix}/designer" "$devtools"
  '';

  pythonImportsCheck = [ "PySide6" ];

  meta = {
    description = "Python bindings for Qt";
    license = with lib.licenses; [
      lgpl3Only
      gpl2Only
      gpl3Only
    ];
    homepage = "https://wiki.qt.io/Qt_for_Python";
    changelog = "https://code.qt.io/cgit/pyside/pyside-setup.git/tree/doc/changelogs/changes-${finalAttrs.version}?h=v${finalAttrs.version}";
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.all;
  };
})
