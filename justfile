set shell := ["bash", "-euxo", "pipefail", "-c"]
default_target := "x86_64-unknown-linux-musl"
default_toolchain := "stable"
default_profile := "debug"
container_name := "ghcr.io/githedgehog/dpdk-sys/dev-env"
default_llvm_version := "18"
max_nix_jobs := "1"
date := `date --utc --iso-8601=seconds | sed 's/[:+]/_/g'`
commit := `git rev-parse HEAD`
# Compute the default number of jobs to use as a guess to try and keep the build within the memory limits
# of the system
jobs_guess := `
  # measure total free memory
  free_memory=$(( $(grep MemFree /proc/meminfo | awk '{print $2}') / 1024**2 ));
  # guess worst case memory load per core for build (GiB)
  max_mem_per_core_guess=6;
  # guess the max number of cores we can safely use
  max_cores_guess=$(( $free_memory / $max_mem_per_core_guess ));
  # check if we have at least one core
  max_cores_guess=$(if [ $max_cores_guess -lt 1 ]; then echo 1; else echo ${max_cores_guess}; fi);
  # ensure we didn't guess more cores than the system has
  if [ ${max_cores_guess} -gt $(nproc) ]; then echo $(nproc); else echo ${max_cores_guess}; fi;
`


default: build-container

install-nix:
  sh <(curl -L https://nixos.org/nix/install) --no-daemon

build-container profile=default_profile llvm_version=default_llvm_version cores=jobs_guess:
  @echo MAX JOBS GUESS: {{jobs_guess}}
  nix build  \
    --keep-failed  \
    --print-build-logs \
    --show-trace \
    -f default.nix \
    container.dev-env \
    --out-link container.dev-env \
    --argstr profile "{{profile}}" \
    --argstr llvm-version "{{llvm_version}}" \
    "-j{{max_nix_jobs}}" \
    `if [ "{{cores}}" != "all" ]; then echo --cores "{{cores}}"; fi`
  docker load --input ./container.dev-env
  docker tag \
    "{{container_name}}:{{profile}}-llvm{{llvm_version}}" \
    "{{container_name}}:{{date}}-{{profile}}-llvm{{llvm_version}}-{{commit}}"
  docker tag \
    "{{container_name}}:{{profile}}-llvm{{llvm_version}}" \
    "{{container_name}}:{{date}}-{{profile}}-llvm{{llvm_version}}"

push-container profile=default_profile llvm_version=default_llvm_version: (build-container profile llvm_version)
  docker push "{{container_name}}:{{date}}-{{profile}}-llvm{{llvm_version}}-{{commit}}"
  docker push "{{container_name}}:{{date}}-{{profile}}-llvm{{llvm_version}}"
