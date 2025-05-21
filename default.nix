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
  rust-overlay = (
    import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz")
  );
  toolchainPkgs =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/${versions.nixpkgs.commit}.tar.gz";
        sha256 = versions.nixpkgs.hash.nix32.unpacked.sha256;
      })
      {
        overlays = [
          llvm-overlay
          rust-overlay
          helpersOverlay
        ];
      };

  helpersOverlay = self: super: rec {
    tmpdir = self.stdenv.mkDerivation {
      name = "${project-name}-tmpdir";
      src = null;
      dontUnpack = true;
      installPhase = ''
        mkdir --parent "$out/tmp"
      '';
    };

    graphviz-links = self.stdenv.mkDerivation {
      name = "${project-name}-tmpdir";
      src = null;
      dontUnpack = true;
      installPhase = ''
        mkdir -p $out/opt/local/bin
        ln -s "${self.graphviz}/bin/dot" "$out/opt/local/bin/dot"
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

      fancy.stdenvDynamic = super.fancy.llvmPackages.libcxxStdenv;
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
      systemd = null;
      systemdLibs = null;
      systemdMinimal = null;
      tinysparql = null;
      util-linux = super.util-linux.override { systemdSupport = false; };
      rdma-core = (optimizedBuild super.rdma-core).overrideAttrs (orig: {
        version = "57.0";
        src = self.fetchFromGitHub {
          owner = "githedgehog";
          repo = "rdma-core";
          rev = "fix-lto-57.0";
          hash = "sha256-huwo0j/V2a1KNwEuL8EfVyk+bSVNRkm+zm8vGhvUr3s=";
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
      libyang-dynamic =
        ((optimizedBuild super.libyang).override { pcre2 = self.fancy.pcre2; }).overrideAttrs
          (orig: {
            cmakeFlags = (orig.cmakeFlags or [ ]) ++ [
              "-DBUILD_SHARED_LIBS=ON"
            ];
          });
      libyang-static =
        ((optimizedBuild super.libyang).override { pcre2 = self.fancy.pcre2; }).overrideAttrs
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
      libcap =
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
      protobuf = (optimizedBuild super.protobuf).overrideAttrs (orig: {
        cmakeFlags = (orig.cmakeFlags or [ ]) ++ [ "-Dprotobuf_BUILD_SHARED_LIBS=OFF" ];
      });
      fancy.zlib = (optimizedBuild super.zlib).override {
        static = true;
        shared = false;
      };
      protobufc =
        (optimizedBuild (
          self.callPackage ./nix/protobufc {
            stdenv = self.fancy.stdenv;
            protobuf = self.protobuf;
            zlib = self.fancy.zlib;
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
            pcre2 = self.fancy.pcre2;
            protobufc = self.protobufc;
            python3Minimal = fancy.python3Minimal;
            readline = fancy.readline;
            stdenv = fancy.stdenv;
          }
        )).overrideAttrs
          (orig: {
            LDFLAGS =
              (orig.LDFLAGS or "")
              + " -L${self.libyang-static}/lib "
              + " -L${fancy.libxcrypt}/lib -lcrypt "
              + " -L${self.protobufc}/lib -lprotobuf-c "
              + " -L${self.fancy.pcre2}/lib -lpcre2-8 ";
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
      fancy.python3 = (super.python3.override { stdenv = fancy.stdenv; }).overrideAttrs (orig: {
        configureFlags = orig.configureFlags ++ [
          "--disable-shared"
          "--enable-static"
        ];
      });
      fancy.python3Minimal =
        (super.python3Minimal.override { stdenv = fancy.stdenv; }).overrideAttrs
          (orig: {
            configureFlags = orig.configureFlags ++ [
              "--disable-shared"
              "--enable-static"
            ];
          });
      fancy.nuitka = self.python3Packages.nuitka.override { python = fancy.python3; };

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
      # the optimized build for openssl takes ages to run.  We don't care about the performance of the crypto for
      # mstflint so skip the optimization
      fancy.openssl = (super.openssl.override { static = true; }).overrideAttrs (final: {
        doCheck = false;
      });
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
    };

  pkgs.debug =
    (import toolchainPkgs.path {
      overlays = [
        (self: prev: {
          pkgsCross.gnu64 = import prev.path {
            overlays = [
              llvm-overlay
              helpersOverlay
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

  rust-toolchain =
    with rust-version;
    (toolchainPkgs.rust-bin.${channel}.${version}.${rust-version.profile}.override {
      inherit targets extensions;
    });

  compileEnvPackageList = with toolchainPkgs; [
    bash
    cacert
    coreutils
    docker-client
    getent
    glibc.dev
    glibc.out
    gnugrep
    just
    libcap
    libgcc.libgcc
    libgccjit
    libz
    fancy.llvmPackages.clang
    fancy.llvmPackages.libclang.lib
    fancy.llvmPackages.lld
    pam
    rust-toolchain
    sudo
    tmpdir
    which
  ];

  docEnvPackageList = (
    with toolchainPkgs;
    [
      (callPackage ./nix/mdbook-alerts { })
      (callPackage ./nix/plantuml-wrapper { })
      bash
      coreutils
      file # needed for mdbook-plantuml to work (runtime exe dep)
      fontconfig.lib # needed for mdbook-plantuml to work (runtime exe dep)
      fontconfig.out # needed for mdbook-plantuml to work (runtime exe dep)
      glibc.out
      graphviz # needed for mdbook-plantuml to work (runtime exe dep)
      graphviz-links # needed for mdbook-plantuml to work (runtime exe dep)
      jre # needed for mdbook-plantuml to work (runtime exe dep)
      mdbook
      mdbook-mermaid
      mdbook-plantuml
      openssl.out # needed for mdbook-plantuml to work (runtime exe dep)
      plantuml # needed for mdbook-plantuml to work (runtime exe dep)
      tmpdir
    ]
  );

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
    doc = toolchainPkgs.symlinkJoin {
      name = "${project-name}-doc";
      paths = docEnvPackageList;
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
      name = "${contianer-repo}/frr-${profile}";
      tag = "${image-tag}";
      contents = toolchainPkgs.buildEnv {
        name = "frr-env-${profile}";
        pathsToLink = [ "/" ];
        paths = with pkgs.${profile}.gnu64; [
          bash
          fancy.busybox
          dplane-plugin
          dplane-rpc
          findutils
          frr-config
          pkgs.${profile}.gnu64.frr
          tmpdir
        ];
      };
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
      name = "${contianer-repo}/mstflint-${profile}";
      tag = "${image-tag}";
      contents = [
        pkgs.${profile}.gnu64.mstflint
        pkgs.${profile}.gnu64.coreutils
        pkgs.${profile}.gnu64.gnugrep
        pkgs.${profile}.gnu64.gnused
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
      mstflint-debug = release.mstflint;
      mstflint-release = debug.mstflint;
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
            "PATH=/bin"
          ];
        };
      };
    };
}
