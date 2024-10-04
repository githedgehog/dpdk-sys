{
  llvm-version ? "18",
  build-flags ? import ./nix/flags.nix,
  versions ? import ./nix/versions.nix,
}: rec {
  toolchainPkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${versions.nixpkgs.commit}.tar.gz";
    sha256 = versions.nixpkgs.hash.nar.sha256;
  }) {};
  project-name = "dpdk-sys";
  crossOverlay = { build-flags, crossEnv }: self: super: rec {
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

  pkgsCrossDebug = (import toolchainPkgs.path {
    overlays = [
      (self: prev: {
        pkgsCross.gnu64 = import prev.path {
          overlays = [(crossOverlay { build-flags = build-flags.debug; crossEnv="gnu64"; })];
        };
        pkgsCross.musl64 = import prev.path {
          overlays = [(crossOverlay { build-flags = build-flags.debug; crossEnv="musl64"; })];
        };
      })
    ];
  }).pkgsCross;

  pkgsCrossRelease = (import toolchainPkgs.path {
    overlays = [
      (self: prev: {
        pkgsCross.gnu64 = import prev.path {
          overlays = [(crossOverlay { build-flags = build-flags.release; crossEnv="gnu64"; })];
        };
        pkgsCross.musl64 = import prev.path {
          overlays = [(crossOverlay { build-flags = build-flags.release; crossEnv="musl64"; })];
        };
      })
    ];
  }).pkgsCross;

  sysrootPackageListFn = crossEnv: pkgs: with pkgs; (
    [
      customLibbsd
      customLibmd
      dpdk
      dpdk-wrapper
      libbsd.dev
      libmnl
      libnftnl
      libnl.out
      libpcap
      linuxHeaders
      llvmPackages.libclang.dev
      llvmPackages.libclang.lib
      llvmPackages.libcxx
      llvmPackages.libcxx.dev
      llvmPackages.libcxxClang
      numactl
      rdma-core
    ] ++
    (if crossEnv == "gnu64" then [ glibc glibc.out libgcc.libgcc glibc.dev ] else [])
    ++
    (if crossEnv == "musl64" then [ musl.out musl.dev ] else [])
  );

  sysrootPackageList = {
    debug = {
      gnu64 = sysrootPackageListFn "gnu64" pkgsCrossDebug.gnu64;
      musl64 = sysrootPackageListFn "musl64" pkgsCrossDebug.musl64;
    };
    release = {
      gnu64 = sysrootPackageListFn "gnu64" pkgsCrossRelease.gnu64;
      musl64 = sysrootPackageListFn "musl64" pkgsCrossRelease.musl64;
    };
  };

  toolchainPackageList = with toolchainPkgs; [
    bash-completion
    bashInteractive
    cacert
    coreutils
    glibc.dev
    llvmPackages.clang-unwrapped
    llvmPackages.compiler-rt
    llvmPackages.compiler-rt.dev
    llvmPackages.libclang.lib
    llvmPackages.libcxx
    llvmPackages.libllvm
    llvmPackages.libllvm.lib
    llvmPackages.lld
    llvmPackages.llvm
    mold
    nix
    rustup
  ];

  re-link = toolchainPkgs.writeShellApplication {
    name = "re-link";
    runtimeInputs = with toolchainPkgs; [ coreutils ];
    text = ''
      new_target="$(realpath -s --relative-to="$1" "$(readlink "$1")")"
      rm "$1"
      ln -rs "$new_target" "$1"
    '';
  };

  de-link = toolchainPkgs.writeShellApplication {
    name = "de-link";
    runtimeInputs = with toolchainPkgs; [ coreutils ];
    text = ''
      target="$(readlink --canonicalize-existing "$1")"
      cp -r "$target" "$2/$1"
    '';
  };

  env = {
    sysroot.gnu64.debug = toolchainPkgs.buildEnv {
      name = "${project-name}-debug-sysroot-gnu64";
      paths = sysrootPackageList.debug.gnu64;
      pathsToLink = [ "/" ];
    };
    sysroot.musl64.debug = toolchainPkgs.buildEnv {
      name = "${project-name}-debug-sysroot-musl64";
      paths = sysrootPackageList.debug.musl64;
      pathsToLink = [ "/" ];
    };
    sysroot.gnu64.release = toolchainPkgs.buildEnv {
      name = "${project-name}-release-sysroot-gnu64";
      paths = sysrootPackageList.release.gnu64;
      pathsToLink = [ "/" ];
    };
    sysroot.musl64.release = toolchainPkgs.buildEnv {
      name = "${project-name}-release-sysroot-musl64";
      paths = sysrootPackageList.release.musl64;
      pathsToLink = [ "/" ];
    };
    toolchain = toolchainPkgs.buildEnv {
      name = "${project-name}-toolchain";
      paths = toolchainPackageList;
      pathsToLink = [ "/" ];
    };
  };

  sysroot = toolchainPkgs.stdenv.mkDerivation {
    name = "${project-name}-sysroot";
    src = env.sysroot.gnu64.debug;
    buildPhase = ''
      mkdir -p $out/x86_64-unknown-linux-{musl,gnu}
      ln -s ${env.sysroot.gnu64.debug} $out/x86_64-unknown-linux-gnu/debug
      ln -s ${env.sysroot.gnu64.release} $out/x86_64-unknown-linux-gnu/release
      ln -s ${env.sysroot.musl64.debug} $out/x86_64-unknown-linux-musl/debug
      ln -s ${env.sysroot.musl64.release} $out/x86_64-unknown-linux-musl/release
    '';
  };

  build = toolchainPkgs.stdenv.mkDerivation {
    name = "${project-name}-dir";
    src = env.toolchain;
    nativeBuildInputs = [ toolchainPkgs.rsync ];
    buildPhase = ''
      mkdir -p $out
      cp -r ${env.toolchain}/* $out/
      mkdir $out/sysroot
      cp -r ${sysroot}/* $out/sysroot/
      mkdir $out/tmp
    '';
  };

  container = {
    dev-env = toolchainPkgs.dockerTools.buildLayeredImage {
      name = "ghcr.io/githedgehog/dpdk-sys/dev-env";
      tag = "llvm${llvm-version}";
      contents = [ build ];
      config = {
        Cmd = [ "/bin/bash" ];
        WorkingDir = "/";
        Env = [
          "LD_LIBRARY_PATH=/lib"
        ];
      };
      maxLayers = 120;
#      enableFakechroot = true;
#      fakeRootCommands = let re-link-sh=(toolchainPkgs.lib.getExe re-link); in ''
#        find /bin -type l -lname '/nix/*' -exec ${re-link-sh} {} \;
#        find /lib -type l -lname '/nix/*' -exec ${re-link-sh} {} \;
#        find /include -type l -lname '/nix/*' -exec ${re-link-sh} {} \;
#        ${re-link-sh} /sysroot/x86_64-unknown-linux-gnu/debug
#        ${re-link-sh} /sysroot/x86_64-unknown-linux-gnu/release
#        ${re-link-sh} /sysroot/x86_64-unknown-linux-musl/debug
#        ${re-link-sh} /sysroot/x86_64-unknown-linux-musl/release
#      '';
    };
  };
}
