# WARNING: This file is generated by the bump.sh script. Do not edit it manually.
{
  nixpkgs = {
    branch = "nixpkgs-unstable";
    commit = "b2243f41e860ac85c0b446eadc6930359b294e79";
    commit_date = "2025-02-09T21:53:45+00:00";
    source_url = "https://github.com/NixOS/nixpkgs/archive/b2243f41e860ac85c0b446eadc6930359b294e79.tar.gz";
    hash = {
      nix32 = {
        packed = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (packed)";
          sha256 = "0fd7kslxwpx7gy4vb4588ixq6iwqs69l39409jv8iff16zf8j5w1";
          sha512 = "33nwiprddjf39zpmvfp4s3km74rvssnz4bzkk6mbda3n69pmnzld2bnwplr5czqz9jckgybw3zifainay0b8hj3ddsf4vwri0565868";
        };
        unpacked = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (unpacked)";
          sha256 = "0bhibarcx56j1szd40ygv1nm78kap3yr4s24p5cv1kdiy4hsb21k";
        };
      };
      tar = {
        comment = "openssl generated hashes of the actual tar.gz file obtained from github archive";
        sha256 = "811789dc37c1b988b64c80a44193d19847837b44a890b5897fa75fdea99ea739";
        sha384 = "f5d6092fdb46e0925cefa7e0310a770c443218de114995c1a02a2e9bc3eb5ef1b54e50cb43875bfd134296e9c82a7e3e";
        sha512 = "c8a0620a88996fe2746b4342b48057362a17ffe0cbbfc964faf8b392e9e5768946bfad37193b545bd5ccf917f956eb9dc9a9736872ddaef7a7e1646bf9466ec7";
        sha3_256 = "fa024359135b76044415da29d75eaf58ad554596a8392231046dd63e27cf518f";
        sha3_384 = "a9769380c432b87d9ee6cf3e75a7ab56f65845b7e485b9cd6d560fac80602812d77a80d79956450d43efe73662f355d8";
        sha3_512 = "f10bc0fe890a80f85064e69b265e2bf548747efdc1fcba5635d44734b92893d65b55de46910a373e744fd7cbaa951648600c88b311ca6f7d36fc6244a5bb8326";
        blake2b512 = "af5d25ee0582c72660aa6a55142ebfed8308cbbb53fd5b66548800dc5b72ccf9de7f0a4ea69f0598e38cb04531e1e7f1aa00b49b9a5e541ad972abe7a4edcce6";
        blake2s256 = "ae6a4fd1aae7233112eb2478311b7b969d50175bdd5d8b99c87f791358a562f9";
      };
    };
  };
  rust = {
    stable = {
      channel = "stable";
      version = "1.84.1";
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
