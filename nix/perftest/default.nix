{ stdenv, rdma-core, autoreconfHook, fetchFromGitHub, pciutils, rev, hash }:
stdenv.mkDerivation (final: {
  pname = "perftest";
  version = "0.0.1";
  src = fetchFromGitHub {
    owner = "linux-rdma";
    repo = final.pname;
    # inherit rev hash;
    rev = "446dea7da4a02501256706b3ed10e17591c7a723";
    hash = "sha256-mdbqgTAZdDi5LzIETmkDEzw7ejHx2jeUrMAVUpiEFYU=";
  };
  nativeBuildInputs = [ autoreconfHook rdma-core pciutils ];
  buildStage = ''
    set -euxo pipefail
    make CFLAGS="$CFLAGS"
  '';
})
