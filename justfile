default_target := "x86_64-unknown-linux-musl"
default_toolchain := "stable"
default_profile := "debug"
container_name := "ghcr.io/githedgehog/dpdk-sys/dev-env"
default_llvm_version := "18"
max_jobs := "1"
# if unspecified, number of cores will be determined by nix
default_max_cores := "16"
date := `date --utc --iso-8601=date`
commit := `git rev-parse HEAD`

default: build-container

install-nix:
  sh <(curl -L https://nixos.org/nix/install) --no-daemon

# I expect this command is mostly useful for CI
# In CI we have machines with a huge number of cores and not a lot of memory.
# It is easy to drive the system OOM if you let nix have all the cores.
build-container-with-core-limit profile=default_profile llvm_version=default_llvm_version cores=default_max_cores:
  nix build  \
    --keep-failed  \
    --print-build-logs \
    --show-trace \
    -f default.nix \
    container.dev-env \
    --out-link container.dev-env \
    --argstr profile "{{profile}}" \
    --argstr llvm-version "{{llvm_version}}" \
    "-j{{max_jobs}}" \
    `if [ ! -z "{{cores}}" ]; then echo --cores "{{cores}}"; fi`
  docker load --input ./container.dev-env
  docker tag \
    "{{container_name}}:{{profile}}-llvm{{llvm_version}}" \
    "{{container_name}}:{{profile}}-llvm{{llvm_version}}-{{commit}}"
  docker tag \
    "{{container_name}}:{{profile}}-llvm{{llvm_version}}" \
    "{{container_name}}:{{profile}}-llvm{{llvm_version}}-{{date}}"
  docker tag \
    "{{container_name}}:{{profile}}-llvm{{llvm_version}}" \
    "{{container_name}}:{{profile}}-llvm{{llvm_version}}-{{date}}-{{commit}}"

build-container profile=default_profile llvm_version=default_llvm_version: (build-container-with-core-limit profile llvm_version "")

push-container profile=default_profile llvm_version=default_llvm_version: (build-container profile llvm_version)
  docker push "{{container_name}}:{{profile}}-llvm{{llvm_version}}-{{commit}}"
  docker push "{{container_name}}:{{profile}}-llvm{{llvm_version}}-{{date}}"
  docker push "{{container_name}}:{{profile}}-llvm{{llvm_version}}-{{date}}-{{commit}}"
