# WARNING: This file is generated by the bump.sh script. Do not edit it manually.
{
  nixpkgs = {
    branch = "nixpkgs-unstable";
    commit = "85f7e662eda4fa3a995556527c87b2524b691933";
    commit_date = "2024-11-07T05:50:23+00:00";
    source_url = "https://github.com/NixOS/nixpkgs/archive/85f7e662eda4fa3a995556527c87b2524b691933.tar.gz";
    hash = {
      nix32 = {
        packed = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (packed)";
          sha256 = "00nv64w1bh0zw3m04as3pgvqvq2r7y24yzxv4k4z5rkrb1lkch5w";
          sha512 = "2995aaz4sjcwwn3rjh4i43pgw9yn5myfa9s4cd0rfhszzjhj9s6fnimrk714v696ng7hn4j6s0208vmnhniq792mva7zdm4bq7qxs54";
        };
        unpacked = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (unpacked)";
          sha256 = "1p8qam6pixcin63wai3y55bcyfi1i8525s1hh17177cqchh1j117";
        };
      };
      tar = {
        comment = "openssl generated hashes of the actual tar.gz file obtained from github archive";
        sha256 = "bc4036695879e6f2c924bb7f4f843f59e08df7bb432b02eae01fc0153831db02";
        sha384 = "446eba7dd27f0d0087ce5c91d34b55eb0de629476c815667b21925aca6dbb2fbc5d29bb15ad16dbe4522d8f418bc5f45";
        sha512 = "a4e88e0f5ea4b67fd4ae221d1c2db475232080369258789e35c96c12cecc355a67749250feafa1cba031a29372be16eb137f779048a0ccc372cea4265fa99292";
        sha3_256 = "2556485e2fc9445c77546543713c30102a2683b8dc2fdd9b3afcff421f1a6e47";
        sha3_384 = "63883603a17afecd2ec0b20408da94cb27af3514cbdcbc48a7b2beb3b771c851a4a14059fe774a689bc523e44506c8ac";
        sha3_512 = "0651c77a7c59770b115e8e97707573ea50d41743d87b7e01b925f6e9c4faea1cbdfaa2282e5a5bc5a961c20b58306eed8136693de3ff114f80f04d65256bef41";
        blake2b512 = "6a8da071b1ff3cb8623ec3f9eada748895080d6a0529722835ddd03f92a18e403eff2bec6c8c3a6364d841dc1abbd28db59b7fb40b07577d4e2661bbeb985626";
        blake2s256 ="52fc0e4e4809ea9efeaacfc75240364adbc55424c5826859eddbd51db2c1fb90";
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
      version = "2024-11-07";
      llvm = "19";
      profile = "default";
      targets = ["x86_64-unknown-linux-gnu" "x86_64-unknown-linux-musl"];
    };
  };
}
