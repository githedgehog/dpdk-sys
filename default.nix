{ rust-channel ? "stable", build-flags ? import ./nix/flags.nix
, versions ? import ./nix/versions.nix, image-tag ? "latest"
, contianer-repo ? "ghcr.io/githedgehog/dpdk-sys" }: rec {
  rust-version = versions.rust.${rust-channel};
  llvm-version = rust-version.llvm;
  llvm-overlay = self: super: rec {
    llvmPackagesVersion = "llvmPackages_${llvm-version}";
    llvmPackages = super.${llvmPackagesVersion};
  };
  rust-overlay = (import (builtins.fetchTarball
    "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"));
  toolchainPkgs = import (fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/${versions.nixpkgs.commit}.tar.gz";
    sha256 = versions.nixpkgs.hash.nar.sha256;
  }) {
    overlays = [
      (self: super: {
        dataplane-test-runner = super.callPackage ./nix/test-runner { };
      })
      llvm-overlay
      rust-overlay
    ];
  };
  project-name = "dpdk-sys";
  crossOverlay = { build-flags, crossEnv }:
    self: super: rec {
      inherit build-flags;
      buildWithFlags = flags: pkg:
        (pkg.overrideAttrs (orig: {
          CFLAGS = "${orig.CFLAGS or ""} ${flags.CFLAGS}";
          CXXFLAGS = "${orig.CXXFLAGS or ""} ${flags.CXXFLAGS}";
          LDFLAGS = "${orig.LDFLAGS or ""} ${flags.LDFLAGS}";
        }));
      customStdenv = self.stdenvAdapters.makeStaticLibraries
        (self.stdenvAdapters.useMoldLinker (if crossEnv == "musl64" then
        # TODO: It doesn't really make any sense to me that I need
        # to use pkgsMusl here.
        # In my mind that is implied by the fact that super is a
        # crossEnv.
          self.pkgsMusl.${self.llvmPackagesVersion}.libcxxStdenv
        else
          self.llvmPackages.libcxxStdenv));
      # TODO: consider LTO optimizing libcxx{,abi}
      # TODO: consider ways to LTO optimize musl (this one might be a bit tricky)
      # NOTE: libmd and libbsd customizations will cause an infinite recursion if done with normal overlay methods
      customLibmd = ((buildWithMyFlags (super.libmd)).override {
        stdenv = customStdenv;
      }).overrideAttrs (orig: {
        configureFlags = orig.configureFlags
          ++ [ "--enable-static" "--disable-shared" ];
        postFixup = (orig.postFixup or "") + ''
          rm $out/lib/*.la
        '';
      });
      customLibbsd = ((buildWithMyFlags super.libbsd).override {
        stdenv = customStdenv;
        libmd = customLibmd;
      }).overrideAttrs (orig: {
        doCheck = false;
        configureFlags = orig.configureFlags
          ++ [ "--enable-static" "--enable-shared" ];
        postFixup = (orig.postFixup or "") + ''
          rm $out/lib/*.la
        '';
      });
      buildWithMyFlags = pkg: (buildWithFlags build-flags pkg);
      optimizedBuild = pkg:
        (buildWithMyFlags (pkg.override { stdenv = customStdenv; }));
      fatLto = pkg:
        pkg.overrideAttrs
        (orig: { CFLAGS = "${orig.CFLAGS or ""} -ffat-lto-objects"; });
      rdma-core = (fatLto (optimizedBuild super.rdma-core)).overrideAttrs
        (orig: { cmakeFlags = orig.cmakeFlags ++ [ "-DENABLE_STATIC=1" ]; });
      iptables = null;
      ethtool = null;
      iproute2 = null;
      libnl = (optimizedBuild super.libnl).overrideAttrs (orig: {
        configureFlags = orig.configureFlags
          ++ [ "--enable-static" "--disable-shared" ];
        postFixup = (orig.postFixup or "") + ''
          rm $out/lib/*.la
        '';
      });
      jansson = (optimizedBuild super.jansson).overrideAttrs
        (orig: { cmakeFlags = [ "-DJANSSON_BUILD_SHARED_LIBS=OFF" ]; });
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
        libbsd = customLibbsd;
        libmd = customLibmd;
      }));
      dpdk-wrapper = (optimizedBuild (self.callPackage ./nix/dpdk-wrapper {
        inherit dpdk;
        libbsd = customLibbsd;
        bintools = self.llvmPackages.bintools;
      }));
    };

  pkgs.debug = (import toolchainPkgs.path {
    overlays = [
      (self: prev: {
        pkgsCross.gnu64 = import prev.path {
          overlays = [
            llvm-overlay
            (crossOverlay {
              build-flags = build-flags.debug;
              crossEnv = "gnu64";
            })
          ];
        };
        pkgsCross.musl64 = import prev.path {
          overlays = [
            llvm-overlay
            (crossOverlay {
              build-flags = build-flags.debug;
              crossEnv = "musl64";
            })
          ];
        };
      })
    ];
  }).pkgsCross;

  pkgs.release = (import toolchainPkgs.path {
    overlays = [
      (self: prev: {
        pkgsCross.gnu64 = import prev.path {
          overlays = [
            llvm-overlay
            (crossOverlay {
              build-flags = build-flags.release;
              crossEnv = "gnu64";
            })
          ];
        };
        pkgsCross.musl64 = import prev.path {
          overlays = [
            llvm-overlay
            (crossOverlay {
              build-flags = build-flags.release;
              crossEnv = "musl64";
            })
          ];
        };
      })
    ];
  }).pkgsCross;

  sysrootPackageListFn = crossEnv: pkgs:
    with pkgs;
    ([
      customLibbsd
      customLibbsd.dev
      customLibmd
      dpdk
      dpdk-wrapper
      libmnl
      libnftnl
      libnl.out
      libpcap
      numactl
      rdma-core
    ] ++ (if crossEnv == "gnu64" then [
      glibc
      glibc.out
      libgcc.libgcc
      glibc.dev
      glibc.static
    ] else
      [ ]) ++ (if crossEnv == "musl64" then [
        mimalloc
        musl.out
        musl.dev
      ] else
        [ ]));

  sysrootPackageList = {
    gnu64 = {
      debug = sysrootPackageListFn "gnu64" pkgs.debug.gnu64;
      release = sysrootPackageListFn "gnu64" pkgs.release.gnu64;
    };
    musl64 = {
      debug = sysrootPackageListFn "musl64" pkgs.debug.musl64;
      release = sysrootPackageListFn "musl64" pkgs.release.musl64;
    };
  };

  rust-toolchain = with rust-version;
    (toolchainPkgs.rust-bin.${channel}.${version}.${profile}.override {
      targets = targets;
    });

  compileEnvPackageList = (with toolchainPkgs; [
    cacert
    coreutils
    glibc.static # for linking the tests
    just
    llvmPackages.clang
    llvmPackages.libclang.lib
    llvmPackages.lld
    rust-toolchain
    sysroot
  ]);

  testEnvPackageList = [ ];

  devEnvPackageList = compileEnvPackageList ++ testEnvPackageList
    ++ (with toolchainPkgs; [
      bash-completion
      bashInteractive
      cacert
      coreutils
      curl
      dataplane-test-runner
      docker-client
      ethtool
      gawk
      gdb
      git
      glibc
      glibc.bin # for ldd
      gnugrep
      gnused
      gnutar
      htop
      hwloc
      iproute2
      jq
      just
      less
      libcap
      llvmPackages.bintools-unwrapped
      llvmPackages.clang
      llvmPackages.libclang.lib
      llvmPackages.lld
      llvmPackages.lldb
      nodejs_20 # for github ci
      numactl
      openssh # for git
      openssl.all # for git
      pam # for sudo
      pciutils
      stdenv.cc.cc.lib # for github ci
      strace
      sudo
      util-linux
      vim
      wget
    ]);

  env = {
    sysroot.gnu64.debug = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-debug-sysroot-gnu64";
      paths = sysrootPackageList.gnu64.debug;
    };
    sysroot.gnu64.release = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-release-sysroot-gnu64";
      paths = sysrootPackageList.gnu64.release;
    };
    sysroot.musl64.debug = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-debug-sysroot-musl64";
      paths = sysrootPackageList.musl64.debug;
    };
    sysroot.musl64.release = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-release-sysroot-musl64";
      paths = sysrootPackageList.musl64.release;
    };
    compile = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-compile";
      paths = compileEnvPackageList;
    };
    test = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-test";
      paths = testEnvPackageList;
    };
    dev = toolchainPkgs.symlinkJoin {
      name = "${project-name}-toolchain";
      paths = devEnvPackageList;
    };
  };

  sysroot = toolchainPkgs.stdenv.mkDerivation {
    name = "${project-name}-sysroot";
    src = null;
    dontUnpack = true;
    installPhase = ''
      mkdir --parent "$out/sysroot/x86_64-unknown-linux-"{musl,gnu}/{debug,release}
      cp -r "${env.sysroot.gnu64.debug}"/* "$out/sysroot/x86_64-unknown-linux-gnu/debug"
      cp -r "${env.sysroot.gnu64.release}"/* "$out/sysroot/x86_64-unknown-linux-gnu/release"
      cp -r "${env.sysroot.musl64.debug}"/* "$out/sysroot/x86_64-unknown-linux-musl/debug"
      cp -r "${env.sysroot.musl64.release}"/* "$out/sysroot/x86_64-unknown-linux-musl/release"
      ln -s /nix "$out/sysroot/x86_64-unknown-linux-gnu/debug"
      ln -s /nix "$out/sysroot/x86_64-unknown-linux-gnu/release"
      ln -s /nix "$out/sysroot/x86_64-unknown-linux-musl/debug"
      ln -s /nix "$out/sysroot/x86_64-unknown-linux-musl/release"
    '';
  };

  maxLayers = 110;

  container = {
    compile-env = toolchainPkgs.dockerTools.buildLayeredImage {
      name = "${contianer-repo}/compile-env";
      tag = "${image-tag}";
      contents = [ compileEnvPackageList ];
      inherit maxLayers;
      config = {
        Cmd = [ "/bin/sh" ];
        WorkingDir = "/";
        Env = [
          "DEV_ENV=/"
          "LD_LIBRARY_PATH=/lib"
          "LIBCLANG_PATH=/lib"
          "PATH=/bin"
          "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
          "SYSROOT=/sysroot"
        ];
      };
    };
    test-env = toolchainPkgs.dockerTools.buildLayeredImage {
      name = "${contianer-repo}/test-env";
      tag = "${image-tag}";
      contents = [ env.test ];
      config = {
        Cmd = [ "/bin/bash" ];
        WorkingDir = "/";
        Env = [
          "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
          "PATH=/bin"
          "LD_LIBRARY_PATH=/lib"
          "LIBCLANG_PATH=/lib"
        ];
      };
      inherit maxLayers;
    };
    dev-env = toolchainPkgs.dockerTools.buildLayeredImage {
      name = "${contianer-repo}/dev-env";
      tag = "${image-tag}";
      contents = [ env.dev ];
      config = {
        Cmd = [ "/bin/bash" ];
        WorkingDir = "/";
        Env = [
          "DEV_ENV=/"
          "LD_LIBRARY_PATH=/lib"
          "LIBCLANG_PATH=/lib"
          "PATH=/bin"
          "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
          "SYSROOT=/sysroot"
        ];
      };
      inherit maxLayers;
    };
  };
}
