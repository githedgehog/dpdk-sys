default_target := "x86_64-unknown-linux-musl"
default_toolchain := "stable"
default_profile := "debug"
container_name := "ghcr.io/githedgehog/dpdk-sys/dev-env"
default_llvm_version := "18"

default: build-container

install-nix:
  sh <(curl -L https://nixos.org/nix/install) --no-daemon

build-container profile=default_profile jobs="1" llvm_version=default_llvm_version:
  nix build  --keep-failed  --print-build-logs --show-trace -f default.nix container.dev-env --out-link container.dev-env --argstr profile "{{profile}}" --argstr llvm-version "{{llvm_version}}" "-j{{jobs}}"
  docker load --input ./container.dev-env
  docker tag "{{container_name}}:{{profile}}-llvm{{llvm_version}}" "{{container_name}}:{{profile}}-llvm{{llvm_version}}-$(git rev-parse HEAD)"

push-container profile=default_profile jobs="1" llvm_version=default_llvm_version: (build-container profile jobs llvm_version)
  docker push "{{container_name}}:{{profile}}-$(git rev-parse HEAD)"
