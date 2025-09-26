let
  flags = {
    compile = {
      machine = "-mcrc32 -mrtm -msse4 -mssse3 -march=x86-64-v3 -mtune=znver4";
      # note: debug is applied to all profiles: don't include performance compromising flags here.  Add those to the profiles.
      debug = "-ggdb3 -gdwarf-5 -gembed-source -gz";
      security = "-fstack-protector-strong";
      errors = "-Werror=odr -Werror=strict-aliasing";
      profile = {
        debug = "-Og -fno-inline -fno-omit-frame-pointer";
        release = "-O3 -flto=thin";
      };
      end = "-Qunused-arguments";
    };
    link = {
      linker = "-fuse-ld=lld";
      profile = {
        debug = "";
        release = "-flto=thin -Wl,-O3 -Wl,-z,relro,-z,now";
      };
      end = "-Qunused-arguments";
    };
  };
  cflags =
    type: with flags.compile; "${machine} ${debug} ${security} ${errors} ${profile.${type}} ${end}";
  cxxflags = type: cflags type;
  ldflags = type: with flags.link; "${linker} ${profile.${type}} ${end}";
  configuration = type: {
    CFLAGS = cflags type;
    CXXFLAGS = cxxflags type;
    LDFLAGS = ldflags type;
  };
in
{
  release = configuration "release";
  debug = configuration "debug";
}
