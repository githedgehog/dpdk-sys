{
  rustPlatform,
  fetchFromGitHub,
  rev,
  hash,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "kopium";
  version = rev;
  src = fetchFromGitHub {
    owner = "kube-rs";
    repo = finalAttrs.pname;
    inherit rev hash;
  };
  cargoLock.lockFile = "${finalAttrs.src}/Cargo.lock";
  cargoHash = hash;
})
