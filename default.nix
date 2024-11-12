{ rust-channel ? "stable", build-flags ? import ./nix/flags.nix
, versions ? import ./nix/versions.nix, image-tag ? "latest"
, contianer-repo ? "ghcr.io/githedgehog/dpdk-sys" }: rec {
  rust-version = versions.rust.${rust-channel};
  llvm-version = rust-version.llvm;
  llvm-overlay = self: super: rec {
    llvmPackages = super.${llvmPackagesVersion};
    llvmPackagesVersion = "llvmPackages_${llvm-version}";
  };
  rust-overlay = (import (builtins.fetchTarball
    "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"));
  toolchainPkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${versions.nixpkgs.commit}.tar.gz";
    sha256 = versions.nixpkgs.hash.nix32.unpacked.sha256;
  }) {
    overlays = [
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
      # TODO: consider ways to LTO optimize musl (this one might be a bit tricky)
      buildWithMyFlags = pkg: (buildWithFlags build-flags pkg);
      optimizedBuild = pkg:
        (buildWithMyFlags (pkg.override { stdenv = customStdenv; })).overrideAttrs {
          withDoc = false;
          doCheck = false;
        };
      customLibmd = (optimizedBuild super.libmd).overrideAttrs (orig: {
        configureFlags = orig.configureFlags
          ++ [ "--enable-static" "--disable-shared" ];
        postFixup = (orig.postFixup or "") + ''
          rm $out/lib/*.la
        '';
      });
      customLibbsd = ((optimizedBuild super.libbsd).override {
        libmd = customLibmd;
      }).overrideAttrs (orig: {
        doCheck = false;
        configureFlags = orig.configureFlags
          ++ [ "--enable-static" "--enable-shared" ];
        postFixup = (orig.postFixup or "") + ''
          rm $out/lib/*.la
        '';
      });
      fatLto = pkg:
        pkg.overrideAttrs
        (orig: { CFLAGS = "${orig.CFLAGS or ""} -ffat-lto-objects"; });

      at-spi2-atk = null; # no users in container
      at-spi2-core = null; # no users in container
      dbus = super.dbus.override { enableSystemd = false; };
      libusb = null;
      libusb1 = null;
      gtk3 = null;
      tinysparql = null;
      systemd = null;
      systemdLibs = null;
      systemdMinimal = null;
      util-linux = super.util-linux.override { systemdSupport = false; };
      rdma-core = (fatLto (optimizedBuild super.rdma-core)).overrideAttrs
        (orig: {
          outputs = [ "out" "dev" ];
          perl = null;
          cmakeFlags = orig.cmakeFlags ++ [
            "-DENABLE_STATIC=1"
            "-DNO_PYVERBS=1"
            "-DNO_MAN_PAGES=1"
            "-DIOCTL_MODE=write"
            "-DNO_COMPAT_SYMS=1"
          ];
          patches = (orig.patches or []) ++ (if crossEnv == "musl64" then [] else [(super.fetchpatch {
            # you need to patch rdma-core to build with clang + glibc 2.40.x since glibc 2.40 has improved fortifying
            # this function with clang.
            name = "fix-for-glibc-2.40.x";
            url = "https://git.openembedded.org/meta-openembedded/plain/meta-networking/recipes-support/rdma-core/rdma-core/0001-librdmacm-Use-overloadable-function-attribute-with-c.patch?id=69769ff44ed0572a7b3c769ce3c36f28fff359d1";
            sha256 = "sha256-k+T8vSkvljksJabSJ/WRCXTYfbINcW1n0oDQrvFXXGM=";
          })]);
        });
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

  pkgs.dev = (import toolchainPkgs.path {
    overlays = [
      (self: prev: {
        pkgsCross.gnu64 = import prev.path {
          overlays = [
            llvm-overlay
            (crossOverlay {
              build-flags = build-flags.dev;
              crossEnv = "gnu64";
            })
          ];
        };
        pkgsCross.musl64 = import prev.path {
          overlays = [
            llvm-overlay
            (crossOverlay {
              build-flags = build-flags.dev;
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

  sysrootPackageListFn = libc: pkgs:
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
    ] ++ (if libc == "gnu64" then [
      glibc
      glibc.out
      libgcc.libgcc
      glibc.dev
      glibc.static
    ] else
      [ ]) ++ (if libc == "musl64" then [
        musl.out
        musl.dev
      ] else
        [ ]));

  sysrootPackageList = {
    gnu64 = {
      dev = sysrootPackageListFn "gnu64" pkgs.dev.gnu64;
      release = sysrootPackageListFn "gnu64" pkgs.release.gnu64;
    };
    musl64 = {
      dev = sysrootPackageListFn "musl64" pkgs.dev.musl64;
      release = sysrootPackageListFn "musl64" pkgs.release.musl64;
    };
  };

  rust-toolchain = with rust-version;
    (toolchainPkgs.rust-bin.${channel}.${version}.${profile}.override {
      inherit targets extensions;
    });

  compileEnvPackageList = with toolchainPkgs; [
    (toolchainPkgs.callPackage ./nix/shell-fixup {})
    bash-completion
    bashInteractive
    cacert
    cargo-nextest
    coreutils
    just
    libcap # for test runner
    llvmPackages.clang
    llvmPackages.libclang.lib
    llvmPackages.lld
    rust-toolchain
    sudo # for test runner
  ];

  docEnvPackageList = [tmpdir] ++ (with toolchainPkgs; [
    (callPackage ./nix/mdbook-alerts {})
    (callPackage ./nix/plantuml-wrapper {})
    bash
    coreutils
    graphviz # needed for mdbook-plantuml to work (runtime exe dep)
    mdbook
    mdbook-katex
    mdbook-mermaid
    mdbook-plantuml
    openjdk # needed for mdbook-plantuml to work (runtime exe dep)
    plantuml # needed for mdbook-plantuml to work (runtime exe dep)
  ]);

  env = {
    sysroot.gnu64.dev = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-dev-sysroot-gnu64";
      paths = sysrootPackageListFn "gnu64" pkgs.dev.gnu64;
    };
    sysroot.gnu64.release = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-release-sysroot-gnu64";
      paths = sysrootPackageListFn "gnu64" pkgs.release.gnu64;
    };
    sysroot.musl64.dev = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-dev-sysroot-musl64";
      paths = sysrootPackageListFn "musl64" pkgs.dev.musl64;
    };
    sysroot.musl64.release = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-release-sysroot-musl64";
      paths = sysrootPackageListFn "musl64" pkgs.release.musl64;
    };
    compile = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-compile";
      paths = compileEnvPackageList;
    };
    doc = toolchainPkgs.symlinkJoin {
      name = "${project-name}-doc";
      paths = docEnvPackageList;
    };
  };

  sysrootFn = libc: profile: let libcShortName = (if libc == "gnu64" then "gnu" else "musl"); in
    toolchainPkgs.stdenv.mkDerivation {
    name = "${project-name}-sysroot.${libc}.${profile}";
    nativeBuildInputs = [toolchainPkgs.rsync];
    src = null;
    dontUnpack = true;
    installPhase = ''
      mkdir --parent "$out/sysroot/x86_64-unknown-linux-${libcShortName}/${profile}/"{lib,include}
      rsync -rLhP \
        "${env.sysroot.${libc}.${profile}}/lib/" \
        "$out/sysroot/x86_64-unknown-linux-${libcShortName}/${profile}/lib/"
      rsync -rLhP \
        "${env.sysroot.${libc}.${profile}}/include/" \
        "$out/sysroot/x86_64-unknown-linux-${libcShortName}/${profile}/include/"
    '';
    # Rust can't decided if the profile is called dev or debug so we need a fixup
    postFixup = (if profile == "dev" then ''
      ln -s dev $out/sysroot/x86_64-unknown-linux-${libcShortName}/debug
    '' else "") + (if libc == "gnu64" then ''
      export lib="$out/sysroot/x86_64-unknown-linux-${libcShortName}/${profile}/lib"
      cd $lib
      cat > libm.a <<EOF
      OUTPUT_FORMAT(elf64-x86-64)
      /* GNU ld script
      */
      OUTPUT_FORMAT(elf64-x86-64)
      GROUP ( libm-${pkgs.dev.gnu64.glibc.version}.a libmvec.a )
      EOF
      cat > libm.so <<EOF
      /* GNU ld script
      */
      OUTPUT_FORMAT(elf64-x86-64)
      GROUP ( libm.so.6 AS_NEEDED ( libmvec.so.1 ) )
      EOF
      cat > libc.so <<EOF
      /* GNU ld script
      */
      OUTPUT_FORMAT(elf64-x86-64)
      GROUP ( libc.so.6 libc_nonshared.a AS_NEEDED ( ld-linux-x86-64.so.2 ) )
      EOF
    '' else "");
  };

  sysroot.gnu64.dev = sysrootFn "gnu64" "dev";
  sysroot.gnu64.release = sysrootFn "gnu64" "release";
  sysroot.musl64.dev = sysrootFn "musl64" "dev";
  sysroot.musl64.release = sysrootFn "musl64" "release";

  sysroots = with sysroot; [ gnu64.dev gnu64.release musl64.dev musl64.release ];

  tmpdir = toolchainPkgs.stdenv.mkDerivation {
    name = "${project-name}-tmpdir";
    src = null;
    dontUnpack = true;
    installPhase = ''
      mkdir --parent "$out/tmp"
    '';
  };

  clearDeps = obj: with builtins; (
    /. + "${unsafeDiscardStringContext(unsafeDiscardOutputDependency(obj))}"
  );

  maxLayers = 120;

  container = {
    compile-env = toolchainPkgs.dockerTools.buildLayeredImage {
        name = "${contianer-repo}/compile-env";
        tag = "${image-tag}";
        # glibc is needed as an explicit dependency due to the use of linker script in the libm.a file.
        # Specifically, the libm.a file contains a GROUP instruction which contains absolute paths to /nix
        # and those paths are not preserved by the rsync and clearDeps commands.
        contents = [
          env.compile
          pkgs.dev.gnu64.glibc.static
          pkgs.release.gnu64.glibc.static
          pkgs.dev.gnu64.glibc.dev
          pkgs.release.gnu64.glibc.dev
          pkgs.dev.gnu64.glibc.out
          pkgs.release.gnu64.glibc.out
        ] ++ (map clearDeps sysroots);
        inherit maxLayers;
    };
    doc-env = toolchainPkgs.dockerTools.buildLayeredImage {
      name = "${contianer-repo}/doc-env";
      tag = "${image-tag}";
      contents = docEnvPackageList;
      inherit maxLayers;
      config = {
        Entrypoint = [
          "/bin/mdbook"
        ];
        Env = [
          "LD_LIBRARY_PATH=/lib"
          "PATH=/bin:/lib/openjdk/bin"
        ];
      };
    };
  };
}
