# WARNING: This file is generated by the bump.sh script. Do not edit it manually.
{
  nixpkgs = {
    branch = "nixpkgs-unstable";
    commit = "dab3a6e781554f965bde3def0aa2fda4eb8f1708";
    commit_date = "2025-07-15T16:15:05+00:00";
    source_url = "https://github.com/NixOS/nixpkgs/archive/dab3a6e781554f965bde3def0aa2fda4eb8f1708.tar.gz";
    hash = {
      nix32 = {
        packed = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (packed)";
          sha256 = "16ivhs0sckg5slxlcz3g0b89znq8r0zij2fparfd2zkgxhrqv333";
          sha512 = "2hls3jrw6xmkdgq0z5wgjzv9fssyn5x3lanm1843asj2y83mvrrr2v4bfrl9v8wg40pjrry1gfg6gk5fc7lcqzj6y3967nz2dvxc81q";
        };
        unpacked = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (unpacked)";
          sha256 = "0sabyminhpllps3k0hhxf54jhic51ilvhk2xmfvvl776xyr5alwl";
        };
      };
      tar = {
        comment = "openssl generated hashes of the actual tar.gz file obtained from github archive";
        sha256 = "638c8d33ec6f7ed15c56d709193fc808db9fd0026f7c463bd5e54da681863b9a";
        sha384 = "f021702ff2d33d9718d88b5c8e4392dc3ad96a8c5972349faac268b4de2e24960d37ddca33455c0100ecb3f382bd9693";
        sha512 = "3820d67713df1e938637f263460f73653ef3dc0b3e677901791ced44b35b648b9cf3ae037921b51a04856a151dbd58afb54bfbcbc7cb07f8b559bbe1590e4da1";
        sha3_256 = "90151300b280c607f59095e63e805cb64862de612e1bd7acc729f732a06788a9";
        sha3_384 = "a61306e66213341ea942da5e741c9348a31bfd7a44050a0a2762865288cf9609b272193ea2b8d2ddeff15db14691e7b6";
        sha3_512 = "0a36710f4c6ebca6f4cd8ef88ecc7dd827941ff14b2fc1aebc75dd5fd99b7ba774bfd6cbf2ede200592037a0894291a5d1938d5d67aa4128affa647ffa012800";
        blake2b512 = "388c5415d023825d521108dd683958524c9dc7d9f794178b1d329a1f07e6489f16750b7807d3cefb57d1c9735440e2c96fcd50caa8796e4f7f561a4afaa2b37b";
        blake2s256 = "ccc072121477a76e87af67b470796050d60fbea429d20215233adf7430ab4501";
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
    rev = "dec4aabd377b00ab8b35dafc5e3adae57930522c";
    hash = "sha256-90c9BqoO8pBxVFovrRf7oZcGEEI7MN5Gqkod/He4QgA=";
    commit_date = "2025-07-09T13:53:39+00:00";
  };
  dplane-plugin = {
    branch = "master";
    rev = "d1bcf31ac6cab80e5f9d26137804ac7266b9c80c";
    hash = "sha256-ULQFG7Ucsor8m/r8+vMWngPPM4p7et4v7yMLasK9Zyk=";
    commit_date = "2025-07-10T12:18:20+00:00";
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
