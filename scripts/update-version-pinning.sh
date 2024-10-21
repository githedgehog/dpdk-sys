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

declare nixpkgs_repo
nixpkgs_repo="$(mktemp --directory --suffix=.nixpkgs)"
declare -r nixpkgs_repo

git clone --depth=1 --branch "${NIXPKGS_BRANCH}" "https://github.com/NixOS/nixpkgs" "${nixpkgs_repo}"
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

wget --quiet --output-document="${nixpkgs_repo}/${NIXPKGS_BRANCH}.tar.gz" "${NIXPKGS_SOURCE_URL}"

hash_file() {
  declare -r algo="$1"
  declare -r file="$2"
  openssl dgst "-${algo}" < "${file}" | cut -d' ' -f2
}

declare NIXPKGS_TAR_SHA256
declare NIXPKGS_TAR_SHA384
declare NIXPKGS_TAR_SHA512
declare NIXPKGS_TAR_SHA3_256
declare NIXPKGS_TAR_SHA3_384
declare NIXPKGS_TAR_SHA3_512

declare -r nixpkgs_tar_file="${nixpkgs_repo}/${NIXPKGS_BRANCH}.tar.gz"

NIXPKGS_TAR_SHA256="$(hash_file sha256 "${nixpkgs_tar_file}")"
NIXPKGS_TAR_SHA384="$(hash_file sha384 "${nixpkgs_tar_file}")"
NIXPKGS_TAR_SHA512="$(hash_file sha512 "${nixpkgs_tar_file}")"
NIXPKGS_TAR_SHA3_256="$(hash_file sha3-256 "${nixpkgs_tar_file}")"
NIXPKGS_TAR_SHA3_384="$(hash_file sha3-384 "${nixpkgs_tar_file}")"
NIXPKGS_TAR_SHA3_512="$(hash_file sha3-512 "${nixpkgs_tar_file}")"

declare -rx NIXPKGS_TAR_SHA256
declare -rx NIXPKGS_TAR_SHA384
declare -rx NIXPKGS_TAR_SHA512
declare -rx NIXPKGS_TAR_SHA3_256
declare -rx NIXPKGS_TAR_SHA3_384
declare -rx NIXPKGS_TAR_SHA3_512

declare -rx NIXPKGS_NIX_HASH_TYPE=sha256
declare NIXPKGS_NIX_HASH
NIXPKGS_NIX_HASH="$(nix-prefetch-url --name "${NIXPKGS_BRANCH}" --type "${NIXPKGS_NIX_HASH_TYPE}" --unpack "${NIXPKGS_SOURCE_URL}")"
declare -rx NIXPKGS_NIX_HASH

declare -rx RUST_STABLE="1.82.0"
declare -rx RUST_STABLE_LLVM="19"

pushd "${project_dir}"
envsubst < "${project_dir}/nix/versions.nix.template" > "${project_dir}/nix/versions.nix"
