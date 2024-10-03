set shell := ["bash", "-euxo", "pipefail", "-c"]
default_target := "x86_64-unknown-linux-musl"
default_toolchain := "stable"
container_name := "ghcr.io/githedgehog/dpdk-sys/dev-env"
default_llvm_version := "18"
max_nix_jobs := "1"
commit := `git rev-parse HEAD`
slug := `git rev-parse --abbrev-ref HEAD | sed 's/[^a-zA-Z0-9]/_/g'`
# Compute the default number of jobs to use as a guess to try and keep the build within the memory limits
# of the system
jobs_guess := `./scripts/estimate-jobs.sh`

default: build-container

install-nix:
  sh <(curl -L https://nixos.org/nix/install) --no-daemon

_nix_build attribute llvm_version=default_llvm_version cores=jobs_guess:
  @echo MAX JOBS GUESS: {{jobs_guess}}
  nix build  \
    --keep-failed  \
    --print-build-logs \
    --show-trace \
    -f default.nix \
    "{{attribute}}" \
    --out-link "{{attribute}}" \
    --argstr llvm-version "{{llvm_version}}" \
    "-j{{max_nix_jobs}}" \
    `if [ "{{cores}}" != "all" ]; then echo --cores "{{cores}}"; fi`

build-sysroot llvm_version=default_llvm_version cores=jobs_guess: (_nix_build "sysroot" llvm_version cores)

build-container llvm_version=default_llvm_version cores=jobs_guess: (build-sysroot llvm_version cores) (_nix_build "container.dev-env" llvm_version cores)
  docker load --input ./container.dev-env
  docker tag \
    "{{container_name}}:llvm{{llvm_version}}" \
    "{{container_name}}:{{slug}}-llvm{{llvm_version}}"
  docker tag \
    "{{container_name}}:llvm{{llvm_version}}" \
    "{{container_name}}:{{slug}}-llvm{{llvm_version}}-{{commit}}"

push-container llvm_version=default_llvm_version: (build-container llvm_version)
  docker push "{{container_name}}:{{slug}}-llvm{{llvm_version}}"
  docker push "{{container_name}}:{{slug}}-llvm{{llvm_version}}-{{commit}}"

pull-container llvm_version=default_llvm_version:
  docker pull "{{container_name}}:{{slug}}-llvm{{llvm_version}}"
