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
    llvmPackages = super.${llvmPackagesVersion};
    llvmPackagesVersion = "llvmPackages_${llvm-version}";
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
        }));
      fancy.stdenvDynamic = self.llvmPackages.libcxxStdenv;
      fancy.stdenv = self.stdenvAdapters.makeStaticLibraries fancy.stdenvDynamic;
      buildWithMyFlags = pkg: (buildWithFlags build-flags pkg);
      optimizedBuild =
        pkg:
        (buildWithMyFlags (pkg.override { stdenv = fancy.stdenv; })).overrideAttrs (orig: {
          nativeBuildInputs = (orig.nativeBuildInputs or [ ]) ++ [ self.llvmPackages.bintools ];
          LD="lld";
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
        version = "56.1";
        src = self.fetchFromGitHub {
          owner = "githedgehog";
          repo = "rdma-core";
          rev = "fix-lto-56.1";
          hash = "sha256-nyvmDJBMPCnJP1AJw287bGFjJHiaN2kc8qvXCo/6WDg=";
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
            bintools = self.llvmPackages.bintools;
          }
        )
      );
      libyang =
        ((optimizedBuild super.libyang).override { pcre2 = self.fancy.pcre2; }).overrideAttrs
          (orig: {
            cmakeFlags = (orig.cmakeFlags or [ ]) ++ [
              "-DENABLE_STATIC=1"
              "-DBUILD_SHARED_LIBS=ON"
            ];
          });
      libcap =
        ((optimizedBuild super.libcap).override {
          usePam = false;
        }).overrideAttrs
          (orig: {
            nativeBuildInputs = (orig.nativeBuildInputs or [ ]) ++ [ self.llvmPackages.bintools ];
            LD = "lld";
            configureFlags = (orig.configureFlags or [ ]) ++ [ "--enable-static" ];
            makeFlags = orig.makeFlags ++ [ "GOLANG=no" ];
            postInstall =
              orig.postInstall
              + ''
                # extant postInstall removes .a files for no reason
                rm $lib/lib/*.so*;
                cp ./libcap/*.a $lib/lib;
              '';
          });
      fancy.json_c = (optimizedBuild super.json_c).overrideAttrs (orig: {
        CFLAGS = (orig.CFLAGS or "") + " -ffat-lto-objects ";
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
      protobuf_25 = (optimizedBuild super.protobuf_25).overrideAttrs (orig: {
        cmakeFlags = (orig.cmakeFlags or [ ]) ++ [ "-Dprotobuf_BUILD_SHARED_LIBS=OFF" ];
      });
      protobufc = (optimizedBuild super.protobufc).overrideAttrs (orig: {
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
      fancy.readline = optimizedBuild super.readline;
      fancy.libxcrypt = optimizedBuild super.libxcrypt;
      frr =
      (optimizedBuild (
        self.callPackage ./nix/frr {
          stdenv = fancy.stdenv;
          readline = fancy.readline;
          json_c = fancy.json_c.dev;
          libxcrypt = fancy.libxcrypt;
        }
      )).overrideAttrs
        (orig: {
          nativeBuildInputs = (orig.nativeBuildInputs or [ ]) ++ [
            fancy.libxcrypt
            self.fancy.pcre2
            self.protobufc
          ];
          LDFLAGS =
            (orig.LDFLAGS or "")
            + " -L${fancy.libxcrypt}/lib -lcrypt "
            + " -L${self.protobufc}/lib -lprotobuf-c "
            + " -L${self.fancy.pcre2}/lib -lpcre2-8 "
            + " -L${self.libgccjit}/lib -latomic ";
          configureFlags = orig.configureFlags ++ [
            "--enable-shared"
            "--enable-static"
            "--enable-static-bin"
          ];
        });
    };

  pkgs.dev =
    (import toolchainPkgs.path {
      overlays = [
        (self: prev: {
          pkgsCross.gnu64 = import prev.path {
            overlays = [
              llvm-overlay
              helpersOverlay
              (crossOverlay {
                build-flags = build-flags.dev;
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
      dev = sysrootPackageListFn pkgs.dev.gnu64;
      release = sysrootPackageListFn pkgs.release.gnu64;
    };
  };

  rust-toolchain =
    with rust-version;
    (toolchainPkgs.rust-bin.${channel}.${version}.${profile}.override {
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
    llvmPackages.clang
    llvmPackages.libclang.lib
    llvmPackages.lld
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
    sysroot.gnu64.dev = toolchainPkgs.symlinkJoin {
      name = "${project-name}-env-dev-sysroot-gnu64";
      paths = sysrootPackageListFn pkgs.dev.gnu64;
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
      # Rust can't decided if the profile is called dev or debug so we need a fixup
      postFixup =
        (
          if profile == "dev" then
            ''
              ln -s dev $out/sysroot/x86_64-unknown-linux-gnu/debug
            ''
          else
            ""
        )
        + (
          # libm.a file contains a GROUP instruction which contains absolute paths to /nix
          # and those paths are not preserved by the rsync commands.
          ''
            export lib="$out/sysroot/x86_64-unknown-linux-gnu/${profile}/lib"
            cd $lib
            cat > libm.a <<EOF
            OUTPUT_FORMAT(elf64-x86-64)
            GROUP ( libm-${pkgs.dev.gnu64.glibc.version}.a libmvec.a )
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

  sysroot.gnu64.dev = sysrootFn "dev";
  sysroot.gnu64.release = sysrootFn "release";

  sysroots = with sysroot; [
    gnu64.dev
    gnu64.release
  ];

  maxLayers = 120;

  initfrr = toolchainPkgs.stdenv.mkDerivation {
    name = "${project-name}-initfrr";
    src = ./nix/frr/bin;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src/init.sh $out/bin/init.sh
      chmod +x $out/bin/init.sh
    '';
  };

  frrContainerContents = (
    with pkgs.release.gnu64;
    [
      bash
      coreutils
      frr
      glibc.bin
      glibc.out
      gnugrep
      gnused
      initfrr
      libxcrypt
      ncurses
      readline
      tmpdir
    ]
  );

  container = {
    frr = toolchainPkgs.dockerTools.buildLayeredImage {
      name = "${contianer-repo}/frr";
      tag = "${image-tag}";
      contents = frrContainerContents;
      config = {
        Env = [
          "LD_LIBRARY_PATH=/lib"
          "PATH=/bin:/libexec/frr"
        ];
        Entrypoint = [ "/bin/init.sh" ];
      };
      inherit maxLayers;
    };
    compile-env = toolchainPkgs.dockerTools.buildLayeredImage {
      name = "${contianer-repo}/compile-env";
      tag = "${image-tag}";
      contents = [
        env.compile
        pkgs.dev.gnu64.glibc.static
        pkgs.release.gnu64.glibc.static
        pkgs.dev.gnu64.glibc.dev
        pkgs.release.gnu64.glibc.dev
        pkgs.dev.gnu64.glibc.out
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
    libc-env = toolchainPkgs.dockerTools.buildLayeredImage {
      name = "${contianer-repo}/libc-env";
      tag = "${image-tag}";
      contents = [
        pkgs.release.gnu64.glibc.out
        pkgs.release.gnu64.libgcc.libgcc
      ];
      inherit maxLayers;
    };
  };
}
