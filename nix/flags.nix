rec {
  machine = "-mcrc32 -mrtm -msse4 -mssse3 -march=x86-64-v3 -mtune=znver4";
  debug_flags = "-ggdb3 -gdwarf-5";
  release = rec {
    CFLAGS = " ${machine} ${debug_flags} -O3 -flto=thin -Werror=odr -Werror=strict-aliasing -fstack-protector-strong -Qunused-arguments";
    CXXFLAGS = CFLAGS;
    LDFLAGS = "-flto=thin -fuse-ld=lld -Wl,-O3 -Wl,-z,relro,-z,now -Wl,--thinlto-jobs=6 -Qunused-arguments";
  };

  debug = rec {
    CFLAGS = " ${machine} ${debug_flags} -Og -fno-inline -Qunused-arguments";
    CXXFLAGS = CFLAGS;
    LDFLAGS = "-fuse-ld=lld";
  };

}
