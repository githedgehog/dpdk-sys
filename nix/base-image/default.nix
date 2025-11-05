{
    stdenv,
    glibc,
    libgcc,
}: stdenv.mkDerivation rec {
    pname = "base-image";
    version = "25.07";

    src = ./root;

    installPhase = ''
        cp -r $src $out
    '';
    dontUnpack = true;
    buildInputs = [
        glibc.out
        libgcc.libgcc
    ];
}
