set unstable
set shell := ["bash", "-euo", "pipefail", "-c"]
set script-interpreter := ["bash", "-euo", "pipefail"]

debug_mode := "false"
export _just_debug_ := if debug_mode == "true" { "set -x" } else { "" }

target := "x86_64-unknown-linux-musl"
rust := "stable"
container_repo := "ghcr.io/githedgehog/dpdk-sys"
dev_env_container_name := container_repo + "/dev-env"
compile_env_container_name := container_repo + "/compile-env"
test_env_container_name := container_repo + "/test-env"
llvm := "19"
max_nix_builds := "1"
commit := `git rev-parse HEAD`
clean := `git diff-index --quiet HEAD -- && echo clean || echo dirty`
branch := `git rev-parse --abbrev-ref HEAD`
slug := (if clean == "clean" { "" } else { "dirty-_-" }) + branch
versions := "./nix/versions.nix"
_build-id := `uuidgen --random`
build-date := `date --iso-8601=seconds --utc | sed -e 's/[-:+]/_/g'`

# Compute the default number of jobs to use as a guess to try and keep the build within the memory limits
# of the system
jobs_guess := `./scripts/estimate-jobs.sh`

is_clean:
  echo {{clean}}

debug_recipe +args="default":
  just debug_mode=true {{args}}

install-nix:
  sh <(curl -L https://nixos.org/nix/install) --no-daemon

_nix_build attribute llvm=llvm cores=jobs_guess:
  @echo MAX JOBS GUESS: {{jobs_guess}}
  mkdir -p /tmp/dpdk-sys-builds
  nix build  \
    --option substitute false \
    --keep-failed  \
    --print-build-logs \
    --show-trace \
    -f default.nix \
    "{{attribute}}" \
    --out-link "/tmp/dpdk-sys-builds/{{attribute}}" \
    --argstr image-tag "{{_build-id}}" \
    --argstr llvm-version "{{llvm}}" \
    --argstr versions-file "{{versions}}" \
    "-j{{max_nix_builds}}" \
    `if [ "{{cores}}" != "all" ]; then echo --cores "{{cores}}"; fi`

build-sysroot llvm=llvm cores=jobs_guess: (_nix_build "sysroot" llvm cores)

build-dev-env-container llvm=llvm cores=jobs_guess: (_nix_build "container.dev-env" llvm cores)
  docker load --input /tmp/dpdk-sys-builds/container.dev-env
  docker tag \
    "{{dev_env_container_name}}:{{_build-id}}" \
    "{{dev_env_container_name}}:{{slug}}-llvm{{llvm}}"
  docker tag \
    "{{dev_env_container_name}}:{{_build-id}}" \
    "{{dev_env_container_name}}:{{slug}}-llvm{{llvm}}-{{commit}}"
  docker build \
    --label "git.commit={{commit}}" \
    --label "git.branch={{branch}}" \
    --label "git.tree-state={{clean}}" \
    --label "build.date={{build-date}}" \
    --label "version.llvm={{llvm}}" \
    --label "version.nixpkgs.hash.nar.sha256=$(nix eval -f '{{versions}}' 'nixpkgs.hash.nar.sha256')" \
    --label "version.nixpkgs.hash.tar.sha256=$(nix eval -f '{{versions}}' 'nixpkgs.hash.tar.sha256')" \
    --label "version.nixpkgs.hash.tar.sha384=$(nix eval -f '{{versions}}' 'nixpkgs.hash.tar.sha384')" \
    --label "version.nixpkgs.hash.tar.sha512=$(nix eval -f '{{versions}}' 'nixpkgs.hash.tar.sha512')" \
    --label "version.nixpkgs.hash.tar.sha3_256=$(nix eval -f '{{versions}}' 'nixpkgs.hash.tar.sha3_256')" \
    --label "version.nixpkgs.hash.tar.sha3_384=$(nix eval -f '{{versions}}' 'nixpkgs.hash.tar.sha3_384')" \
    --label "version.nixpkgs.hash.tar.sha3_512=$(nix eval -f '{{versions}}' 'nixpkgs.hash.tar.sha3_512')" \
    --build-arg IMAGE="{{dev_env_container_name}}" \
    --build-arg TAG="{{_build-id}}" \
    --tag "{{dev_env_container_name}}:post-{{_build-id}}" \
    -f Dockerfile.dev-env \
    .
  docker tag \
    "{{dev_env_container_name}}:post-{{_build-id}}" \
    "{{dev_env_container_name}}:{{slug}}-llvm{{llvm}}"
  docker tag \
    "{{dev_env_container_name}}:post-{{_build-id}}" \
    "{{dev_env_container_name}}:{{slug}}-llvm{{llvm}}-{{commit}}"
  docker tag \
    "{{dev_env_container_name}}:post-{{_build-id}}" \
    "{{dev_env_container_name}}:{{build-date}}-{{slug}}-llvm{{llvm}}-{{commit}}"
  docker rmi "{{dev_env_container_name}}:{{_build-id}}"
  docker rmi "{{dev_env_container_name}}:post-{{_build-id}}"

build-compile-env-container llvm=llvm cores=jobs_guess: (_nix_build "container.compile-env" llvm cores)
  docker load --input /tmp/dpdk-sys-builds/container.compile-env
  docker tag \
    "{{compile_env_container_name}}:{{_build-id}}" \
    "{{compile_env_container_name}}:{{slug}}-llvm{{llvm}}"
  docker tag \
    "{{compile_env_container_name}}:{{_build-id}}" \
    "{{compile_env_container_name}}:{{slug}}-llvm{{llvm}}-{{commit}}"
  docker tag \
    "{{compile_env_container_name}}:{{_build-id}}" \
    "{{compile_env_container_name}}:{{build-date}}-{{slug}}-llvm{{llvm}}-{{commit}}"
  docker rmi "{{compile_env_container_name}}:{{_build-id}}"

push-containers llvm=llvm: (build llvm)
  docker push "{{compile_env_container_name}}:{{slug}}-llvm{{llvm}}"
  docker push "{{compile_env_container_name}}:{{slug}}-llvm{{llvm}}-{{commit}}"
  docker push "{{dev_env_container_name}}:{{slug}}-llvm{{llvm}}"
  docker push "{{dev_env_container_name}}:{{slug}}-llvm{{llvm}}-{{commit}}"

build-containers llvm=llvm cores=jobs_guess: (build-dev-env-container llvm cores) (build-compile-env-container llvm cores)

build llvm=llvm cores=jobs_guess: (build-sysroot llvm cores) (build-containers llvm cores)

push llvm=llvm: (push-containers llvm)
