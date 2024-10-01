{
  stdenv,
  clang,
  dpdk,
  llvm,
  libbsd,
  libnl,
}: stdenv.mkDerivation {
  pname = "dpdk-wrapper";
  version = "24.07";

  src = ./src;

  nativeBuildInptus = [
    clang
    dpdk
    libbsd.dev
    libnl
    llvm
  ];

  buildPhase = ''
    set euxo pipefail
    mkdir -p $out/{lib,include}
    ${stdenv.cc}/bin/clang \
      -Wno-deprecated-declarations \
      -Ic \
      -O3 \
      -flto=thin \
      -fretain-comments-from-system-headers \
      -fparse-all-comments \
      -march=native \
      -ggdb3 \
      -march=x86-64-v4 \
      -mtune=znver4 \
      -Werror=odr \
      -Werror=strict-aliasing \
      -fstack-protector-strong \
      -I${dpdk}/include \
      -I${libbsd.dev}/include \
      -c \
      $src/dpdk_wrapper.c \
      -o \
      wrapper.o;
    ${llvm}/bin/llvm-ar rcs $out/lib/libdpdk_wrapper.a wrapper.o;
    cp $src/*.h $out/include
  '';

}
