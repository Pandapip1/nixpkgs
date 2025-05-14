{
  lib,
  stdenv,
  fetchFromGitHub,
  replaceVars,
  srcOnly,
  chromium,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kaleido";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "plotly";
    repo = "Kaleido";
    tag = "v${finalAttrs.version}";
    hash = "sha256-/ZDPZCbm/y5ycQ4KaPuptR/FIcdP7gUjWHURBXlr+1w=";
  };

  sourceRoot = "repos/kaleido/cc";

  postPatch = ''
    cp ${replaceVars ./CMakeLists.txt {
      chromium_src = srcOnly chromium;
    }} repos/kaleido/cc/CMakeLists.txt
  '';

  nativeBuildInputs = [ cmake ];

  meta = {
    description = "Fast static image export for web-based visualization libraries with zero dependencies";
    homepage = "https://github.com/plotly/Kaleido";
    changelog = "https://github.com/plotly/Kaleido/releases";
    platforms = lib.platforms.all;
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ pandapip1 ];
  };
})
