{
  stdenv,
  fetchFromGitHub,

  # build time
  cmake,

  # args
  cmakeBuildType ? "Release",
}:

stdenv.mkDerivation
(finalAttrs: {
  pname = "dplane-rpc";
  version = "0.0.1";

  doCheck = false;
  enableParallelBuilding = true;

  src = fetchFromGitHub {
    owner = "githedgehog";
    repo = finalAttrs.pname;
    rev = "019206ff443645684596fbef49470163f5ae58d6";
    hash = "sha256-lbkDKEvOhrgP+AQO2ENjmpPUYoBcW8mlByHXOLbp518=";
  };

  outputs = ["out" "dev"];

  nativeBuildInputs = [
    cmake
  ];

  cmakeFlags = [
    "-S" "../clib"
    "-DCMAKE_BUILD_TYPE=${cmakeBuildType}"
    "-DCMAKE_C_STANDARD=23"
  ];

  configurePhase = ''
    export NIX_CFLAGS_COMPILE=" $CFLAGS $LDFLAGS -fvisibility=default ";
    export NIX_CFLAGS_LINK=" $LDFLAGS ";
    cmake -DCMAKE_C_STANDARD=23 -S ./clib .
  '';

  buildPhase = ''
    make DESTDIR="$out";
  '';

  installPhase = ''
    make DESTDIR="$out" install;
    mv $out/usr/local/* $out
    mv $out/usr/include $out
    rmdir $out/usr/local
    rmdir $out/usr
  '';

})
