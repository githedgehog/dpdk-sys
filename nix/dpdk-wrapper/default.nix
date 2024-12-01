{
  stdenv,
  dpdk,
  bintools,
  libbsd,
}:
stdenv.mkDerivation {
  pname = "dpdk-wrapper";
  version = "24.11.0";

  src = ./src;

  nativeBuildInptus = [
    dpdk
    libbsd.dev
    bintools
  ];

  buildPhase = ''
    set euxo pipefail
    mkdir -p $out/{lib,include}
    cc $CFLAGS -I${dpdk}/include -I${libbsd.dev}/include -c $src/dpdk_wrapper.c -o wrapper.o;
    ar rcs $out/lib/libdpdk_wrapper.a wrapper.o;
    ranlib $out/lib/libdpdk_wrapper.a;
    cp $src/*.h $out/include
  '';

}
