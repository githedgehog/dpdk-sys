set unstable
set shell := ["bash", "-euo", "pipefail", "-c"]
set script-interpreter := ["bash", "-euo", "pipefail"]

# Turn on debug_mode if you want to `set -x` all the just [script] recipes
debug := "false"

# The version of the rust compiler to include.
# These versions are pinned by the `./nix/versions.nix`
# file (which is managed by `./scripts/update-version-pinning.sh`)
rust := "stable"
container_repo := "ghcr.io/githedgehog/dpdk-sys"

# This is the maximum number of builds nix will start at a time.
# You can jump this up to 8 or 16 if you have a really powerful machine.
# Be careful tho, LLVM is a memory hog of a build.
max_nix_builds := "1"

# This is the path to the versions.nix file that contains the nixpkgs version information
# It is a safe bet that the current ./nix/versions.nix file is what you want unless you are
# trying to jump back in time to a previous version of nixpkgs or something.
versions := "./nix/versions.nix"

# semi private (override if you really need to)

# Setting this to "false" will disable pulling derivations from the nix cache.

# If you turn this to "false" with an empty /nix/store, then you will have to rebuild
# _everything_.
# The rebuild will be massive!
# On the other hand, setting this to "false" will allow you to test
# the reproducibility of the entire dependency graph.
#
# NOTE: if you already have packages cached they will still be used.
# You would need to clear out /nix/store to truly force a rebuild of everything.
nix_substitute := "true"

# private fields (do not override)

# The git tree state (clean or dirty)
_clean := ```
  set -euo pipefail
  (
    git diff-index --quiet HEAD -- && \
    test -z "$(git ls-files --exclude-standard --others)" && \
    echo clean \
  ) || echo dirty
```
# The git commit hash of the last commit to HEAD
_commit := `git rev-parse HEAD`
# The git branch we are currnetly on
_branch := `git rev-parse --abbrev-ref HEAD`
# The slug is the branch name (sanitized) with a marker if the tree is dirty
_slug := (if _clean == "clean" { "" } else { "dirty-_-" }) + _branch

# The name of the dev-env container
_dev_env_container_name := container_repo + "/dev-env"
# The name of the doc-env container
_doc_env_container_name := container_repo + "/doc-env"
# The name of the compile-env container
_compile_env_container_name := container_repo + "/compile-env"

# This is a unique identifier for the build.
# We temporarily tag our containers with this id so that we can be certain that we are
# not retagging or pushing some other container.
_build-id := uuid()
_just_debug_ := if debug == "true" { "set -x" } else { "" }
_build_time := datetime_utc("%+")

# Compute the default number of jobs to use as a guess to try and keep the build within the memory limits
# of the system
cores := `./scripts/estimate-jobs.sh`

[private]
@default:
  just --list --justfile {{justfile()}}

# Install the nix package manager (in single user mode)
[script]
install-nix:
  {{_just_debug_}}
  sh <(curl -L https://nixos.org/nix/install) --no-daemon

[private]
[script]
_nix_build attribute:
  {{_just_debug_}}
  mkdir -p /tmp/dpdk-sys/builds
  nix build  \
    --option substitute "{{nix_substitute}}" \
    --keep-failed  \
    --print-build-logs \
    --show-trace \
    -f default.nix \
    "{{attribute}}" \
    --out-link "/tmp/dpdk-sys/builds/{{attribute}}" \
    --argstr container-repo "{{container_repo}}" \
    --argstr image-tag "{{_build-id}}" \
    --argstr rust-channel "{{rust}}" \
    "-j{{max_nix_builds}}" \
    `if [ "{{cores}}" != "all" ]; then echo --cores "{{cores}}"; fi`

# Build only the sysroot
[script]
build-sysroot: (_nix_build "sysroot")
  {{_just_debug_}}

# Builds and post processes a container from the nix build
[private]
[script]
_build-container target container-name: (_nix_build ("container." + target))
  {{_just_debug_}}
  declare build_date
  build_date="$(date --utc --iso-8601=date --date="{{_build_time}}")"
  declare -r build_date
  docker load --input /tmp/dpdk-sys/builds/container.{{target}}
  docker tag \
    "{{container-name}}:{{_build-id}}" \
    "{{container-name}}:{{_slug}}-rust-{{rust}}"
  docker tag \
    "{{container-name}}:{{_build-id}}" \
    "{{container-name}}:{{_slug}}-rust-{{rust}}-{{_commit}}"
  docker build \
    --label "git.commit={{_commit}}" \
    --label "git.branch={{_branch}}" \
    --label "git.tree-state={{_clean}}" \
    --label "build.date=${build_date}" \
    --label "build.timestamp={{_build_time}}" \
    --label "rust={{rust}}" \
    --label "rust.version=$(nix eval --raw -f '{{versions}}' 'rust.{{rust}}.version')" \
    --label "rust.channel=$(nix eval --raw -f '{{versions}}' 'rust.{{rust}}.channel')" \
    --label "rust.profile=$(nix eval --raw -f '{{versions}}' 'rust.{{rust}}.profile')" \
    --label "rust.targets=$(nix eval --json -f '{{versions}}' 'rust.{{rust}}.targets')" \
    --label "llvm.version=$(nix eval --raw -f '{{versions}}' 'rust.{{rust}}.llvm')" \
    --label "nixpkgs.git.commit=$(nix eval --raw -f '{{versions}}' 'nixpkgs.commit')" \
    --label "nixpkgs.git.branch=$(nix eval --raw -f '{{versions}}' 'nixpkgs.branch')" \
    --label "nixpkgs.git.commit_date=$(nix eval --raw -f '{{versions}}' 'nixpkgs.commit_date')" \
    --label "nixpkgs.git.source_url=$(nix eval --raw -f '{{versions}}' 'nixpkgs.source_url')" \
    --label "nixpkgs.hash.nix32.packed.sha256=$(nix eval --raw -f '{{versions}}' 'nixpkgs.hash.nix32.packed.sha256')" \
    --label "nixpkgs.hash.nix32.packed.sha512=$(nix eval --raw -f '{{versions}}' 'nixpkgs.hash.nix32.packed.sha512')" \
    --label "nixpkgs.hash.nix32.unpacked.sha256=$(nix eval --raw -f '{{versions}}' 'nixpkgs.hash.nix32.unpacked.sha256')" \
    --label "nixpkgs.hash.tar.sha256=$(nix eval --raw -f '{{versions}}' 'nixpkgs.hash.tar.sha256')" \
    --label "nixpkgs.hash.tar.sha384=$(nix eval --raw -f '{{versions}}' 'nixpkgs.hash.tar.sha384')" \
    --label "nixpkgs.hash.tar.sha512=$(nix eval --raw -f '{{versions}}' 'nixpkgs.hash.tar.sha512')" \
    --label "nixpkgs.hash.tar.sha3_256=$(nix eval --raw -f '{{versions}}' 'nixpkgs.hash.tar.sha3_256')" \
    --label "nixpkgs.hash.tar.sha3_384=$(nix eval --raw -f '{{versions}}' 'nixpkgs.hash.tar.sha3_384')" \
    --label "nixpkgs.hash.tar.sha3_512=$(nix eval --raw -f '{{versions}}' 'nixpkgs.hash.tar.sha3_512')" \
    --label "nixpkgs.hash.tar.blake2b512=$(nix eval --raw -f '{{versions}}' 'nixpkgs.hash.tar.blake2b512')" \
    --label "nixpkgs.hash.tar.blake2s256=$(nix eval --raw -f '{{versions}}' 'nixpkgs.hash.tar.blake2s256')" \
    --label "versions.json=$(nix eval --json -f '{{versions}}')" \
    --build-arg TAG="{{_build-id}}" \
    --tag "{{container-name}}:post-{{_build-id}}" \
    --target "{{target}}" \
    -f Dockerfile \
    .
  docker tag \
    "{{container-name}}:post-{{_build-id}}" \
    "{{container-name}}:{{_slug}}-rust-{{rust}}"
  docker tag \
    "{{container-name}}:post-{{_build-id}}" \
    "{{container-name}}:{{_slug}}-rust-{{rust}}-{{_commit}}"
  docker tag \
    "{{container-name}}:post-{{_build-id}}" \
    "{{container-name}}:${build_date}-{{_slug}}-rust-{{rust}}-{{_commit}}"
  docker rmi "{{container-name}}:{{_build-id}}"
  docker rmi "{{container-name}}:post-{{_build-id}}"

# Build and tag the dev-env container
build-dev-env-container: (_build-container "dev-env" _dev_env_container_name)

# Build and tag the doc-env container
build-doc-env-container: (_build-container "doc-env" _doc_env_container_name)

# Build and tag the dev-env container
build-compile-env-container: (_build-container "compile-env" _compile_env_container_name)

# Build the sysroot, compile-env, and dev-env containers
build: build-sysroot build-compile-env-container build-dev-env-container build-doc-env-container

# Push the compile-env and dev-env containers to the container registry
[script]
push: build
  {{_just_debug_}}
  declare build_date
  build_date="$(date --utc --iso-8601=date --date="{{_build_time}}")"
  declare -r build_date
  docker push "{{_compile_env_container_name}}:{{_slug}}-rust-{{rust}}"
  docker push "{{_compile_env_container_name}}:{{_slug}}-rust-{{rust}}-{{_commit}}"
  docker push "{{_compile_env_container_name}}:${build_date}-{{_slug}}-rust-{{rust}}-{{_commit}}"
  docker push "{{_dev_env_container_name}}:{{_slug}}-rust-{{rust}}"
  docker push "{{_dev_env_container_name}}:{{_slug}}-rust-{{rust}}-{{_commit}}"
  docker push "{{_dev_env_container_name}}:${build_date}-{{_slug}}-rust-{{rust}}-{{_commit}}"
  docker push "{{_doc_env_container_name}}:{{_slug}}-rust-{{rust}}"
  docker push "{{_doc_env_container_name}}:{{_slug}}-rust-{{rust}}-{{_commit}}"
  docker push "{{_doc_env_container_name}}:${build_date}-{{_slug}}-rust-{{rust}}-{{_commit}}"

# Delete all the old generations of the nix store and run the garbage collector
[script]
nix-garbage-collector:
  {{_just_debug_}}
  nix-env --delete-generations old
  nix-store --gc

# Generate the test matrix
[script]
generate-todo-list param=".":
  {{_just_debug_}}
  yq -r -c '[
    {{param}} as $matrix |
    $matrix | keys as $factors |
    [range(0; $factors | length)] as $itr |
    $factors | map($matrix[.]) | combinations as $combinations |
    $itr | map({($factors[.]): $combinations[.]}) | add
  ]' ./builds.yml
