{
  release = rec {
    CFLAGS="-O3 -ggdb3 -march=x86-64-v4 -mtune=znver4 -flto=thin -Werror=odr -Werror=strict-aliasing -fstack-protector-strong -Qunused-arguments";
    CXXFLAGS=CFLAGS;
    LDFLAGS="-Wl,-O3 -Wl,--gc-sections -Wl,-z,relro,-z,now -Qunused-arguments";
  };

  debug = rec {
    CFLAGS="-Og -ggdb3 -fno-inline -Qunused-arguments";
    CXXFLAGS=CFLAGS;
    LDFLAGS="";
  };
}
