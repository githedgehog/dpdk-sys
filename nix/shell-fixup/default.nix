{
  stdenv,
}: stdenv.mkDerivation {
  pname = "dataplane-shell-fixup";
  version = "0.0.1";
  src = ./src;
  installPhase = ''
    chmod 555 $src/etc/pam.d
    chmod -R 444 $src/etc/pam.d/*
    chmod 444 $src/etc/group
    chmod 444 $src/etc/passwd
    chmod 777 $src/tmp
    cp -a $src $out
  '';

}
