{
  lib,
  stdenv,
  pkgs,
  buildPythonPackage,
  fetchFromGitHub,
  fetchpatch,
  cmake,
  zlib,
  setuptools,
  cudaPackages,
  addDriverRunpath,
  pytestCheckHook,
  httpx,
  numpy,
  protobuf,
  pillow,
  decorator,
  astor,
  opt-einsum,
  typing-extensions,
  nix-update-script,
  config,
  cudaSupport ? config.cudaSupport or false,
  rocmSupport ? config.rocmSupport or false,
  avx2Support ? stdenv.hostPlatform.avx2Support or false,
}:

buildPythonPackage rec {
  pname = "paddlepaddle";
  version = "3.2.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "PaddlePaddle";
    repo = "Paddle";
    tag = "v${version}";
    hash = "sha256-LhchfdnsXk718v0z5wNVQLJYBlnBgqlbiEpDdmdQN3U=";
  };

  patches = [
    # Backport fix for use of old CMake behavior
    (fetchpatch {
      url = "https://github.com/PaddlePaddle/Paddle/commit/01edb453af3806410971c20148c93e813c40b7af.patch";
      hash = "sha256-OJu9fLIiNYRAHtcpzLDMQUZ4zWPLFX0odjjGN7/IHSQ=";
    })
  ];

  postPatch = ''
    cat > cmake/version.cmake << EOF
    function(version version_file)
      file(
        WRITE ''${version_file}
        "Paddle version: ''${PADDLE_VERSION}\n"
        "Nixpkgs path: ${pkgs.path}\n")
    endfunction()
    EOF
    cat > cmake/third_party.cmake << EOF
    include(ExternalProject)
    EOF
    substituteInPlace CMakeLists.txt \
      --replace-fail "find_package(Git REQUIRED)" ""
  '';

  build-system = [
    setuptools
    cmake
  ];
  dependencies = [
    httpx
    numpy
    protobuf
    pillow
    decorator
    astor
    opt-einsum
    typing-extensions
  ];
  nativeBuildInputs = [
    addDriverRunpath
  ];
  buildInputs = [
    zlib
  ]
  ++ lib.optionals cudaSupport (
    with cudaPackages;
    [
      cudatoolkit.lib
      cudatoolkit.out
      cudnn
    ]
  );
  nativeCheckInputs = [
    pytestCheckHook
  ];

  cmakeFlags = [
    (lib.cmakeFeature "PADDLE_VERSION" version)
    (lib.cmakeBool "WITH_GPU" (cudaSupport || stdenv.hostPlatform.isDarwin))
    (lib.cmakeBool "WITH_NCCL" cudaSupport)
    (lib.cmakeBool "CINN_WITH_CUDNN" cudaSupport)
    (lib.cmakeBool "WITH_ROCM" rocmSupport)
    (lib.cmakeBool "WITH_RCCL" rocmSupport)
    (lib.cmakeBool "WITH_AVX" avx2Support)
    (lib.cmakeBool "WITH_MUSL" (stdenv.hostPlatform.libc == "musl"))
    (lib.cmakeBool "WITH_PIP_CUDA_LIBRARIES" false)
    (lib.cmakeBool "WITH_PIP_TENSORRT" false)
  ];

  pythonImportsCheck = [ "paddle" ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Machine Learning Framework from Industrial Practice";
    homepage = "https://github.com/PaddlePaddle/Paddle";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      happysalada
      pandapip1
    ];
  };
}
