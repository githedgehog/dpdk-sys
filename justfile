set unstable
set shell := ["bash", "-euo", "pipefail", "-c"]
set script-interpreter := ["bash", "-euo", "pipefail"]

debug_mode := "false"
export _just_debug_ := if debug_mode == "true" { "set -x" } else { "set +x" }


default_target := "x86_64-unknown-linux-musl"
default_toolchain := "stable"
dev_env_container_name := "ghcr.io/githedgehog/dpdk-sys/dev-env"
compile_env_container_name := "ghcr.io/githedgehog/dpdk-sys/compile-env"
test_container_name := "ghcr.io/githedgehog/dpdk-sys/test-env"
default_llvm_version := "18"
max_nix_jobs := "1"
commit := `git rev-parse HEAD`
slug := `git rev-parse --abbrev-ref HEAD | sed 's/[^a-zA-Z0-9]/_/g'`

# Compute the default number of jobs to use as a guess to try and keep the build within the memory limits
# of the system
jobs_guess := `./scripts/estimate-jobs.sh`

debug_recipe +args="default":
  just debug_mode=true {{args}}

install-nix:
  sh <(curl -L https://nixos.org/nix/install) --no-daemon

_nix_build attribute llvm_version=default_llvm_version cores=jobs_guess:
  @echo MAX JOBS GUESS: {{jobs_guess}}
  mkdir -p /tmp/dpdk-sys-builds
  nix build  \
    --keep-failed  \
    --print-build-logs \
    --show-trace \
    -f default.nix \
    "{{attribute}}" \
    --out-link "/tmp/dpdk-sys-builds/{{attribute}}" \
    --argstr llvm-version "{{llvm_version}}" \
    "-j{{max_nix_jobs}}" \
    `if [ "{{cores}}" != "all" ]; then echo --cores "{{cores}}"; fi`

build-sysroot llvm_version=default_llvm_version cores=jobs_guess: (_nix_build "sysroot" llvm_version cores)

build-dev-env-container llvm_version=default_llvm_version cores=jobs_guess: (_nix_build "container.dev-env" llvm_version cores)
  docker load --input /tmp/dpdk-sys-builds/container.dev-env
  docker tag \
    "{{dev_env_container_name}}-nix:llvm{{llvm_version}}" \
    "{{dev_env_container_name}}-nix:{{slug}}-llvm{{llvm_version}}"
  docker tag \
    "{{dev_env_container_name}}-nix:llvm{{llvm_version}}" \
    "{{dev_env_container_name}}-nix:{{slug}}-llvm{{llvm_version}}-{{commit}}"
  docker build -t "{{dev_env_container_name}}:llvm{{llvm_version}}" -f Dockerfile.dev-env .
  docker tag \
    "{{dev_env_container_name}}:llvm{{llvm_version}}" \
    "{{dev_env_container_name}}:{{slug}}-llvm{{llvm_version}}"
  docker tag \
    "{{dev_env_container_name}}:llvm{{llvm_version}}" \
    "{{dev_env_container_name}}:{{slug}}-llvm{{llvm_version}}-{{commit}}"

build-compile-env-container llvm_version=default_llvm_version cores=jobs_guess: (_nix_build "container.compile-env" llvm_version cores)
  docker load --input /tmp/dpdk-sys-builds/container.compile-env
  docker tag \
    "{{compile_env_container_name}}:llvm{{llvm_version}}" \
    "{{compile_env_container_name}}:{{slug}}-llvm{{llvm_version}}"
  docker tag \
    "{{compile_env_container_name}}:llvm{{llvm_version}}" \
    "{{compile_env_container_name}}:{{slug}}-llvm{{llvm_version}}-{{commit}}"

push-containers llvm_version=default_llvm_version: (build llvm_version)
  docker push "{{compile_env_container_name}}:{{slug}}-llvm{{llvm_version}}"
  docker push "{{compile_env_container_name}}:{{slug}}-llvm{{llvm_version}}-{{commit}}"
  docker push "{{dev_env_container_name}}:{{slug}}-llvm{{llvm_version}}"
  docker push "{{dev_env_container_name}}:{{slug}}-llvm{{llvm_version}}-{{commit}}"

build-containers llvm_version=default_llvm_version cores=jobs_guess: (build-dev-env-container llvm_version cores) (build-compile-env-container llvm_version cores)

build llvm_version=default_llvm_version cores=jobs_guess: (build-sysroot llvm_version cores) (build-containers llvm_version cores)

push llvm_version=default_llvm_version: (push-containers llvm_version)
