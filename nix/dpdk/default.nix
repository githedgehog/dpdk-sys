{
  stdenv,
  lib,
  fetchurl,
  pkg-config,
  meson,
  ninja,
  makeWrapper,
  libbsd,
  numactl,
  elfutils,
  rdma-core,
  libnl,
  libmd,
  doxygen,
  python3,
  pciutils,
  withExamples ? [ ],
}:

stdenv.mkDerivation rec {
  pname = "dpdk";
  version = "25.03";

  src = fetchurl {
    url = "https://fast.dpdk.org/rel/dpdk-${version}.tar.xz";
    sha256 = "sha256-akCnMTKChuvXloWxj/pZkua3cME4Q9Zf0NEVfPzP9j0=";
  };

  nativeBuildInputs = [
    makeWrapper
    doxygen
    meson
    ninja
    pkg-config
    python3
    python3.pkgs.sphinx
    python3.pkgs.pyelftools
  ];

  buildInputs = [
    elfutils
    libnl
    numactl
    python3
  ];

  propagatedBuildInputs = [
    # Propagated to support current DPDK users in nixpkgs which statically link
    # with the framework (e.g. odp-dpdk).
    rdma-core
    # Requested by pkg-config.
    (libbsd.override { inherit libmd; })
  ];

  postPatch = ''
    patchShebangs config/arm buildtools
    # We have no use for RTE_TRACE at all and it makes things more difficult from a security POV so disable it
    sed -i 's/#define RTE_TRACE 1/#undef RTE_TRACE/g' config/rte_config.h
    # We have no use for receive or transmit callbacks at this time so disable them
    sed -i 's/#define RTE_ETHDEV_RXTX_CALLBACKS 1/#undef RTE_ETHDEV_RXTX_CALLBACKS/g' config/rte_config.h
  '';

  disabledLibs = [
    "acl"
    "argparse"
    "bbdev"
    "bitratestats"
    "bpf"
    "cfgfile"
    "compressdev"
    "cryptodev"
    "dispatcher"
    "distributor"
    "dmadev"
    "efd"
    "eventdev"
    "fib"
    "gpudev"
    "graph"
    "gro"
    "gso"
    "ip_frag"
    "ipsec"
    "jobstats"
    "latencystats"
    "lpm"
    "member"
    "metrics"
    "mldev"
    "node"
    "pcapng"
    "pdcp"
    "pdump"
    "pipeline"
    "port"
    "power"
    "ptr_compress"
    "rawdev"
    "regexdev"
    "reorder"
    "rib"
    "sched"
    "security"
    "table"
    "timer"
    "vhost"
  ];

  disabledDrivers = [
    "baseband/*"
    "bus/ifpga"
    "bus/vdev"
    "bus/vmbus"
    "common/cnxk"
    "common/cpt"
    "common/dpaax"
    "common/iavf"
    "common/octeontx"
    "common/octeontx2"
    "common/qat"
    "common/sfc_efx"
    "compress/*"
    "compress/mlx5"
    "compress/zlib"
    "crypto/*"
    "crypto/aesni_gcm"
    "crypto/aesni_mb"
    "crypto/bcmfs"
    "crypto/ccp"
    "crypto/kasumi"
    "crypto/mlx5"
    "crypto/nitrox"
    "crypto/null"
    "crypto/openssl"
    "crypto/scheduler"
    "crypto/snow3g"
    "crypto/virtio"
    "crypto/zuc"
    "event/dlb"
    "event/dsw"
    "event/opdl"
    "event/skeleton"
    "event/sw"
    "net/acc100"
    "net/af_xdp"
    "net/ark"
    "net/atlantic"
    "net/avp"
    "net/axgbe"
    "net/bcmfs"
    "net/bnx2x"
    "net/bnxt"
    "net/bond"
    "net/caam_jr"
    "net/ccp"
    "net/cnxk"
    "net/cnxk_bphy"
    "net/cpt"
    "net/cxgbe"
    "net/dlb2"
    "net/dpaa"
    "net/dpaa2"
    "net/dpaa2_cmdif"
    "net/dpaa2_qdma"
    "net/dpaa2_sec"
    "net/dpaa_sec"
    "net/dpaax"
    "net/dsw"
    "net/ena"
    "net/enetc"
    "net/enic"
    "net/failsafe"
    "net/fm10k"
    "net/fpga_5gnr_fec"
    "net/fpga_lte_fec"
    "net/fslmc"
    "net/hinic"
    "net/hns3"
    "net/iavf"
    "net/ifc"
    "net/ifpga"
    "net/igc"
    "net/intel/i40e"
    "net/ioat"
    "net/ionic"
    "net/ipn3ke"
    "net/ixgbe"
    "net/kasumi"
    "net/kni"
    "net/liquidio"
    "net/mlx4"
    "net/netvsc"
    "net/nfp"
    "net/ngbe"
    "net/nitrox"
    "net/ntb"
    "net/null"
    "net/octeontx"
    "net/octeontx2"
    "net/octeontx2_dma"
    "net/octeontx2_ep"
    "net/octeontx_ep"
    "net/opdl"
    "net/pcap"
    "net/pfe"
    "net/qede"
    "net/sfc"
    "net/sfc_efx"
    "net/skeleton"
    "net/snow3g"
    "net/softnic"
    "net/tap"
    "net/thunderx"
    "net/turbo_sw"
    "net/txgbe"
    "net/vdev"
    "net/vdev_netvsc"
    "net/vhost"
    "net/vmbus"
    "net/vmxnet3"
    "net/zuc"
    "raw/*"
    "raw/ioat"
    "raw/ntb"
    "raw/skeleton"
    "regex/*"
    "regex/mlx5"
    "vdpa/*"
    "vdpa/ifc"
    "vdpa/mlx5"
  ];

  enabledDrivers = [
    "bus/auxiliary"
    "bus/pci"
    "common/mlx5"
    "mempool/bucket"
    "mempool/ring"
    "mempool/stack"
    "net/af_packet"
    "net/auxiliary"
    "net/intel/e1000"
    "net/memif"
    "net/mlx5"
    "net/ring"
    "net/virtio"
  ];

  mesonFlags = [
    "--buildtype=release"
    "-Dauto_features=disabled"
    "-Db_colorout=never"
    "-Db_coverage=false"
    "-Db_lto=true"
    "-Db_lundef=true"
    "-Db_pch=true"
    "-Db_pgo=off"
    "-Db_pie=true"
    "-Db_sanitize=none"
    "-Dbackend=ninja"
    "-Ddefault_library=static"
    "-Denable_docs=false"
    "-Denable_driver_sdk=false"
    "-Dibverbs_link=static"
    "-Dmax_numa_nodes=4"
    "-Dstrip=false" # We should strip binaries in a separate step to preserve detached debug info
    "-Dtests=false" # Running DPDK tests in CI is usually silly
    "-Duse_hpet=false" # TODO: compile kernel with CONFIG_HPET_MMAP=Y
    "-Db_lto_mode=thin"
    "-Ddebug=true"
    ''-Ddisable_drivers=${lib.concatStringsSep "," disabledDrivers}''
    ''-Denable_drivers=${lib.concatStringsSep "," enabledDrivers}''
    ''-Ddisable_libs=${lib.concatStringsSep "," disabledLibs}''
  ];

  postInstall = ''
    # Remove Sphinx cache files. Not only are they not useful, but they also
    # contain store paths causing spurious dependencies.
    rm -rf $out/share/doc/dpdk/html/.doctrees

    wrapProgram $out/bin/dpdk-devbind.py \
      --prefix PATH : "${lib.makeBinPath [ pciutils ]}"
  ''
  + lib.optionalString (withExamples != [ ]) ''
    mkdir -p $examples/bin
    find examples -type f -executable -exec install {} $examples/bin \;
  '';

  outputs = [ "out" ] ++ lib.optional (withExamples != [ ]) "examples";

  meta = with lib; {
    description = "Set of libraries and drivers for fast packet processing";
    homepage = "http://dpdk.org/";
    license = with licenses; [
      lgpl21
      gpl2
      bsd2
    ];
    platforms = platforms.linux;
  };
}
