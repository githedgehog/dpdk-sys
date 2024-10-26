{
  stdenv,
}: stdenv.mkDerivation {
  pname = "dataplane-shell-fixup";
  version = "0.0.1";
  src = ./src;
  installPhase = ''
    cp -a $src $out
    chmod 555 $out/etc/pam.d
    chmod -R 444 $out/etc/pam.d/*
    chmod 444 $out/etc/group
    chmod 444 $out/etc/passwd
    chmod 777 $out/tmp
  '';

}
