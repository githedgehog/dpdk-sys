# WARNING: This file is generated by the bump.sh script. Do not edit it manually.
{
  nixpkgs = {
    branch = "nixpkgs-unstable";
    commit = "6027c30c8e9810896b92429f0092f624f7b1aace";
    commit_date = "2025-07-25T08:26:56+00:00";
    source_url = "https://github.com/NixOS/nixpkgs/archive/6027c30c8e9810896b92429f0092f624f7b1aace.tar.gz";
    hash = {
      nix32 = {
        packed = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (packed)";
          sha256 = "1ag99694cb1s1ijjd4pl2ykiy0nxkzypvzm0nf526l85r081zzc6";
          sha512 = "3s4c6wkjzkbyh98jhn6j6cmdyhfbfpbbs318f58gl4f13ngy3jwaimy9ax9hn5jzk31n9l7xwnsrdx2sr8pd4bsq4zxnxxqmxfli85d";
        };
        unpacked = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (unpacked)";
          sha256 = "1y0acnmg4f48xxi3vv68kddj1d2bak9xrx3zr1l4dipzd5czjwkj";
        };
      };
      tar = {
        comment = "openssl generated hashes of the actual tar.gz file obtained from github archive";
        sha256 = "86fd1f10c80551238ab3a0fe7dfd9fdd021fa717f49226650c3a2c469249e9a9";
        sha384 = "0ecbbb57821a324122ea4b5bfb61ad1c1ac7fc55fa3bee61ef04facdb195dfcd1b7af965f2c2f9b16178d7c7f7bd2f9c";
        sha512 = "ada0485dafb877db3fc17a917651d6a2b7ac2def87261bc6fcb25898ba4abe46c5e5f0cf8ee0087da83814865eebbae5a06f9519692c942841bfe697931b46f4";
        sha3_256 = "e43a6db75cc17431bda7def1cd70d3ca7f8d902549eed20811a598ac09f974ed";
        sha3_384 = "7d0e9f3cc01543f015bce181b6dd87deafeeeadf6ebb9fb22b7545dd8e441410bb400c2c8e36a3a6af450d18aafbaf00";
        sha3_512 = "f7c1ffa9bcdd203765400d209b8a1d53fb4044ccef9f275fba93d1842ecf846530ddc17d75e0b6369efe7f5d1a77f9034bf5001e82a6e2bd573f342d9ee29f18";
        blake2b512 = "001f7137116945ca48e23318b53a3c1b8ff8eb2e976063f50797fb3c17af9a09b34edad343dba750941fc3339d45b0c38f7785ace6555629d2f244f81f7887c7";
        blake2s256 = "6bb5bbb3bd54c0e8097b4e31d8dfc281a02845640f4b3025a8fe35f7a41b95cd";
      };
    };
  };
  rust = {
    stable = {
      channel = "stable";
      toolchain_toml_hash = "sha256-Qxt8XAuaUR2OMdKbN4u8dBJOhSHxS+uS06Wl9+flVEk=";
      version = "1.88.0";
      llvm = "20";
      profile = "default";
      targets = [
        "x86_64-unknown-linux-gnu"
      ];
      extensions = [
        "cargo"
        "clippy"
        "llvm-bitcode-linker"
        "llvm-tools"
        "rust-analyzer"
        "rust-docs"
        "rust-src"
        "rust-std"
        "rustc"
        "rustfmt"
      ];
    };
  };
  dplane-rpc = {
    branch = "master";
    rev = "e8fc33db10e1d00785f2a2b90cbadcad7900f200";
    hash = "sha256-tjN4qSbKrWfosOV3wt2AnQxmVL0BPZYBjAHG3X00+aM=";
    commit_date = "2025-07-22T12:35:11+00:00";
  };
  dplane-plugin = {
    branch = "master";
    rev = "b0d2ada4d5948519104dab7e668a201c3c340b2b";
    hash = "sha256-llZAyc9HGum4Le9pOt8QSILlVg5AO1TtKgQsTZnu/og=";
    commit_date = "2025-07-22T12:48:20+00:00";
  };
  frr = {
    branch = "hh-master-10.3";
    rev = "7f43a0d792aa178f1416f9d41d5096725ffdfccc";
    hash = "sha256-1nWAGo95DJdRhC29DuZDA1p2pREOZTit2i67WLF7QiY=";
    commit_date = "2025-06-25T21:48:53+00:00";
  };
  frr-agent = {
    branch = "master";
    rev = "8d94e71a7ecc1876bdc5f01b090015e54519b7b1";
    hash = "sha256-FK0TQOUgsx2UDcNxKyAm4nrnAltnKP/9evPT8r8/U0A=";
    commit_date = "2025-07-10T18:58:21+00:00";
  };
  perftest = {
    branch = "master";
    rev = "5be2b4e99957cac651bbfe3d1425b80a862d70f7";
    hash = "sha256-NSw0xblFCgfvSwFclfFZVVOySq6X7SSypykrLIxTJCE=";
    commit_date = "2025-07-07T07:54:58+00:00";
  };
}
