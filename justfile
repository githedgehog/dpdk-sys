default_target := "x86_64-unknown-linux-musl"
default_toolchain := "stable"
default_profile := "debug"
container_name := "ghcr.io/githedgehog/dpdk-sys/dev-env"

default: build-container

install-nix:
  sh <(curl -L https://nixos.org/nix/install) --no-daemon

build-container profile=default_profile *args="":
  nix build  --keep-failed  --print-build-logs --show-trace -f default.nix container.dev-env --out-link container.dev-env --argstr profile "{{profile}}" {{args}}
  docker load --input ./container.dev-env
  docker tag "{{container_name}}:{{profile}}" "{{container_name}}:{{profile}}-$(git rev-parse HEAD)"

push-container profile=default_profile:
  docker push "{{container_name}}:{{profile}}-$(git rev-parse HEAD)"
