{
  stdenv,
}:
stdenv.mkDerivation {
  pname = "dataplane-plantuml-wrapper";
  version = "0.0.1";
  src = ./src;
  installPhase = ''
    cp -a $src $out
  '';
}
