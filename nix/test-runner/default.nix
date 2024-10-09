{
  bash,
  coreutils,
  libcap,
  pam,
  stdenv,
  sudo,
}: stdenv.mkDerivation {
  pname = "dataplane-test-runnner";
  version = "0.0.1";

  src = ./src;

  buildInputs = [
    bash
    coreutils
    libcap
    pam
    sudo
  ];

  installPhase = ''
    cp -a $src $out
  '';

}
