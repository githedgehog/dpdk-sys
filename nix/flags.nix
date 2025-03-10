rec {
  machine = "-mcrc32 -mrtm -msse4 -mssse3 -march=x86-64-v3 -mtune=znver4";
  release = rec {
    CFLAGS = " ${machine} -O3 -ggdb3 -flto=thin -Werror=odr -Werror=strict-aliasing -fstack-protector-strong -Qunused-arguments";
    CXXFLAGS = CFLAGS;
    LDFLAGS = "-fuse-ld=lld -Wl,-O3 -Wl,--gc-sections -Wl,-z,relro,-z,now -Wl,--thinlto-jobs=1 -Wl,-plugin-opt,jobs=1 -Qunused-arguments";
  };

  dev = rec {
    CFLAGS = " ${machine} -Og -ggdb3 -fno-inline -Qunused-arguments";
    CXXFLAGS = CFLAGS;
    LDFLAGS = "-fuse-ld=lld";
  };
}
