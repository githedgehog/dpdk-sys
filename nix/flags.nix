rec {
  machine = "-mcrc32 -mrtm -msse4 -mssse3 -march=x86-64-v3 -mtune=znver4";
  release = rec {
    CFLAGS = " ${machine} -O3 -ggdb3 -gdwarf-5 -gembed-source -gz -flto=thin -Werror=odr -Werror=strict-aliasing -fstack-protector-strong -Qunused-arguments";
    CXXFLAGS = CFLAGS;
    LDFLAGS = "-flto=thin -fuse-ld=lld -Wl,-O3 -Wl,-z,relro,-z,now -Wl,--thinlto-jobs=6 -Qunused-arguments";
  };

  debug = rec {
    CFLAGS = " ${machine} -Og -ggdb3 -gdwarf-5 -gembed-source -gz -fno-inline -Qunused-arguments";
    CXXFLAGS = CFLAGS;
    LDFLAGS = "-fuse-ld=lld";
  };

}
