# WARNING: This file is generated by the bump.sh script. Do not edit it manually.
{
  nixpkgs = {
    branch = "nixpkgs-unstable";
    commit = "4703b8d2c708e13a8cab03d865f90973536dcdf5";
    commit_date = "2024-11-30T03:39:21+00:00";
    source_url = "https://github.com/NixOS/nixpkgs/archive/4703b8d2c708e13a8cab03d865f90973536dcdf5.tar.gz";
    hash = {
      nix32 = {
        packed = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (packed)";
          sha256 = "1va72b7xdpszygc3sqh0h321vn20vpgdynfk1siwg57dykgsjyyg";
          sha512 = "29s8klm833vamkvn9sh1ssii5hw1vbam6vkv81b4bvv6qxgwp84kndbb2d2m9wg3g0v25a5w8a4dzc48wvpqawlcmb7qwm02770p52p";
        };
        unpacked = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (unpacked)";
          sha256 = "1khdq4ycg0wcvbf6qhgf76h97y67mw197977ghmsfshmw97mi6h7";
        };
      };
      tar = {
        comment = "openssl generated hashes of the actual tar.gz file obtained from github archive";
        sha256 = "cf7ba9dff4ed94c7a30ed359dfdedd40d81dc48000623dd8f35fdfd6cf1247ed";
        sha384 = "91ef28c3938d41b19a75307faa845ea3c0676476ed994bcd10724d4e25c14d236450c1d01bf5df326661eca2eaabc971";
        sha512 = "57940bce11a0727c5665942b7c374784fd4614e24515b1c11b8fa72a9a58abd949d0e5af63b3f7222ba03db7a96aedc0618951eb0075b27b56b5c740954ea493";
        sha3_256 = "672d383d7c0508538c4190a82b20f9fc0ba22f274ec9c3226915c412547d10b3";
        sha3_384 = "1b4d4f07b7ace08f033774fdd0c1ba13fd2d8f9b080b65cf7ae2218b67e3f6bef96c834d10861d59b5660c3b1ac2bfa7";
        sha3_512 = "75e01b6b8a7f13e0f720a2a6c4f9d61c8d44556fa1a9048a65da04cf02e25f250463584902b621be04658152a97cf2f0f348c53b52d7efa6366c533f0cc26a30";
        blake2b512 = "afd1fe765ca3fa7d8be547480ffc53cf798a4f59a58b065201b00389143bc93cce091cb93cca2a372ff67a0b6261794c794ace23aa43a556db083dc6ed9fe4fc";
        blake2s256 = "0e64fe9146a0bf785af5ebc1e71e0055bb7fbca6d27ffe8788ffe4f3b994743c";
      };
    };
  };
  rust = {
    stable = {
      channel = "stable";
      version = "1.83.0";
      llvm = "19";
      profile = "default";
      targets = [
        "x86_64-unknown-linux-gnu"
        "x86_64-unknown-linux-musl"
      ];
      extensions = [
        "cargo"
        "clippy"
        "rust-std"
      ];
    };
  };
}
