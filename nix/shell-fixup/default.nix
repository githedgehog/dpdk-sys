{
  stdenv,
}:
stdenv.mkDerivation {
  pname = "dataplane-shell-fixup";
  version = "0.0.1";
  src = ./src;
  installPhase = ''
    cp -a $src $out
  '';
}
