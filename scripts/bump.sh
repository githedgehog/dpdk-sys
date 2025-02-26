#!/usr/bin/env bash

set -euxo pipefail

declare -rx NIXPKGS_BRANCH="nixpkgs-unstable"

declare project_dir
project_dir="$(readlink -e "$(dirname "$(readlink -e "${BASH_SOURCE[0]}/..")")")"
declare -r project_dir

declare -a cleanup_actions=()

_cleanup() {
  declare action
  for action in "${cleanup_actions[@]}"; do
    ${action}
  done
}
trap _cleanup EXIT

hash_file() {
  declare -r algo="$1"
  declare -r file="$2"
  openssl dgst "-${algo}" < "${file}" | cut -d' ' -f2
}

declare -Ar hash_algos=(
  ["sha256"]="sha256"
  ["sha384"]="sha384"
  ["sha512"]="sha512"
  ["sha3_256"]="sha3-256"
  ["sha3_384"]="sha3-384"
  ["sha3_512"]="sha3-512"
  ["blake2b512"]="blake2b512"
  ["blake2s256"]="blake2s256"
)
declare -Ar nix32_packed_hash_algos=(
  ["sha256"]="sha256"
  ["sha512"]="sha512"
)
declare -Ar nix32_unpacked_hash_algos=(
  ["sha256"]="sha256"
)

declare nixpkgs_repo
nixpkgs_repo="$(mktemp --directory --suffix=.nixpkgs)"
declare -r nixpkgs_repo

git clone \
  --filter=blob:none \
  --no-checkout \
  --single-branch \
  --depth=1 \
  --branch="${NIXPKGS_BRANCH}" \
  "https://github.com/NixOS/nixpkgs" \
  "${nixpkgs_repo}"
cleanup_actions+=("rm -rf ${nixpkgs_repo}")
pushd "${nixpkgs_repo}"

declare NIXPKGS_COMMIT
NIXPKGS_COMMIT="$(git rev-parse HEAD)"
declare -rx NIXPKGS_COMMIT

declare NIXPKGS_COMMIT_DATE
NIXPKGS_COMMIT_DATE="$(date --date="$(git log --pretty=format:%ci -n1)" --utc --iso-8601=seconds)"
declare -rx NIXPKGS_COMMIT_DATE

declare NIXPKGS_SOURCE_URL
NIXPKGS_SOURCE_URL="https://github.com/NixOS/nixpkgs/archive/${NIXPKGS_COMMIT}.tar.gz"
declare -rx NIXPKGS_SOURCE_URL

wget "${NIXPKGS_SOURCE_URL}" -O "${nixpkgs_repo}/${NIXPKGS_COMMIT}.tar.gz"
nix_multi_hash() {
  declare -n dict="${1}"
  declare -r file="${2}"
  declare -r source_url="${3}"
  declare hash
  for hash in "${!hash_algos[@]}"; do
    dict["openssl_${hash}"]="$(hash_file "${hash_algos[${hash}]}" "${file}")"
    declare -rxg "${1}_openssl_${hash}"="${dict["openssl_${hash}"]}"
  done
  for hash in "${!nix32_packed_hash_algos[@]}"; do
    dict["expected_nix32_packed_${hash}"]="$(nix hash convert --from base16 --to nix32 --hash-algo "${hash}" "${dict["openssl_${hash}"]}")"
    dict["nix32_packed_${hash}"]="$(nix-prefetch-url --type "${hash}" "file://${file}" "${dict["expected_nix32_packed_${hash}"]}")"
    declare -rxg "${1}_nix32_packed_${hash}"="${dict["nix32_packed_${hash}"]}"
  done
  for hash in "${!nix32_unpacked_hash_algos[@]}"; do
    dict["nix32_unpacked_${hash}"]="$(nix-prefetch-url --unpack --type "${hash}" "file://${file}")"
    nix-prefetch-url --unpack --type "${hash}" "${source_url}" "${dict["nix32_unpacked_${hash}"]}"
    declare -rxg "${1}_nix32_unpacked_${hash}"="${dict["nix32_unpacked_${hash}"]}"
  done
}

# shellcheck disable=SC2034
declare -A NIXPKGS_ARCHIVE
nix_multi_hash NIXPKGS_ARCHIVE "${nixpkgs_repo}/${NIXPKGS_COMMIT}.tar.gz" "${NIXPKGS_SOURCE_URL}"

pushd "${project_dir}"

rustup update
rustup toolchain install "beta"
rustup update

declare RUST_BETA_PIN RUST_BETA_PIN_LLVM
RUST_BETA_PIN="$(rustc "+beta" -vV | grep 'release:' | awk '{print $NF}')"
RUST_BETA_PIN_LLVM="$(rustc "+beta" -vV | grep 'LLVM version:' | awk '{print $NF}' | sed 's/\([0-9]\+\)\.[0-9]\+\.[0-9]\+/\1/')"
declare -rx RUST_BETA_PIN
declare -rx RUST_BETA_PIN_LLVM

declare JUST_STABLE_PIN
JUST_STABLE_PIN="$(just --version | grep '^just ' | awk '{print $NF}')"
declare -rx JUST_STABLE_PIN

declare -rx WARNING="WARNING: This file is generated by the bump.sh script. Do not edit it manually."
envsubst < "${project_dir}/builds.template.yml" > "${project_dir}/builds.yml"
envsubst < "${project_dir}/nix/versions.nix.template" > "${project_dir}/nix/versions.nix"
