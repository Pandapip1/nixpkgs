{
  lib,
  stdenv,
  fetchzip,
  libgcc,
  glibc_multi,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "nhc98";
  version = "1.22";

  # src = fetchzip {
  #   url = "https://www.haskell.org/nhc98/nhc98src-${finalAttrs.version}.tar.gz";
  #   hash = "sha256-Zatd90TQ+zlgAKd7CV56SsWAJ4X4bDNe8qc3Z9pTos8=";
  # };
  src = /home/gavin/repos/nhc98;

  postPatch = ''
    # Missing headers g
    substituteInPlace Makefile \
      --replace-fail 'script/nhc98 -o $(PRAGMA) script/hmake-PRAGMA.hc' 'script/nhc98 -I$(PWD)/include -o $(PRAGMA) script/hmake-PRAGMA.hc'

    # Missing type
    substituteInPlace script/nhc98heap.c \
      --replace-fail 'main' 'int main'
    substituteInPlace script/config-errno.c \
      --replace-fail 'main' 'int main'
    substituteInPlace script/errnogen.c \
      --replace-fail 'main' 'int main'
  '';

  strictDeps = true;
  buildInputs = [
    libgcc
    glibc_multi
  ];

  enableParallelBuilding = true;

  meta = {
    description = "A small, easy to install, standards-compliant compiler for Haskell 98";
    homepage = "https://www.haskell.org/nhc98/";
    license = lib.licenses.gpl1Plus; # It's a bespoke license that allows relicensing under GPL
    maintainers = with lib.maintainers; [
      pandapip1
    ];
    # mainProgram = "oscavmgr";
  };
})
