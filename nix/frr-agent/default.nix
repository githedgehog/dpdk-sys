{
  rev,
  hash,
  rustPlatform,
  fetchFromGitHub,
  nukeReferences,
  libgcc,
  stdenv,
}:
rustPlatform.buildRustPackage (final: {
  pname = "frr-agent";
  version = rev;
  nativeBuildInputs = [nukeReferences];
  src = fetchFromGitHub {
    repo = final.pname;
    owner = "githedgehog";
    inherit rev hash;
  };
  cargoLock = { lockFile = final.src + "/Cargo.lock"; };
  fixupPhase = ''
    find "$out" -exec nuke-refs -e "$out" -e "${stdenv.cc.libc}" -e "${libgcc.lib}" '{}' +;
  '';
})
