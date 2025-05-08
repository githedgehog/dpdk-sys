{
  stdenv,
  fetchFromGitHub,

  # build time
  cmake,
  rev,
  hash,

  # args
  cmakeBuildType ? "Release",
}:

stdenv.mkDerivation
(finalAttrs: {
  pname = "dplane-rpc";
  version = rev;

  doCheck = false;
  enableParallelBuilding = true;

  src = fetchFromGitHub {
    owner = "githedgehog";
    repo = finalAttrs.pname;
    inherit rev hash;
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
