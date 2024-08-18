{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

{
  executable,
  setUID ? null,
  resetUID ? false,
  setRealUID ? null,
  setGID ? null,
  resetGID ? false,
  setRealGID ? null,
}:

stdenv.mkDerivation (finalAttrs: {
  name = "securitywrap-${builtins.baseNameOf executable}";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "pandapip1";
    repo = "securitywrap";
    rev = "refs/tags/v${finalAttrs.version}";
    hash = "sha256-eMHFTy3uCvWMCuMDezGRVSxhdnsz/FOsL0KMDfrFAB0=";
  };

  nativeBuildInputs = [ cmake ];
  cmakeFlags = [
    (lib.cmakeFeature "WRAP_EXECUTABLE" executable)
    (lib.optionalString (setUID != null) (lib.cmakeFeature "SET_UID" (builtins.toString setUID)))
    (lib.optionalString resetUID (lib.cmakeBool "RESET_UID" true))
    (lib.optionalString (setRealUID != null) (
      lib.cmakeFeature "SET_REAL_UID" (builtins.toString setRealUID)
    ))
    (lib.optionalString (setGID != null) (lib.cmakeFeature "SET_GID" (builtins.toString setGID)))
    (lib.optionalString resetGID (lib.cmakeBool "RESET_GID" true))
    (lib.optionalString (setRealGID != null) (
      lib.cmakeFeature "SET_REAL_GID" (builtins.toString setRealGID)
    ))
  ];

  meta = {
    description = "A simple tool to run a command with real and/or effective uids and/or gids";
    license = lib.licenses.lgpl3;
    maintainers = with lib.maintainers; [ pandapip1 ];
    mainProgram = builtins.baseNameOf executable;
  };
})
