{
  nixpkgs = {
    branch = "nixpkgs-unstable";
    commit = "ccc0c2126893dd20963580b6478d1a10a4512185";
    source_url = "https://github.com/NixOS/nixpkgs/archive/ccc0c2126893dd20963580b6478d1a10a4512185.tar.gz";
    hash = {
      nar = {
        comment = "nix-prefetch-url generated hash of the tar.gz file obtained from github archive";
        sha256 = "1sm9mgz970p5mbxh8ws5xdqkb6w46di58binb4lpjfzclbxhhx70";
      };
      tar = {
        comment = "openssl generated hashes of the actual tar.gz file obtained from github archive";
        sha256 = "0b67698547f6303a89f65437dc540d077d2dea81b2d97c42d0f8c47d772e339b";
        sha384 = "32564d10ec021183713cbccc88ad6455d91384b6ef61736582de6d911626b55bcdc2400b8803e2a749e64f8e3b1b9083";
        sha512 = "7d76b3ed5dde2ea44fef6a2d8efb866ddf57643f9e10e2ca2d90735ccd16db857f3a456bc321e46dbe91bba86a3cf7f0136b05e18f47b0d9e0e9810fbf3acc4d";
        sha3_256 = "2ec28d0775e75546f3dd95de095b60a2e7a0248ea2ba887cc88bb57b87930acc";
        sha3_384 = "c123b251b1d4b4697af5d1327779d3020f5c9294b782aed935c611388d032f55aa509715719c59c3944b9f36297327df";
        sha3_512 = "e3493d26e86372697ed7fbf9364badf9d2f351f661ddfa58035bc00e2c50cc8d392fafef9ecc4bd1e589ab361115da6413b06746a4f8b5701319aec7d7d8dfca";
      };
    };
  };
  rust = {
    pinned = {
      channel = "stable";
      version = "1.82.0";
      llvm = "19";
      profile = "minimal";
      targets = ["x86_64-unknown-linux-gnu" "x86_64-unknown-linux-musl"];
    };
    stable = {
      channel = "stable";
      version = "latest";
      llvm = "latest";
      profile = "minimal";
      targets = ["x86_64-unknown-linux-gnu" "x86_64-unknown-linux-musl"];
    };
    beta = {
      channel = "beta";
      version = "latest";
      llvm = "latest";
      profile = "minimal";
      targets = ["x86_64-unknown-linux-gnu" "x86_64-unknown-linux-musl"];
    };
    nightly = {
      channel = "nightly";
      version = "latest";
      llvm = "latest";
      profile = "minimal";
      targets = ["x86_64-unknown-linux-gnu" "x86_64-unknown-linux-musl"];
    };
  };
}
