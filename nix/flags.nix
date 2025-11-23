let
  flags = {
    compile = {
      machine = "-mcrc32 -mrtm -msse4 -mssse3 -march=x86-64-v3 -mtune=znver4";
      # note: debug is applied to all profiles: don't include performance compromising flags here.  Add those to the profiles.
      debug = "-ggdb3 -gdwarf-5 -gembed-source";
      security = "-fstack-protector-strong";
      errors = "-Werror=odr -Werror=strict-aliasing";
      profile =
        let
          release = "-O3 -flto=thin";
          profile = "-fprofile-instr-generate -fcoverage-mapping -fno-omit-frame-pointer -fno-sanitize-merge";
        in
        {
          debug = "-Og -fno-inline -fno-omit-frame-pointer";
          inherit release;
          fuzz = "${release} ${profile} -fsanitize=address,leak,undefined,local-bounds";
          fuzz_thread = "${release} ${profile} -fsanitize=thread";
        };
      end = "-Qunused-arguments";
    };
    link =
      let
        release = "-flto=thin -Wl,-O3 -Wl,-z,relro,-z,now";
      in
      {
        linker = "-fuse-ld=lld";
        profile = {
          debug = "";
          inherit release;
          fuzz = "${release} -shared-libasan -fsanitize=address,leak,undefined,local-bounds";
          fuzz_thread = "${release} -fsanitize=thread -Wl,--allow-shlib-undefined";
        };
        end = "-Qunused-arguments";
      };
  };
  cflags =
    type: with flags.compile; "${machine} ${debug} ${security} ${errors} ${profile.${type}} ${end}";
  cxxflags = type: cflags type;
  ldflags = type: with flags.link; "${linker} ${profile.${type}} ${end}";
  configuration = type: {
    profile = type;
    CFLAGS = cflags type;
    CXXFLAGS = cxxflags type;
    LDFLAGS = ldflags type;
  };
in
{
  release = configuration "release";
  debug = configuration "debug";
  fuzz = configuration "fuzz";
  fuzz_thread = configuration "fuzz_thread";
}
