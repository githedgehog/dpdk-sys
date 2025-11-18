set unstable := true
set shell := ["bash", "-euo", "pipefail", "-c"]
set script-interpreter := ["bash", "-euo", "pipefail"]

# Turn on debug_mode if you want to `set -x` all the just [script] recipes

debug := "false"

# The version of the rust compiler to include.
# These versions are pinned by the `./nix/versions.nix`
# file (which is managed by `./scripts/bump.sh`)

rust := "stable"
container_repo := "ghcr.io/githedgehog/dpdk-sys"
profile := "debug"

version_extra := ""
version := `git describe --tags --dirty --always` + version_extra

# Print version that will be used in the build
version:
  @echo "Using version: {{version}}"

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

[private]
_clean := ```
  set -euo pipefail
  (
    git diff-index --quiet HEAD -- && \
    test -z "$(git ls-files --exclude-standard --others)" && \
    echo clean \
  ) || echo dirty
```

# The git commit hash of the last commit to HEAD

[private]
_commit := `git rev-parse HEAD`

# The git branch we are currnetly on
# The slug is the branch name (sanitized) with a marker if the tree is dirty

[private]
_slug := (if _clean == "clean" { "" } else { "dirty." }) + _commit + "." + profile

# The name of the compile-env container

[private]
_compile_env_container_name := container_repo + "/compile-env"
[private]
_frr_container_name := container_repo + "/frr"
[private]
_libc_container_name := container_repo + "/libc-env"
[private]
_debug_container_name := container_repo + "/debug-env"
[private]
_mstflint_container_name := container_repo + "/mstflint"

# This is a unique identifier for the build.
# We temporarily tag our containers with this id so that we can be certain that we are
# not retagging or pushing some other container.

[private]
_build-id := "1"
[private]
_just_debug_ := if debug == "true" { "set -x" } else { "" }
[private]
_build_time := datetime_utc("%+")

# Compute the default number of jobs to use as a guess to try and keep the build within the memory limits
# of the system

cores := `./scripts/estimate-jobs.sh`

[private]
@default:
    just --list --justfile {{ justfile() }}

# Install the nix package manager (in single user mode)
[script]
install-nix:
    {{ _just_debug_ }}
    sh <(curl -L https://nixos.org/nix/install) --no-daemon

[private]
[script]
_nix_build attribute:
    {{ _just_debug_ }}
    mkdir -p /tmp/dpdk-sys/builds
    nix build  \
      --option substitute "{{ nix_substitute }}" \
      --keep-failed  \
      --print-build-logs \
      --show-trace \
      -f default.nix \
      "{{ attribute }}" \
      --out-link "/tmp/dpdk-sys/builds/{{ attribute }}" \
      --argstr container-repo "{{ container_repo }}" \
      --argstr image-tag "{{ _build-id }}" \
      --argstr rust-channel "{{ rust }}" \
      "-j{{ max_nix_builds }}" \
      `if [ "{{ cores }}" != "all" ]; then echo --cores "{{ cores }}"; fi`

# Build the sysroot
build-sysroot: (_nix_build "sysroots") (_nix_build "env.sysroot.gnu64.debug") (_nix_build "env.sysroot.gnu64.release") (_nix_build "sysroot")

# Build doc env packages
build-docEnvPackageList: (_nix_build "docEnvPackageList")

# generate version file that'll be injected into containers
[private]
[script]
_gen_version_file:
    echo "{{ version }}" > ./version

# Builds and post processes a container from the nix build
[private]
[script]
_build-container target container-name: _gen_version_file (_nix_build ("container." + target))
    {{ _just_debug_ }}
    declare build_date
    build_date="$(date --utc --iso-8601=date --date="{{ _build_time }}")"
    declare -r build_date
    docker load --input /tmp/dpdk-sys/builds/container.{{ target }}
    docker build \
      --label "git.commit={{ _commit }}" \
      --label "git.tree-state={{ _clean }}" \
      --label "build.date=${build_date}" \
      --label "build.timestamp={{ _build_time }}" \
      --label "rust={{ rust }}" \
      --label "profile={{ profile }}" \
      --label "rust.version=$(nix eval --raw -f '{{ versions }}' 'rust.{{ rust }}.version')" \
      --label "rust.channel=$(nix eval --raw -f '{{ versions }}' 'rust.{{ rust }}.channel')" \
      --label "rust.profile=$(nix eval --raw -f '{{ versions }}' 'rust.{{ rust }}.profile')" \
      --label "rust.targets=$(nix eval --json -f '{{ versions }}' 'rust.{{ rust }}.targets')" \
      --label "llvm.version=$(nix eval --raw -f '{{ versions }}' 'rust.{{ rust }}.llvm')" \
      --label "nixpkgs.git.commit=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.commit')" \
      --label "nixpkgs.git.branch=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.branch')" \
      --label "nixpkgs.git.commit_date=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.commit_date')" \
      --label "nixpkgs.git.source_url=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.source_url')" \
      --label "nixpkgs.hash.nix32.packed.sha256=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.hash.nix32.packed.sha256')" \
      --label "nixpkgs.hash.nix32.packed.sha512=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.hash.nix32.packed.sha512')" \
      --label "nixpkgs.hash.nix32.unpacked.sha256=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.hash.nix32.unpacked.sha256')" \
      --label "nixpkgs.hash.tar.sha256=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.hash.tar.sha256')" \
      --label "nixpkgs.hash.tar.sha384=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.hash.tar.sha384')" \
      --label "nixpkgs.hash.tar.sha512=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.hash.tar.sha512')" \
      --label "nixpkgs.hash.tar.sha3_256=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.hash.tar.sha3_256')" \
      --label "nixpkgs.hash.tar.sha3_384=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.hash.tar.sha3_384')" \
      --label "nixpkgs.hash.tar.sha3_512=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.hash.tar.sha3_512')" \
      --label "nixpkgs.hash.tar.blake2b512=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.hash.tar.blake2b512')" \
      --label "nixpkgs.hash.tar.blake2s256=$(nix eval --raw -f '{{ versions }}' 'nixpkgs.hash.tar.blake2s256')" \
      --label "versions.json=$(nix eval --json -f '{{ versions }}')" \
      --build-arg IMAGE="{{ container-name }}:{{ _build-id }}" \
      --tag "{{ container-name }}:post-{{ _build-id }}" \
      --target {{ target }} \
      -f Dockerfile \
      .
    docker tag \
      "{{ container-name }}:post-{{ _build-id }}" \
      "{{ container-name }}:{{ _slug }}"
    docker rmi "{{ container-name }}:{{ _build-id }}"
    docker rmi "{{ container-name }}:post-{{ _build-id }}"

# Build and tag the compile-env container
build-compile-env-container: build-sysroot (_build-container "compile-env" _compile_env_container_name)

# build and push the compile-env container
[script]
push-compile-env-container: build-compile-env-container
    {{ _just_debug_ }}
    docker push "{{ _compile_env_container_name }}:{{ _slug }}"

# Build and tag the frr container
build-frr-container: (_build-container "frr-" + profile _frr_container_name)

# build and push the frr container
[script]
push-frr-container: build-frr-container
    {{ _just_debug_ }}
    docker push "{{ _frr_container_name }}:{{ _slug }}"

# Build and tag the libc container
build-libc-container: (_build-container "libc-env" _libc_container_name)

# build and push the libc container
[script]
push-libc-container: build-libc-container
    {{ _just_debug_ }}
    docker push "{{ _libc_container_name }}:{{ _slug }}"

# Build and tag the debug container
build-debug-container: (_build-container "debug-env" _debug_container_name)

# build and push the libc container
[script]
push-debug-container: build-debug-container
    {{ _just_debug_ }}
    docker push "{{ _debug_container_name }}:{{ _slug }}"

# Build and tag the libc container
build-mstflint-container: (_build-container "mstflint-" + profile _mstflint_container_name)

# build and push the libc container
[script]
push-mstflint-container: build-mstflint-container
    {{ _just_debug_ }}
    docker push "{{ _mstflint_container_name }}:{{ _slug }}"

# Build the sysroot, and compile-env containers
build: \
  build-libc-container \
  build-debug-container \
  build-compile-env-container \
  build-frr-container

# Push the containers to the container registry
[script]
push: \
  push-libc-container \
  push-debug-container \
  push-compile-env-container \
  push-frr-container

# Delete all the old generations of the nix store and run the garbage collector
[script]
nix-garbage-collector:
    {{ _just_debug_ }}
    nix-env --delete-generations old
    nix-store --gc

# Generate the test matrix
[script]
generate-todo-list param=".":
    {{ _just_debug_ }}
    yq -r -c '[
      {{ param }} as $matrix |
      $matrix | keys as $factors |
      [range(0; $factors | length)] as $itr |
      $factors | map($matrix[.]) | combinations as $combinations |
      $itr | map({($factors[.]): $combinations[.]}) | add
    ]' ./builds.yml

[script]
bump dpdk_sys_branch="main":
    {{ _just_debug_ }}
    ./scripts/bump.sh {{ dpdk_sys_branch }}
