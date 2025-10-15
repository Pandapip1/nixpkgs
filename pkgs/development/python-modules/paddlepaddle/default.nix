{
  lib,
  stdenv,
  pkgs,
  buildPythonPackage,
  fetchFromGitHub,
  fetchpatch,
  cmake,
  zlib,
  glog,
  eigen,
  setuptools,
  cudaPackages,
  addDriverRunpath,
  nlohmann_json,
  yaml-cpp,
  jinja2,
  pytestCheckHook,
  httpx,
  numpy,
  blas,
  pybind11,
  pyyaml,
  protobuf,
  pillow,
  decorator,
  astor,
  opt-einsum,
  typing-extensions,
  pkg-config,
  nix-update-script,
  config,
  oneAPISupport ? false,
  cudaSupport ? config.cudaSupport or false,
  rocmSupport ? config.rocmSupport or false,
  avx2Support ? stdenv.hostPlatform.avx2Support or false,
}:

buildPythonPackage rec {
  pname = "paddlepaddle";
  version = "3.2.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Pandapip1";
    repo = "Paddle";
    rev = "93ecf3d26e5a89bb3250fe08572fab29ee494d95";
    hash = "sha256-dxF/8x7olEnWplg7MGpv+hLh1OgwlEopQmHtqY+5a2Y=";
  };

  # TODO: Should cmake and pkg-config be in nativebuild or build-system?
  build-system = [
    setuptools
    pkg-config
    cmake
    pyyaml
    pybind11
    jinja2
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
    blas
    pkgs.gflags
    glog
    pkgs.protobuf
    zlib
    eigen
    nlohmann_json
    yaml-cpp
  ]
  ++ lib.optionals cudaSupport (
    with cudaPackages;
    [
      cudatoolkit.lib
      cudatoolkit.out
      cudnn
    ]
  )
  ++ lib.optionals oneAPISupport [
    pkgs.mkl
  ];
  nativeCheckInputs = [
    pytestCheckHook
  ];

  strictDeps = true;

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
    (lib.cmakeBool "WITH_MKL" oneAPISupport)
    (lib.cmakeBool "WITH_ONEMKL" oneAPISupport)
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
