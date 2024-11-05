# WARNING: This file is generated by the update-version-pinning.sh script. Do not edit it manually.
{
  nixpkgs = {
    branch = "nixpkgs-unstable";
    commit = "a04d33c0c3f1a59a2c1cb0c6e34cd24500e5a1dc";
    commit_date = "2024-11-05T01:08:39+00:00";
    source_url = "https://github.com/NixOS/nixpkgs/archive/a04d33c0c3f1a59a2c1cb0c6e34cd24500e5a1dc.tar.gz";
    hash = {
      nix32 = {
        packed = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (packed)";
          sha256 = "0zhj471j3z82wpq0byf1sshlsjfrv92g3lc5kyw86lzfq98n2lgr";
          sha512 = "1vldm864mcgwm1qfadpxd1mgdv5v87gdics8aviy4rbspf3pb90xhmgkis4vbf4kqm6zl4ag6xf10b8xin7x30qwl29hjgb234bwsvl";
        };
        unpacked = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (unpacked)";
          sha256 = "0ha2a6j3y4dbclcw7s6p473fcrzxhn4yap4wbm8s4jg7v6wal0ph";
        };
      };
      tar = {
        comment = "openssl generated hashes of the actual tar.gz file obtained from github archive";
        sha256 = "f9516151c2ee5383b89f85d1f144dad9494da1d6c1f905f0e502fd21c321127e";
        sha384 = "27ff280d4da5050cdbd2de0d8dcb328d7cbcdb51c54e461f257898f5d689d3492e94f673bad0352fc5dccca9be4858e9";
        sha512 = "746bbec810eb499804e5188c7e6cec6881e0ba798ad06f2a9ec4ad4d749cafc20ed2bac35dbd32f1712ba4596cefa05d767b35b47e9b723854fe582506d54677";
        sha3_256 = "d6a82a3b0038a625c350d5c7ea0b649ea25657c35eb02234dad36b2a152816a5";
        sha3_384 = "826253d0f368058a297da3f7e190dd0e1c1aaa7bdd80cb9065bbeb7c3fff338a97d6a39666cb3f0952fac322e39948d2";
        sha3_512 = "117c140eb0670e51813a1495d4206d4be4a9fc67fad74f4186859cfc7eede51971606a4f84eba0ea6bb96274b108a2427a4897dd89fe54c06fa27e630a002414";
        blake2b512 = "1c0d36fc91821b67ebe68e40f37b0c016e3d96fab3351a2d5eea8aee527c149b025059bdf23fed647734727eb9ed64b5f745c27b3fb2f247c5ede851837daeea";
        blake2s256 ="8a829d2309ca0dc1aafa2f360eba449d08f15626ddf802da98444fd2071ce921";
      };
    };
  };
  rust = {
    stable = {
      channel = "stable";
      version = "1.82.0";
      llvm = "19";
      profile = "default";
      targets = ["x86_64-unknown-linux-gnu" "x86_64-unknown-linux-musl"];
    };
    nightly = {
      channel = "nightly";
      version = "2024-11-04";
      llvm = "19";
      profile = "default";
      targets = ["x86_64-unknown-linux-gnu" "x86_64-unknown-linux-musl"];
    };
  };
}
