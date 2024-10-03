{
  llvm-version ? "18",
  profile ? "debug",
  crossEnv ? "gnu64",
  build-flags-file ? ./nix/flags.nix,
  versions ? import ./nix/versions.nix,
}: rec {
  toolchainPkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${versions.nix.commit}.tar.gz";
    sha256 = versions.nix.hash.nar.sha256;
  }) {};
  project-name = "dpdk-sys";
  build-flags = (import build-flags-file).${profile};
  crossOverlay = crossEnv: self: super: rec {
    inherit build-flags;
    buildWithFlags = flags: pkg: (pkg.overrideAttrs (orig: {
      CFLAGS = "${orig.CFLAGS or ""} ${flags.CFLAGS}";
      CXXFLAGS = "${orig.CXXFLAGS or ""} ${flags.CXXFLAGS}";
      LDFLAGS = "${orig.LDFLAGS or ""} ${flags.LDFLAGS}";
    }));
    llvmPackagesVersion = "llvmPackages_${llvm-version}";
    llvmPackages = super.${llvmPackagesVersion};
    customStdenv = self.stdenvAdapters.makeStaticLibraries (
      self.stdenvAdapters.useMoldLinker (
        if crossEnv == "musl64" then
          self.pkgsMusl.${llvmPackagesVersion}.libcxxStdenv
        else if crossEnv == "gnu64" then
          llvmPackages.stdenv
        else
          llvmPackages.stdenv
      )
    );
    # NOTE: libmd and libbsd customizations will cause an infinite recursion if done with normal overlay methods
    customLibmd = ((buildWithMyFlags (super.libmd)).override { stdenv = customStdenv; }).overrideAttrs (orig: {
      configureFlags = orig.configureFlags ++ ["--enable-static" "--disable-shared"];
      postFixup = (orig.postFixup or "") + ''
        rm $out/lib/*.la
      '';
    });
    customLibbsd = ((buildWithMyFlags super.libbsd).override {
      stdenv = customStdenv; libmd = customLibmd;
    }).overrideAttrs (orig: {
      doCheck = false;
      configureFlags = orig.configureFlags ++ ["--enable-static" "--enable-shared"];
      postFixup = (orig.postFixup or "") + ''
        rm $out/lib/*.la
      '';
    });
    buildWithMyFlags = pkg: (buildWithFlags build-flags pkg);
    optimizedBuild = pkg: (buildWithMyFlags (pkg.override {
      stdenv = customStdenv;
    }));
    fatLto = pkg: pkg.overrideAttrs (orig: {
      CFLAGS = "${orig.CFLAGS or ""} -ffat-lto-objects";
    });
    rdma-core = (fatLto (optimizedBuild super.rdma-core)).overrideAttrs (orig: {
      cmakeFlags = orig.cmakeFlags ++ [
        "-DENABLE_STATIC=1"
      ];
    });
    iptables = null;
    ethtool = null;
    iproute2 = null;
    libnl = (optimizedBuild super.libnl).overrideAttrs (orig: {
      configureFlags = orig.configureFlags ++ [
        "--enable-static"
        "--disable-shared"
      ];
      postFixup = (orig.postFixup or "") + ''
        rm $out/lib/*.la
      '';
    });
    jansson = (optimizedBuild super.jansson).overrideAttrs (orig: {
      cmakeFlags = [
        "-DJANSSON_BUILD_SHARED_LIBS=OFF"
      ];
    });
    libmnl = optimizedBuild super.libmnl;
    libnetfilter_conntrack = optimizedBuild super.libnetfilter_conntrack;
    libnftnl = optimizedBuild super.libnftnl;
    libpcap = optimizedBuild super.libpcap;
    numactl = (optimizedBuild super.numactl).overrideAttrs (orig: {
      outputs = super.lib.lists.remove "man" orig.outputs;
      configurePhase = ''
        set -euxo pipefail;
        ./configure \
          --prefix=$out \
          --libdir=$out/lib \
          --includedir=$out/include \
          --enable-static \
          --enable-shared;
      '';
      buildPhase = ''
        set -euxo pipefail;
        make;
        rm ./.libs/*.la;
      '';
    });
    dpdk = (optimizedBuild (self.callPackage ./nix/dpdk {
      libbsd = customLibbsd; libmd = customLibmd;
    }));
    dpdk-wrapper = (optimizedBuild (self.callPackage ./nix/dpdk-wrapper {
      libbsd = customLibbsd; inherit dpdk;
    }));
  };

  pkgsCross = (import toolchainPkgs.path {
    overlays = [
      (self: prev: {
        pkgsCross.gnu64 = import prev.path {
          overlays = [(crossOverlay "gnu64")];
        };
        pkgsCross.musl64 = import prev.path {
          overlays = [(crossOverlay "musl64")];
        };
      })
    ];
  }).pkgsCross;

  sysrootPackageListFn = pkgs: with pkgs; (
    [
      dpdk
      dpdk-wrapper
      customLibbsd.dev
      customLibmd
      libmnl
      libnftnl
      libnl.out
      libpcap
      numactl
      rdma-core
    ] ++
    (if customStdenv.targetPlatform.isGnu then [ glibc.out libgcc.libgcc ] else [])
    ++
    (if customStdenv.targetPlatform.isMusl then [ musl.out ] else [])
  );

  sysrootPackageList = {
    gnu64 = sysrootPackageListFn pkgsCross.gnu64;
    musl64 = sysrootPackageListFn pkgsCross.musl64;
  };


  toolchainPackageList = (with toolchainPkgs; let
    # mdbook-citeproc = import ./nix/mdbook-citeproc.nix ({
    #   stdenv = pkgs.stdenv;
    #   inherit lib fetchFromGitHub rustPlatform CoreServices;
    # });
    # mdbook-alerts = import ./nix/mdbook-alerts.nix ({
    #   stdenv = pkgs.stdenv;
    #   inherit lib fetchFromGitHub rustPlatform CoreServices;
    # });
    in [
      # mdbook-alerts
      # mdbook-citeproc
      bash-completion
      bashInteractive
      cacert
      coreutils
      docker
      git
      just
      llvmPackages.clang
      llvmPackages.compiler-rt
      llvmPackages.libclang.lib
      llvmPackages.libcxx
      llvmPackages.lld
      llvmPackages.llvm
      mdbook
      mdbook-admonish
      mdbook-katex
      mdbook-mermaid
      mdbook-plantuml
      mold
      nix
      pandoc # needed for mdbook-citeproc to work (runtime exe dep)
      plantuml # needed for mdbook-plantuml to work (runtime exe dep)
      rustup
    ]
  );


  env = {

    sysroot.gnu64 = toolchainPkgs.buildEnv {
      name = "${project-name}-sysroot-gnu64";
      paths = sysrootPackageList.gnu64;
      pathsToLink = [ "/include" "/lib" ];
    };

    sysroot.musl64 = toolchainPkgs.buildEnv {
      name = "${project-name}-sysroot-musl64";
      paths = sysrootPackageList.musl64;
      pathsToLink = [ "/include" "/lib" ];
    };


    toolchain = toolchainPkgs.buildEnv {
      name = "${project-name}-toolchain";
      paths = toolchainPackageList;
      pathsToLink = [ "/" ];
    };
  };

  sysroot = toolchainPkgs.stdenv.mkDerivation {
    name = "${project-name}-sysroot";
    src = ./.;
    buildPhase = ''
      mkdir -p $out;
      ln -s ${env.sysroot.musl64} $out/x86_64-unknown-linux-musl;
      ln -s ${env.sysroot.gnu64} $out/x86_64-unknown-linux-gnu;
    '';
  };

  build = toolchainPkgs.stdenv.mkDerivation {
    name = "${project-name}-dir";
    src = env.toolchain;
    buildPhase = ''
      mkdir -p $out
      cp -r ${env.toolchain}/* $out/
      mkdir -p $out/sysroot
      ln -s ${env.sysroot.musl64} $out/sysroot/x86_64-unknown-linux-musl;
      ln -s ${env.sysroot.gnu64} $out/sysroot/x86_64-unknown-linux-gnu;
      mkdir $out/tmp
    '';
  };

  dockerEnvs = [
    "LD_LIBRARY_PATH=/lib"
  ];

  container = {
    toolchain = toolchainPkgs.dockerTools.buildLayeredImage {
      name = "ghcr.io/githedgehog/dpdk-sys/toolchain";
      tag = "${profile}-llvm${llvm-version}";
      contents = [ env.toolchain ];
      maxLayers = 120;
      config = {
        Cmd = [ "/bin/bash" ];
        WorkingDir = "/";
        Env = dockerEnvs;
      };

    };
    dev-env = toolchainPkgs.dockerTools.buildLayeredImage {
      name = "ghcr.io/githedgehog/dpdk-sys/dev-env";
      tag = "${profile}-llvm${llvm-version}";
      contents = [ build ];
      config = {
        Cmd = [ "/bin/bash" ];
        WorkingDir = "/";
        Env = dockerEnvs;
      };
      maxLayers = 120;
    };
  };
}
