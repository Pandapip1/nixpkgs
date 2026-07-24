{
  lib,
  stdenv,
  grayjay,
  curl-impersonate,
}:

stdenv.mkDerivation {
  pname = "${grayjay.pname}-libcurlshim";

  # nixpkgs-update: no auto update
  inherit (grayjay) version src;

  sourceRoot = "source/curlbind/native";

  dontConfigure = true;

  buildInputs = [ curl-impersonate ];
  buildPhase = ''
    runHook preBuild

    $CC -shared -fPIC \
      -I ${lib.getDev curl-impersonate}/include \
      "curlshim.c" \
      -o libcurlshim.so \
      -L ${lib.getLib curl-impersonate}/lib -lcurl-impersonate

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp libcurlshim.so $out/lib/

    runHook postInstall
  '';

  meta = {
    description = "curl-impersonate shim used by Grayjay";
    homepage = "https://grayjay.app/desktop/";
    inherit (grayjay.meta) license maintainers platforms;
  };
}
