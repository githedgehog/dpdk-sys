# WARNING: This file is generated by the update-version-pinning.sh script. Do not edit it manually.
{
  nixpkgs = {
    branch = "nixpkgs-unstable";
    commit = "30c9efeef01e2ad4880bff6a01a61dd99536b3c9";
    commit_date = "2024-10-29T02:50:45+00:00";
    source_url = "https://github.com/NixOS/nixpkgs/archive/30c9efeef01e2ad4880bff6a01a61dd99536b3c9.tar.gz";
    hash = {
      nix32 = {
        packed = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (packed)";
          sha256 = "14wjvrww5pgdfgqnr3jic8qf07g17zqynv3ciipa3z3wivlhn6dm";
          sha512 = "23q5q7s28j6ar3c4z2cxhcw1fkv2jygpym33wbjw42hnlabr6mayw3rqay0s8qw4vbrsv91ywky2hz87d007dsil55qfak30icfl6ja";
        };
        unpacked = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (unpacked)";
          sha256 = "0k3vfjb8hx3c9imp5c1awf3cqp6dzg8mf96wk2syjsy3k2ybh6ix";
        };
      };
      tar = {
        comment = "openssl generated hashes of the actual tar.gz file obtained from github archive";
        sha256 = "b5190be98e7cfca16e8c6c6cebf13fe11de03062518e6cf173edddc279de9293";
        sha384 = "48ceeee2a9b76c3b65cd523f692f2e24816ba732795600b087c7b81f21f64fc2ac46ec7ffc7f661f9854f62af0d6da0f";
        sha512 = "4a1aea5804632a874ba151b703403be843e127f7216d9dd7261c230dbcc27970afaac94b510b05e172f131aabfcf4bb1a70b9cc1cec4276c64652412fae08287";
        sha3_256 = "673ba28b70d749ad46ad585f1f90af3f6044b699661f385f19c5400a67debbe5";
        sha3_384 = "33284828faefeeff8a9e1835b195360866b1745235e965c2f9b3c3afb028c51235171c496b7e70dc8a1eb60eddeac1b8";
        sha3_512 = "978ab87aaca2ad05db2995c2bdea3d24ec4ceece5a0392d0638aeba7101cb1e94f1072bc73ab0a989fceab02d4780c849ea2c55fc06a3a53e6103012ed1c827e";
        blake2b512 = "b17da54bb709fe70adaa1a578bbc2b4d59fe18bb385a78be0d22db96e6b7c9791ae3059f503ae9ced1fd0fa30c2169c45c77bf12006635964021e18d51172773";
        blake2s256 ="cf58822ecf19c56a5a372eadbc920f7c869faa47f7b161a3a6338f4f42dbc2c1";
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
