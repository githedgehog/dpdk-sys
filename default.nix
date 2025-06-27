{
  rust-channel ? "stable",
  build-flags ? import ./nix/flags.nix,
  versions ? import ./nix/versions.nix,
  image-tag ? "latest",
  contianer-repo ? "ghcr.io/githedgehog/dpdk-sys",
}:
rec {
  rust-version = versions.rust.${rust-channel};
  llvm-version = rust-version.llvm;
  llvm-overlay = self: super: rec {
    llvmPackagesVersion = "llvmPackages_${llvm-version}";
    fancy.llvmPackages = super.${llvmPackagesVersion};
  };
  fenix-overlay = (
    import "${fetchTarball "https://github.com/nix-community/fenix/archive/main.tar.gz"}/overlay.nix"
  );
  rust-overlay = self: super: rec {
    rust-toolchain = with super.fenix; let toolchain = fromToolchainName {
        name = versions.rust.stable.version;
        sha256 = versions.rust.stable.toolchain_toml_hash;
      }; in combine (
      map (extension: toolchain.${extension}) versions.rust.stable.extensions
    );
    fancy = super.fancy // rec {
      rustPlatform = super.makeRustPlatform { cargo = rust-toolchain; rustc = rust-toolchain; };
      rustOverrides = pkg: (pkg.override { inherit rustPlatform; }).overrideAttrs { doCheck = false; };
    };
    cargo-bolero = fancy.rustOverrides super.cargo-bolero;
    cargo-deny = fancy.rustOverrides super.cargo-deny;
    cargo-llvm-cov = fancy.rustOverrides super.cargo-llvm-cov;
    cargo-nextest = fancy.rustOverrides super.cargo-nextest;
    csview = fancy.rustOverrides super.csview;
    just = fancy.rustOverrides super.just;
    frr-agent = fancy.rustOverrides (self.callPackage ./nix/frr-agent {
      rev = versions.frr-agent.rev;
      hash = versions.frr-agent.hash;
    });
  };
  toolchainPkgs =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/${versions.nixpkgs.commit}.tar.gz";
        sha256 = versions.nixpkgs.hash.nix32.unpacked.sha256;
      })
      {
        overlays = [
          llvm-overlay
          fenix-overlay
          rust-overlay
          helpersOverlay
        ];
      };

  helpersOverlay = self: super: {
    tmpdir = self.stdenv.mkDerivation {
      name = "${project-name}-tmpdir";
      src = null;
      dontUnpack = true;
      installPhase = ''
        mkdir --parent "$out/tmp"
      '';
    };
  };

  project-name = "dpdk-sys";
  crossOverlay =
    { build-flags, crossEnv }:
    self: super: rec {
      inherit build-flags;
      buildWithFlags =
        flags: pkg:
        (pkg.overrideAttrs (orig: {
          CFLAGS = "${orig.CFLAGS or ""} ${flags.CFLAGS}";
          CXXFLAGS = "${orig.CXXFLAGS or ""} ${flags.CXXFLAGS}";
          LDFLAGS = "${orig.LDFLAGS or ""} ${flags.LDFLAGS}";
          env.NIX_CFLAGS_COMPILE = (orig.NIX_CFLAGS_COMPILE or "") + flags.CFLAGS;
          env.NIX_CXXFLAGS_COMPILE = (orig.NIX_CXXFLAGS_COMPILE or "") + flags.CXXFLAGS;
          env.NIX_CFLAGS_LINK = (orig.NIX_CFLAGS_LINK or "") + flags.LDFLAGS;
        }));

      fancy.llvmPackages = super.fancy.llvmPackages;
      fancy.stdenvDynamic = super.fancy.llvmPackages.stdenv;
      fancy.stdenv = self.stdenvAdapters.makeStaticLibraries fancy.stdenvDynamic;
      buildWithMyFlags = pkg: (buildWithFlags build-flags pkg);
      optimizedBuild =
        pkg:
        (buildWithMyFlags (pkg.override { stdenv = fancy.stdenv; })).overrideAttrs (orig: {
          nativeBuildInputs = (orig.nativeBuildInputs or [ ]) ++ [ super.fancy.llvmPackages.bintools ];
          LD = "lld";
          withDoc = false;
          doCheck = false;
        });
      fancy.libmd = (optimizedBuild super.libmd).overrideAttrs (orig: {
        configureFlags = orig.configureFlags ++ [
          "--enable-static"
          "--disable-shared"
        ];
        postFixup =
          (orig.postFixup or "")
          + ''
            rm $out/lib/*.la
          '';
      });
      fancy.libbsd =
        ((optimizedBuild super.libbsd).override {
          libmd = fancy.libmd;
        }).overrideAttrs
          (orig: {
            doCheck = false;
            configureFlags = orig.configureFlags ++ [
              "--enable-static"
              "--enable-shared"
            ];
            postFixup =
              (orig.postFixup or "")
              + ''
                rm $out/lib/*.la
              '';
          });
      fatLto =
        pkg:
        pkg.overrideAttrs (orig: {
          CFLAGS = "${orig.CFLAGS or ""} -ffat-lto-objects";
        });

      at-spi2-atk = null; # no users in container
      at-spi2-core = null; # no users in container
      bluez = null;
      dbus = super.dbus.override { enableSystemd = false; };
      gtk3 = null;
      libusb = null;
      libusb1 = null;
      tinysparql = null;
      util-linux = super.util-linux.override { systemdSupport = false; };
      rdma-core = (optimizedBuild super.rdma-core).overrideAttrs (orig: {
        version = "58.0";
        src = self.fetchFromGitHub {
          owner = "githedgehog";
          repo = "rdma-core";
          rev = "fix-lto-58.0";
          hash = "sha256-2FpPBrbHvJlFfmQlLBbl9aK5BIOXfOJxr6AIPsrLrPY=";
        };
        outputs = [
          "out"
          "dev"
        ];
        perl = null;
        cmakeFlags = orig.cmakeFlags ++ [
          "-DENABLE_STATIC=1"
          "-DNO_PYVERBS=1"
          "-DNO_MAN_PAGES=1"
          "-DIOCTL_MODE=write"
          "-DNO_COMPAT_SYMS=1"
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
        postFixup =
          (orig.postFixup or "")
          + ''
            rm $out/lib/*.la
          '';
      });
      jansson = (optimizedBuild super.jansson).overrideAttrs (orig: {
        cmakeFlags = [ "-DJANSSON_BUILD_SHARED_LIBS=OFF" ];
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
      dpdk = (
        optimizedBuild (
          self.callPackage ./nix/dpdk {
            libbsd = fancy.libbsd;
            libmd = fancy.libmd;
          }
        )
      );
      dpdk-wrapper = (
        optimizedBuild (
          self.callPackage ./nix/dpdk-wrapper {
            inherit dpdk;
            libbsd = fancy.libbsd;
            bintools = super.fancy.llvmPackages.bintools;
          }
        )
      );
      fancy.xxHash = optimizedBuild super.xxHash;
      libyang-dynamic =
        ((optimizedBuild super.libyang).override { pcre2 = self.fancy.pcre2; xxHash = self.fancy.xxHash; }).overrideAttrs
          (orig: {
            cmakeFlags = (orig.cmakeFlags or [ ]) ++ [
              "-DBUILD_SHARED_LIBS=ON"
            ];
          });
      libyang-static =
        ((optimizedBuild super.libyang).override { pcre2 = self.fancy.pcre2; xxHash = self.fancy.xxHash; }).overrideAttrs
          (orig: {
            cmakeFlags = (orig.cmakeFlags or [ ]) ++ [
              "-DBUILD_SHARED_LIBS=OFF"
            ];
          });
      libyang = self.fancy.stdenv.mkDerivation {
        name = "libyang";
        src = null;
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/lib;
          cp -r ${self.libyang-static}/lib/libyang.a $out/lib/
          cp -r ${self.libyang-dynamic}/* $out
        '';
      };
      fancy.libcap =
        ((optimizedBuild super.libcap).override {
          stdenv = fancy.stdenv;
          usePam = false;
        }).overrideAttrs
          (orig: {
            doCheck = false; # tests require privileges
            makeFlags = [
              "lib=lib"
              "PAM_CAP=no"
              "CC:=clang"
              "SHARED=no"
              "LIBCSTATIC=no"
              "GOLANG=no"
            ];
            configureFlags = (orig.configureFlags or [ ]) ++ [ "--enable-static" ];
            postInstall =
              orig.postInstall
              + ''
                # extant postInstall removes .a files for no reason
                cp ./libcap/*.a $lib/lib;
              '';
          });
      fancy.json_c = (optimizedBuild super.json_c).overrideAttrs (orig: {
        cmakeFlags = (orig.cmakeFlags or [ ]) ++ [ "-DENABLE_STATIC=1" ];
        postInstall =
          (orig.postInstall or "")
          + ''
            mkdir -p $dev/lib
            $RANLIB libjson-c.a;
            cp libjson-c.a $dev/lib;
          '';
      });
      rtrlib = (optimizedBuild super.rtrlib).overrideAttrs (orig: {
        cmakeFlags = (orig.cmakeFlags or [ ]) ++ [ "-DENABLE_STATIC=1" ];
      });
      abseil-cpp = (optimizedBuild super.abseil-cpp);
      protobuf = (optimizedBuild (super.protobuf.override { enableShared = false; })).overrideAttrs (orig: {
        cmakeFlags = (orig.cmakeFlags or [ ]) ++ [ "-Dprotobuf_BUILD_SHARED_LIBS=OFF" ];
      });
      fancy.zlib = (optimizedBuild super.zlib).override {
        static = true;
        shared = false;
      };
      protobufc =
        (optimizedBuild (
          self.callPackage ./nix/protobufc {
            stdenv = fancy.stdenv;
            zlib = fancy.zlib;
          }
        )).overrideAttrs
          (orig: {
            configureFlags = (orig.configureFlags or [ ]) ++ [
              "--enable-static"
              "--disable-shared"
            ];
          });
      fancy.pcre2 = (optimizedBuild super.pcre2).overrideAttrs (orig: {
        configureFlags = (orig.configureFlags or [ ]) ++ [
          "--enable-static"
          "--disable-shared"
        ];
      });
      fancy.ncurses = optimizedBuild (super.ncurses.override { enableStatic = true; });
      fancy.readline = optimizedBuild (super.readline.override { ncurses = fancy.ncurses; });
      fancy.libxcrypt = optimizedBuild super.libxcrypt;
      frr =
        (optimizedBuild (
          self.callPackage ./nix/frr {
            rev = versions.frr.rev;
            hash = versions.frr.hash;
            json_c = fancy.json_c.dev;
            libxcrypt = fancy.libxcrypt;
            libyang = self.libyang-static;
            pcre2 = fancy.pcre2;
            readline = fancy.readline;
            stdenv = fancy.stdenv;
          }
        )).overrideAttrs
          (orig: {
            LDFLAGS =
              (orig.LDFLAGS or "")
              + " -L${self.libyang-static}/lib -lyang "
              + " -L${fancy.xxHash}/lib -lxxhash "
              + " -L${fancy.libxcrypt}/lib -lcrypt "
              + " -L${protobufc}/lib -lprotobuf-c "
              + " -L${fancy.pcre2}/lib -lpcre2-8 "
              + " -L${self.libgccjit}/lib -latomic ";
            configureFlags = orig.configureFlags ++ [
              "--enable-shared"
              "--enable-static"
              "--enable-static-bin"
            ];
          });
      dplane-rpc = optimizedBuild (
        self.callPackage ./nix/dplane-rpc {
          rev = versions.dplane-rpc.rev;
          hash = versions.dplane-rpc.hash;
        }
      );
      dplane-plugin = optimizedBuild (
        self.callPackage ./nix/dplane-plugin {
          rev = versions.dplane-plugin.rev;
          hash = versions.dplane-plugin.hash;
          commit_date = versions.dplane-plugin.commit_date;
          stdenv = fancy.stdenv;
          libyang = libyang-static;
          pcre2 = fancy.pcre2;
        }
      );
      frr-config = (optimizedBuild (self.callPackage ./nix/frr-config { }));
      frr-with-dplane-plugin = self.symlinkJoin {
        name = "frr-with-dplane-plugin";
        paths = [
          frr
          dplane-rpc
          dplane-plugin
          frr-config
        ];
      };

      fancy.zstd = optimizedBuild super.zstd;
      fancy.xz = optimizedBuild super.xz;
      fancy.libxml2 = optimizedBuild super.libxml2;
      fancy.busybox = super.busybox.override {
        enableStatic = true;
      };
      fancy.boost = (optimizedBuild super.boost).override {
        enableShared = false;
        enableStatic = true;
      };
      fancy.expat = optimizedBuild super.expat;
      fancy.openssl = optimizedBuild ((super.openssl.override { static = true; }).overrideAttrs (final: {
        doCheck = false;
      }));
      fancy.curl = (optimizedBuild super.curlMinimal).override { zlib = fancy.zlib; };
      hwdata = optimizedBuild super.hwdata;
      pciutils = (optimizedBuild super.pciutils).override {
        zlib = fancy.zlib;
        static = true;
      };

      mstflint =
        (optimizedBuild (
          super.mstflint.override {
            openssl = self.fancy.openssl;
            zlib = self.fancy.zlib;
            xz = self.fancy.xz;
            expat = self.fancy.expat;
            boost = self.fancy.boost;
            curl = self.fancy.curl;
            libxml2 = self.fancy.libxml2;
            busybox = self.fancy.busybox;
            onlyFirmwareUpdater = false;
            enableDPA = false;
            python3 = self.python3Minimal;
          }
        )).overrideAttrs
          (orig: {
            configureFlags = [
              "--datarootdir=${placeholder "out"}/share"
              "--disable-cs"
              "--disable-dc"
              "--disable-inband"
              "--disable-openssl"
              "--disable-rdmem"
              "--disable-shared"
              "--disable-xml2"
              "--enable-adb-generic-tools"
              "--enable-all-static"
              "--enable-static"
              "--enable-static-libstdcpp"
              # "--disable-dpa" # disabling this causes it to be enabled?
              # "--disable-fw-mgr" # disabling this causes it to be enabled?
            ];

            nativeBuildInputs = orig.nativeBuildInputs ++ [ self.nukeReferences ];

            buildInputs =
              [ self.python3Minimal ]
              ++ (with self.fancy; [
                boost
                curl
                expat
                libxml2
                openssl.out
                xz
                zlib
              ]);

            preFixup =
              (orig.postFixup or "")
              + (with self.fancy; ''
                rm -f "$out/bin/mstarchive"
                rm -f "$out/bin/mstfwmanager"
                find "$out" \
                  -type f \
                  -exec nuke-refs \
                  -e "$out" \
                  -e ${openssl.out} \
                  -e ${self.python3Minimal} \
                  -e ${busybox} \
                  -e ${stdenv.cc.libc} \
                  '{}' +;
              '');
          });

      perftest = (
        optimizedBuild (
          self.callPackage ./nix/perftest {
}
        )
      );
    };

  pkgs.debug =
    (import toolchainPkgs.path {
      overlays = [
        (self: prev: {
          pkgsCross.gnu64 = import prev.path {
            overlays = [
              llvm-overlay
              helpersOverlay
              fenix-overlay
              rust-overlay
              (crossOverlay {
                build-flags = build-flags.debug;
                crossEnv = "gnu64";
              })
            ];
          };
        })
      ];
    }).pkgsCross;

  pkgs.release =
    (import toolchainPkgs.path {
      overlays = [
        (self: prev: {
          pkgsCross.gnu64 = import prev.path {
            overlays = [
              llvm-overlay
              helpersOverlay
              fenix-overlay
              rust-overlay
              (crossOverlay {
                build-flags = build-flags.release;
                crossEnv = "gnu64";
              })
            ];
          };
        })
      ];
    }).pkgsCross;

  sysrootPackageListFn =
    pkgs: with pkgs; [
      dpdk
      dpdk-wrapper
      fancy.libbsd
      fancy.libbsd.dev
      fancy.libmd
      glibc
      glibc.dev
      glibc.out
      glibc.static
      libgcc.libgcc
      libmnl
      libnftnl
      libnl.out
      libpcap
      numactl
      rdma-core
    ];

  sysrootPackageList = {
    gnu64 = {
      debug = sysrootPackageListFn pkgs.debug.gnu64;
      release = sysrootPackageListFn pkgs.release.gnu64;
    };
  };


  compileEnvPackageList = with toolchainPkgs; [
    bash
    cacert
    cargo-bolero
    cargo-deny
    cargo-llvm-cov
    cargo-nextest
    coreutils
    csview
    docker-client
    fancy.llvmPackages.clang
    fancy.llvmPackages.compiler-rt
    fancy.llvmPackages.libclang.lib
    fancy.llvmPackages.lld
    getent
    glibc.dev
    glibc.out
    gnugrep
    just
    just
    libcap
    libgcc.libgcc
    libgccjit
    libz
    pam
    patchelf
    rust-toolchain
    stdenv.cc.cc.lib
    strace
    sudo
    tmpdir
    which
  ];

  env = {
    sysroot.gnu64.debug = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-debug-sysroot-gnu64";
      paths = sysrootPackageListFn pkgs.debug.gnu64;
    };
    sysroot.gnu64.release = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-release-sysroot-gnu64";
      paths = sysrootPackageListFn pkgs.release.gnu64;
    };
    compile = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-compile";
      paths = compileEnvPackageList;
    };
  };

  sysrootFn =
    profile:
    toolchainPkgs.stdenv.mkDerivation {
      name = "${project-name}-sysroot.gnu64.${profile}";
      nativeBuildInputs = [ toolchainPkgs.rsync ];
      src = null;
      dontUnpack = true;
      installPhase = ''
        mkdir --parent "$out/sysroot/x86_64-unknown-linux-gnu/${profile}/"{lib,include}
        rsync -rLhP \
          --exclude '- *.so' \
          --exclude '- *.so.*' \
          --exclude '- *.la' \
          --exclude '- *.pc' \
          --exclude '- *.la' \
          --include 'libc.so*' \
          --include 'libm.so*' \
          --include 'libgcc_s.so*' \
          "${env.sysroot.gnu64.${profile}}/lib/" \
          "$out/sysroot/x86_64-unknown-linux-gnu/${profile}/lib/"
        rsync -rLhP \
          "${env.sysroot.gnu64.${profile}}/include/" \
          "$out/sysroot/x86_64-unknown-linux-gnu/${profile}/include/"
      '';
      postFixup = (
        # libm.a file contains a GROUP instruction which contains absolute paths to /nix
        # and those paths are not preserved by the rsync commands.
        ''
          export lib="$out/sysroot/x86_64-unknown-linux-gnu/${profile}/lib"
          cd $lib
          cat > libm.a <<EOF
          OUTPUT_FORMAT(elf64-x86-64)
          GROUP ( libm-${pkgs.${profile}.gnu64.glibc.version}.a libmvec.a )
          EOF
          cat > libm.so <<EOF
          OUTPUT_FORMAT(elf64-x86-64)
          GROUP ( libm.so.6 AS_NEEDED ( libmvec.so.1 ) )
          EOF
          cat > libc.so <<EOF
          OUTPUT_FORMAT(elf64-x86-64)
          GROUP ( libc.so.6 libc_nonshared.a AS_NEEDED ( ld-linux-x86-64.so.2 ) )
          EOF
        '');
    };

  sysroot.gnu64.debug = sysrootFn "debug";
  sysroot.gnu64.release = sysrootFn "release";

  sysroots = with sysroot; [
    gnu64.debug
    gnu64.release
  ];

  maxLayers = 120;

  container-profile = profile: {
    frr = toolchainPkgs.dockerTools.buildLayeredImage {
      name = "${contianer-repo}/frr";
      tag = "${image-tag}";
      contents = toolchainPkgs.buildEnv {
        name = "frr-env-${profile}";
        pathsToLink = [ "/" ];
        paths = with pkgs.${profile}.gnu64; [
          bash
          dplane-plugin
          dplane-rpc
          fancy.busybox
          findutils
          frr-agent
          frr-config
          libgccjit
          pkgs.${profile}.gnu64.frr
          python3Minimal
          tmpdir
        ];
      };
    };
    debug-env = toolchainPkgs.dockerTools.buildLayeredImage {
      name = "${contianer-repo}/debug-env";
      tag = "${image-tag}";
      contents = (with toolchainPkgs; [
        bashInteractive
        coreutils
        curl
        debianutils
        ethtool
        gawk
        gdb
        gnugrep
        gnused
        iproute2
        iptables
        jq
        less
        nano
        procps
        rr
        strace
        tcpdump
        tshark
        valgrind
        vim
        zstd
      ]) ++ (with pkgs.${profile}.gnu64; [
        glibc.out
        libgcc.libgcc
      ]);
      inherit maxLayers;
    };
    libc-env = toolchainPkgs.dockerTools.buildLayeredImage {
      name = "${contianer-repo}/libc-env";
      tag = "${image-tag}";
      contents = [
        pkgs.${profile}.gnu64.glibc.out
        pkgs.${profile}.gnu64.libgcc.libgcc
      ];
      inherit maxLayers;
    };

    mstflint = toolchainPkgs.dockerTools.buildLayeredImage {
      name = "${contianer-repo}/mstflint";
      tag = "${image-tag}";
      contents = [
        pkgs.${profile}.gnu64.pciutils
        pkgs.${profile}.gnu64.bashInteractive
        pkgs.${profile}.gnu64.coreutils
        pkgs.${profile}.gnu64.gnugrep
        pkgs.${profile}.gnu64.gnused
        pkgs.${profile}.gnu64.inotify-info
        pkgs.${profile}.gnu64.iproute2
        pkgs.${profile}.gnu64.jq
        pkgs.${profile}.gnu64.mstflint
        pkgs.${profile}.gnu64.python3Minimal
      ];
      inherit maxLayers;
    };

  };

  container =
    let
      release = container-profile "release";
      debug = container-profile "debug";
    in
    {
      frr-release = release.frr;
      frr-debug = debug.frr;
      mstflint-debug = debug.mstflint;
      mstflint-release = release.mstflint;
      debug-env = release.debug-env;
      libc-env = release.libc-env;
      compile-env = toolchainPkgs.dockerTools.buildLayeredImage {
        name = "${contianer-repo}/compile-env";
        tag = "${image-tag}";
        contents = [
          env.compile
          pkgs.debug.gnu64.glibc.static
          pkgs.release.gnu64.glibc.static
          pkgs.debug.gnu64.glibc.dev
          pkgs.release.gnu64.glibc.dev
          pkgs.debug.gnu64.glibc.out
          pkgs.release.gnu64.glibc.out
        ] ++ sysroots;
        inherit maxLayers;
      };
    };
}
