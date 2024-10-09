{
  nixpkgs = {
    branch = "nixpkgs-unstable";
    commit = "1366d1af8f58325602280e43ed6233849fb92216";
    source_url = "https://github.com/NixOS/nixpkgs/archive/1366d1af8f58325602280e43ed6233849fb92216.tar.gz";
    hash = {
      nar = {
        comment = "nix-prefetch-url generated hash of the tar.gz file obtained from github archive";
        sha256 = "03cs4rxzxs54wk0d65zasdsm4fn8yx3cj6rls1nkl62lf38pfklj";
      };
      tar = {
        comment = "openssl generated hashes of the actual tar.gz file obtained from github archive";
        sha256 = "e24f7c09f8bfb101c7b3c3c80880b0093159da219fe712a366158db78a17ed91";
        sha384 = "b4c40cba6bfbb57e1312f2a0b3b715a364741c19d99e965905c14e5504cdf518928569cde564e08d855b62f3c9556e4a";
        sha512 = "b9e3d198fdbcca00ed7061407dfb222e1cd2d2b38453503135de9eee2df803b74f01dbe2c793a643c3988c50ba8c6891ff5d4240e1eaeed801780173311a24ab";
        sha3_256 = "d75f70a3b032191c0b76e2316e89461fcf057de88f14a7cdc0949e06df3bec65";
        sha3_384 = "ca0df58feebf6b29873abcff1f0e014a1bde2fcc6e4ea37b64246921a2b8dd1473d9fea7fd5f8580cbd3ddd986d21e57";
        sha3_512 = "112e457a1a1a8248dc36dae11695f0ca48225cdcdbce9bf4ac5a75a0f5184cf7c03d0ec8636c0fa44df7b8dfbabc3e7973c85c99aea8578bec4577d90c98fdb9";
      };
    };
  };
}
