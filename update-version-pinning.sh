#!/usr/bin/env bash

set -euxo pipefail

declare -rx NIXPKGS_BRANCH="nixpkgs-unstable"

declare script_dir
script_dir="$(readlink -e "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")")"
declare -r script_dir

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

declare NIXPKGS_DATE
NIXPKGS_DATE="$(date --utc --iso-8601=seconds)"
declare -rx NIXPKGS_DATE

git clone --depth=1 --branch "${NIXPKGS_BRANCH}" "https://github.com/NixOS/nixpkgs" "${nixpkgs_repo}"
cleanup_actions+=("rm -rf ${nixpkgs_repo}")
pushd "${nixpkgs_repo}"

declare NIXPKGS_COMMIT
NIXPKGS_COMMIT="$(git rev-parse HEAD)"
declare -rx NIXPKGS_COMMIT


declare NIXPKGS_SOURCE_URL
NIXPKGS_SOURCE_URL="https://github.com/NixOS/nixpkgs/archive/${NIXPKGS_COMMIT}.tar.gz"
declare -rx NIXPKGS_SOURCE_URL

wget --quiet --output-document="${nixpkgs_repo}/${NIXPKGS_BRANCH}.tar.gz" "${NIXPKGS_SOURCE_URL}"

declare NIXPKGS_TAR_SHA256
declare NIXPKGS_TAR_SHA384
declare NIXPKGS_TAR_SHA512
declare NIXPKGS_TAR_SHA3_256
declare NIXPKGS_TAR_SHA3_384
declare NIXPKGS_TAR_SHA3_512

NIXPKGS_TAR_SHA256="$(openssl dgst -sha2-256 < "${nixpkgs_repo}/${NIXPKGS_BRANCH}.tar.gz" | cut -d' ' -f2)"
NIXPKGS_TAR_SHA384="$(openssl dgst -sha2-384 < "${nixpkgs_repo}/${NIXPKGS_BRANCH}.tar.gz" | cut -d' ' -f2)"
NIXPKGS_TAR_SHA512="$(openssl dgst -sha2-512 < "${nixpkgs_repo}/${NIXPKGS_BRANCH}.tar.gz" | cut -d' ' -f2)"
NIXPKGS_TAR_SHA3_256="$(openssl dgst -sha3-256 < "${nixpkgs_repo}/${NIXPKGS_BRANCH}.tar.gz" | cut -d' ' -f2)"
NIXPKGS_TAR_SHA3_384="$(openssl dgst -sha3-384 < "${nixpkgs_repo}/${NIXPKGS_BRANCH}.tar.gz" | cut -d' ' -f2)"
NIXPKGS_TAR_SHA3_512="$(openssl dgst -sha3-512 < "${nixpkgs_repo}/${NIXPKGS_BRANCH}.tar.gz" | cut -d' ' -f2)"

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

pushd "${script_dir}"
envsubst < "${script_dir}/nix/versions.nix.template" > "${script_dir}/nix/versions.nix"
