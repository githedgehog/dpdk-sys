{ stdenv, rdma-core, autoreconfHook, fetchFromGitHub, pciutils, rev, hash }:
stdenv.mkDerivation (final: {
  pname = "perftest";
  version = rev;
  src = fetchFromGitHub {
    owner = "linux-rdma";
    repo = final.pname;
    inherit rev hash;
  };
  nativeBuildInputs = [ autoreconfHook rdma-core pciutils ];
})
