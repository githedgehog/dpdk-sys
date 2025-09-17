{
  versions ? import ./nix/versions.nix,
  pkgs ? import (builtins.fetchTarball {
    name = "nixpkgs-unstable";
    url = versions.nixpkgs.source_url;
    sha256 = versions.nixpkgs.hash.nix32.unpacked.sha256;
  }) { },
}:
(pkgs.buildFHSEnv {
  name = "dpdk-sys-shell";
  targetPkgs =
    pkgs:
    (with pkgs; [
      bash
      jq
      just
      nil
      nix-prefetch-git
      nixd
      wget
      
      # source
      dpdk
      rdma-core.dev
      stdenv.cc.libc_dev
      libbsd.dev
    ]);
  runScript = ''bash'';
}).env
