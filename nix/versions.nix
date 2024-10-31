# WARNING: This file is generated by the update-version-pinning.sh script. Do not edit it manually.
{
  nixpkgs = {
    branch = "nixpkgs-unstable";
    commit = "2d2a9ddbe3f2c00747398f3dc9b05f7f2ebb0f53";
    commit_date = "2024-10-30T07:09:13+00:00";
    source_url = "https://github.com/NixOS/nixpkgs/archive/2d2a9ddbe3f2c00747398f3dc9b05f7f2ebb0f53.tar.gz";
    hash = {
      nix32 = {
        packed = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (packed)";
          sha256 = "00inngjgmj10siixwxxavqbqqfq65mdimrbfv9b4xqmkb4j7hqxs";
          sha512 = "012zdqp4pdfbp0s6b1k9shkk6as4wxsz9zr9cxm44vajds0ji5m5k8l1ndl8c70al109crsqj8h3718k46p1yp4k5aa68xjfmi26yib";
        };
        unpacked = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (unpacked)";
          sha256 = "1v6gpivg8mj4qapdp0y5grapnlvlw8xyh5bjahq9i50iidjr3587";
        };
      };
      tar = {
        comment = "openssl generated hashes of the actual tar.gz file obtained from github archive";
        sha256 = "ba63782459b3e24e56da6ee51a5b2d063b8c17deaa77de63d420c8fae4b33602";
        sha384 = "c38b70e528d2d1e8aa325fa82187ccef79ad7176b099e8fe5c3fdf40a6c30fa007b0ec202d6bb5ebff958564a61a5933";
        sha512 = "2b7a236275b223a35499e4fa700d99289c0191c43ab3040255e030449b0d14cd524b944037a93621b5b3947ffaba73a2959913ea34c3321adce5da2517b72f02";
        sha3_256 = "3efc694204b87832237ba694753f7b67a91f6fef43751344bb534f52f987cdf9";
        sha3_384 = "7a0ceff3bb79b6a7dfb579657f126e2fc3bc3d390a3909ce2c385ea140a875f22521ec2035b4b84b2a893faebee434c0";
        sha3_512 = "b492d9c14b0e3daddb462e0989737e42bef935b041a3fa99e380ae39af9c44991c1e132a851d83fedccfbbbb093e28cbabf9ec4bff1949fa8fbdd5b00358cb19";
        blake2b512 = "86085ea29d283706359320de98a11b36f2c70503c33c3d7fe13afd6875db209469519a473b1ea1554adda082b266afbe75ebbeac0a2702495637f6bf7cf1ca14";
        blake2s256 ="0190c488a915211282085e72a2dc165cabb408807b02cbc6fd699c41e47c5762";
      };
    };
  };
  rust = {
    stable = {
      channel = "stable";
      version = "1.82.0";
      llvm = "19";
      profile = "minimal";
      targets = ["x86_64-unknown-linux-gnu" "x86_64-unknown-linux-musl"];
    };
    nightly = {
      channel = "nightly";
      version = "2024-10-30";
      llvm = "19";
      profile = "minimal";
      targets = ["x86_64-unknown-linux-gnu" "x86_64-unknown-linux-musl"];
    };
  };
}
