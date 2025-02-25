{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,

  # build time
  autoreconfHook,
  flex,
  bison,
  perl,
  pkg-config,
  texinfo,
  buildPackages,

  # runtime
  #, libunwind
  #, pam
  #, zeromq
  c-ares,
  elfutils,
  json_c,
  libcap,
  libxcrypt,
  libyang,
  net-snmp,
  pcre2,
  protobufc,
  python3,
  readline,
  rtrlib,

  # tests
  nettools,
  nixosTests,

  # FRR's configure.ac gets SNMP options by executing net-snmp-config on the build host
  # This leads to compilation errors when cross compiling.
  # E.g. net-snmp-config for x86_64 does not return the ARM64 paths.
  #
  #   SNMP_LIBS="`${NETSNMP_CONFIG} --agent-libs`"
  #   SNMP_CFLAGS="`${NETSNMP_CONFIG} --base-cflags`"
  snmpSupport ? false,

  # other general options besides snmp support
  rpkiSupport ? false,
  numMultipath ? 8,
  watchfrrSupport ? true,
  cumulusSupport ? false,
  rtadvSupport ? true,
  irdpSupport ? false,
  mgmtdSupport ? false,

  # routing daemon options
  bgpdSupport ? true,
  bfddSupport ? true,
  staticdSupport ? true,

  ripdSupport ? false,
  ripngdSupport ? false,
  ospfdSupport ? false,
  ospf6dSupport ? false,
  ldpdSupport ? false,
  nhrpdSupport ? false,
  eigrpdSupport ? false,
  babeldSupport ? false,
  isisdSupport ? false,
  pimdSupport ? false,
  pim6dSupport ? false,
  sharpdSupport ? false,
  fabricdSupport ? false,
  vrrpdSupport ? false,
  pathdSupport ? false,
  pbrdSupport ? false,

  # BGP options
  bgpAnnounce ? true,
  bgpBmp ? false,
  bgpVnc ? false,

  # OSPF options
  ospfApi ? false,
}:

lib.warnIf (!(stdenv.buildPlatform.canExecute stdenv.hostPlatform))
  "cannot enable SNMP support due to cross-compilation issues with net-snmp-config"

  stdenv.mkDerivation
  (finalAttrs: {
    pname = "frr";
    version = "10.2.1";
    dontPatchShebangs = true;
    dontFixup = true;
    dontPatchElf = true;

    src = fetchFromGitHub {
      owner = "FRRouting";
      repo = finalAttrs.pname;
      rev = "${finalAttrs.pname}-${finalAttrs.version}";
      hash = "sha256-TWqW6kI5dDl6IW2Ql6eeySDSyxp0fPgcJOOX1JxjAxs";
    };

    nativeBuildInputs = [
      autoreconfHook
      bison
      flex
      perl
      pkg-config
      protobufc
      python3
      texinfo
    ];

    buildInputs =
      [
        # libunwind
        # pam
        # python3
        # zeromq
        c-ares
        json_c
        libxcrypt
        libyang
        pcre2
        protobufc
        readline
        rtrlib
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        libcap
      ]
      ++ lib.optionals snmpSupport [
        net-snmp
      ]
      ++ lib.optionals (lib.meta.availableOn stdenv.hostPlatform elfutils) [
        elfutils
      ];

    # otherwise in cross-compilation: "configure: error: no working python version found"
    depsBuildBuild = [
      # buildPackages.python3
    ];

    # cross-compiling: clippy is compiled with the build host toolchain, split it out to ease
    # navigation in dependency hell
    clippy-helper = buildPackages.callPackage ./clippy-helper.nix {
      frrVersion = finalAttrs.version;
      frrSource = finalAttrs.src;
    };

    configureFlags = [
      "--disable-grpc"
      "--disable-protobuf"
      "--disable-python-runtime"
      "--disable-scripting"
      "--disable-sysrepo"
      "--disable-zeromq"
      "--with-libpam=no"
      "--enable-shared"
      "--enable-static"
      "--enable-static-bin"
      "--with-crypto=internal"
      "--disable-doc"

      "--disable-silent-rules"
      "--enable-configfile-mask=0640"
      "--enable-group=frr"
      "--enable-logfile-mask=0640"
      "--enable-multipath=${toString numMultipath}"
      "--localstatedir=/run/frr"
      "--sbindir=${placeholder "out"}/libexec/frr"
      "--sysconfdir=/etc/frr"
      "--with-clippy=${finalAttrs.clippy-helper}/bin/clippy"
      # general options
      (lib.strings.enableFeature snmpSupport "snmp")
      (lib.strings.enableFeature rpkiSupport "rpki")
      (lib.strings.enableFeature watchfrrSupport "watchfrr")
      (lib.strings.enableFeature rtadvSupport "rtadv")
      (lib.strings.enableFeature irdpSupport "irdp")
      (lib.strings.enableFeature mgmtdSupport "mgmtd")

      # routing protocols
      (lib.strings.enableFeature bgpdSupport "bgpd")
      (lib.strings.enableFeature ripdSupport "ripd")
      (lib.strings.enableFeature ripngdSupport "ripngd")
      (lib.strings.enableFeature ospfdSupport "ospfd")
      (lib.strings.enableFeature ospf6dSupport "ospf6d")
      (lib.strings.enableFeature ldpdSupport "ldpd")
      (lib.strings.enableFeature nhrpdSupport "nhrpd")
      (lib.strings.enableFeature eigrpdSupport "eigrpd")
      (lib.strings.enableFeature babeldSupport "babeld")
      (lib.strings.enableFeature isisdSupport "isisd")
      (lib.strings.enableFeature pimdSupport "pimd")
      (lib.strings.enableFeature pim6dSupport "pim6d")
      (lib.strings.enableFeature sharpdSupport "sharpd")
      (lib.strings.enableFeature fabricdSupport "fabricd")
      (lib.strings.enableFeature vrrpdSupport "vrrpd")
      (lib.strings.enableFeature pathdSupport "pathd")
      (lib.strings.enableFeature bfddSupport "bfdd")
      (lib.strings.enableFeature pbrdSupport "pbrd")
      (lib.strings.enableFeature staticdSupport "staticd")
      # BGP options
      (lib.strings.enableFeature bgpAnnounce "bgp-announce")
      (lib.strings.enableFeature bgpBmp "bgp-bmp")
      (lib.strings.enableFeature bgpVnc "bgp-vnc")
      # OSPF options
      (lib.strings.enableFeature ospfApi "ospfapi")
      # Cumulus options
      (lib.strings.enableFeature cumulusSupport "cumulus")
    ];

    postPatch = ''
      substituteInPlace tools/frr-reload \
        --replace-quiet /usr/lib/frr/ $out/libexec/frr/
      sed -i '/^PATH=/ d' tools/frr.in tools/frrcommon.sh.in
    '';

    buildPhase = ''
      ls -lah
      make CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" -j32
      cd zebra
      ls -lah
      $CC $CFLAGS $LDFLAGS \
        -I /build/source \
        -I /build/source/lib \
        -I /build/source/lib/zebra \
        -o sample_plugin.so \
        -shared \
        -fPIC \
        sample_plugin.c
      mkdir -p $out/lib/frr/modules
      cp sample_plugin.so $out/lib/frr/modules
      cd ..
    '';

    doCheck = false;

    nativeCheckInputs = [
      nettools
      #python3.pkgs.pytest
    ];

    enableParallelBuilding = true;

    meta = with lib; {
      homepage = "https://frrouting.org/";
      description = "FRR BGP/OSPF/ISIS/RIP/RIPNG routing daemon suite";
      longDescription = ''
        FRRouting (FRR) is a free and open source Internet routing protocol suite
        for Linux and Unix platforms. It implements BGP, OSPF, RIP, IS-IS, PIM,
        LDP, BFD, Babel, PBR, OpenFabric and VRRP, with alpha support for EIGRP
        and NHRP.

        FRR’s seamless integration with native Linux/Unix IP networking stacks
        makes it a general purpose routing stack applicable to a wide variety of
        use cases including connecting hosts/VMs/containers to the network,
        advertising network services, LAN switching and routing, Internet access
        routers, and Internet peering.

        FRR has its roots in the Quagga project. In fact, it was started by many
        long-time Quagga developers who combined their efforts to improve on
        Quagga’s well-established foundation in order to create the best routing
        protocol stack available. We invite you to participate in the FRRouting
        community and help shape the future of networking.

        Join the ranks of network architects using FRR for ISPs, SaaS
        infrastructure, web 2.0 businesses, hyperscale services, and Fortune 500
        private clouds.
      '';
      license = with licenses; [
        gpl2Plus
        lgpl21Plus
      ];
      maintainers = with maintainers; [
        woffs
        thillux
      ];
      # adapt to platforms stated in http://docs.frrouting.org/en/latest/overview.html#supported-platforms
      platforms = (platforms.linux ++ platforms.freebsd ++ platforms.netbsd ++ platforms.openbsd);
    };

    passthru.tests = { inherit (nixosTests) frr; };
  })
