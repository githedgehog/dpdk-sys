# WARNING: This file is generated by the bump.sh script. Do not edit it manually.
{
  nixpkgs = {
    branch = "nixpkgs-unstable";
    commit = "250b695f41e0e2f5afbf15c6b12480de1fe0001b";
    commit_date = "2025-04-05T00:48:53+00:00";
    source_url = "https://github.com/NixOS/nixpkgs/archive/250b695f41e0e2f5afbf15c6b12480de1fe0001b.tar.gz";
    hash = {
      nix32 = {
        packed = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (packed)";
          sha256 = "0k1nlj4gj0xwnv4gfng0jv2mj0nq2k10nyyswya2gzwjnyp8xxx5";
          sha512 = "19mvmmkf2man7zh16yph8phyf9qrljlmcyr23xwdyvx850426amxnwzw9avsmkcvcmg1q2xvr1yggshf6lzljbx9i6pns7fv0n00d46";
        };
        unpacked = {
          comment = "nix-prefetch-url generated hash of the nix archive file obtained from github archive (unpacked)";
          sha256 = "0nb4rg1riw29xbv8rpgada712d1xivbhgc3ri03fd3964miz5c3n";
        };
      };
      tar = {
        comment = "openssl generated hashes of the actual tar.gz file obtained from github archive";
        sha256 = "a5f78eaeb792ff2794e7da7b0bc214d80259c596e059f7c8b6bc03f988a4364c";
        sha384 = "9aab4dfc35f663209b36f04bae54705d108ff717922114a789aac7fceed943b9539a2c2f9f458c2b5e665ff4e1b86586";
        sha512 = "8634002cd8ee687b4d4c7d49faa97150bfe743de5de0f02adb6c56bd55e29fdb5e95110414d4b76fbc0f913dab54d28c93f3f02278bd09f01fabaa70b3d65d53";
        sha3_256 = "7fdd713204352fc05ef6bd1c61070fafa1454279753376fce5ded36c6e0a07cd";
        sha3_384 = "f6cb73fb6938bdc84c94f8c7a4e09f8f35d5e1ac8a2a27eefb184b71b097a918fe4f90860d829cb7a39e065a4770f045";
        sha3_512 = "7b785cc2df385bbbbdce81f8165667460647a73e5326c3dada0e686e95e7140d62381638ac0667c6b81f3ff160605db8bbb0f1187d4fe303f5b05b4b2614a99d";
        blake2b512 = "a2a3afc3986dd049a038565b188e05d6d7f4630e7cad060c96a47e954f9378aae55ced96c9f7c60cc97d61c449146d5eaf04592e28f3b722c2f13522e4e0599c";
        blake2s256 = "84bccf36191b8f1846f69edbe046478419fdec98b5842778e491eefeb9376293";
      };
    };
  };
  rust = {
    beta = {
      channel = "beta";
      version = "latest";
      llvm = "20";
      profile = "default";
      targets = [
        "x86_64-unknown-linux-gnu"
      ];
      extensions = [
        "cargo"
        "clippy"
        "rust-analyzer"
        "rust-docs"
        "rust-src"
        "rust-std"
        "rustfmt"
      ];
    };
  };
}
