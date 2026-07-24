{
  lib,
  buildNpmPackage,
  grayjay,
}:

buildNpmPackage {
  pname = "${grayjay.pname}-frontend";

  # nixpkgs-update: no auto update
  inherit (grayjay) version src;

  sourceRoot = "source/Grayjay.Desktop.Web";

  npmBuildScript = "build";
  npmDepsHash = "sha256-3yJIPkuEvkFL9Wb4y/r0yEULQbXx/wHqicFBLzOPj68=";

  installPhase = ''
    runHook preInstall
    cp -r dist/ $out
    runHook postInstall
  '';

  meta = {
    description = "curl-impersonate shim used by Grayjay";
    homepage = "https://grayjay.app/desktop/";
    inherit (grayjay.meta) license maintainers platforms;
  };
}
