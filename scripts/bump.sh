#!/usr/bin/env bash

set -euxo pipefail

declare -rx NIXPKGS_BRANCH="nixpkgs-unstable"
declare -rx DPLANE_RPC_BRANCH="master"
declare -rx DPLANE_PLUGIN_BRANCH="master"
declare -rx FRR_BRANCH="hh-master-10.5"
declare -rx FRR_AGENT_BRANCH="master"
declare -rx PERFTEST_BRANCH="master"

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
rustup toolchain install "stable"
rustup update

declare RUST_STABLE_PIN RUST_STABLE_PIN_LLVM
RUST_STABLE_PIN="$(rustc "+stable" -vV | grep 'release:' | awk '{print $NF}')"
declare RUST_TOOLCHAIN_TOML_HASH
RUST_TOOLCHAIN_TOML_HASH="$(nix-prefetch-url --type sha256 "https://static.rust-lang.org/dist/channel-rust-${RUST_STABLE_PIN}.toml")"
RUST_TOOLCHAIN_TOML_HASH="sha256-$(nix hash convert --from base32 --to base64 --hash-algo sha256 "${RUST_TOOLCHAIN_TOML_HASH}")"
declare -rx RUST_TOOLCHAIN_TOML_HASH
RUST_STABLE_PIN_LLVM="$(rustc "+stable" -vV | grep 'LLVM version:' | awk '{print $NF}' | sed 's/\([0-9]\+\)\.[0-9]\+\.[0-9]\+/\1/')"
declare -rx RUST_STABLE_PIN
declare -rx RUST_STABLE_PIN_LLVM

declare JUST_STABLE_PIN
JUST_STABLE_PIN="$(just --version | grep '^just ' | awk '{print $NF}')"
declare -rx JUST_STABLE_PIN

declare dplane_rpc_repo
dplane_rpc_repo="$(mktemp --directory --suffix=.dplane-rpc)"
declare -r dplane_rpc_repo

git clone \
  --filter=blob:none \
  --no-checkout \
  --single-branch \
  --depth=1 \
  --branch="${DPLANE_RPC_BRANCH}" \
  "https://github.com/githedgehog/dplane-rpc" \
  "${dplane_rpc_repo}"
cleanup_actions+=("rm -rf ${dplane_rpc_repo}")
pushd "${dplane_rpc_repo}"

declare DPLANE_RPC_COMMIT
DPLANE_RPC_COMMIT="$(git rev-parse HEAD)"
declare -rx DPLANE_RPC_COMMIT

declare DPLANE_RPC_DATA
DPLANE_RPC_DATA="$(nix-prefetch-git --rev "${DPLANE_RPC_COMMIT}" https://github.com/githedgehog/dplane-rpc)"
declare -r DPLANE_RPC_DATA

declare DPLANE_RPC_REV
DPLANE_RPC_REV="$(jq -r .rev <<< "${DPLANE_RPC_DATA}")"
declare -rx DPLANE_RPC_REV

declare DPLANE_RPC_HASH
DPLANE_RPC_HASH="$(jq -r .hash <<< "${DPLANE_RPC_DATA}")"
declare -rx DPLANE_RPC_HASH

declare DPLANE_RPC_COMMIT_DATE
DPLANE_RPC_COMMIT_DATE="$(date --utc --iso-8601=s --date="$(jq -r .date <<< "${DPLANE_RPC_DATA}")")"
declare -rx DPLANE_RPC_COMMIT_DATE

popd

declare dplane_plugin_repo
dplane_plugin_repo="$(mktemp --directory --suffix=.dplane-plugin)"
declare -r dplane_plugin_repo

git clone \
  --filter=blob:none \
  --no-checkout \
  --single-branch \
  --depth=1 \
  --branch="${DPLANE_PLUGIN_BRANCH}" \
  "https://github.com/githedgehog/dplane-plugin" \
  "${dplane_plugin_repo}"
cleanup_actions+=("rm -rf ${dplane_plugin_repo}")
pushd "${dplane_plugin_repo}"

declare DPLANE_PLUGIN_COMMIT
DPLANE_PLUGIN_COMMIT="$(git rev-parse HEAD)"
declare -rx DPLANE_PLUGIN_COMMIT

declare DPLANE_PLUGIN_DATA
DPLANE_PLUGIN_DATA="$(nix-prefetch-git --rev "${DPLANE_PLUGIN_COMMIT}" https://github.com/githedgehog/dplane-plugin)"
declare -r DPLANE_PLUGIN_DATA

declare DPLANE_PLUGIN_REV
DPLANE_PLUGIN_REV="$(jq -r .rev <<< "${DPLANE_PLUGIN_DATA}")"
declare -rx DPLANE_PLUGIN_REV

declare DPLANE_PLUGIN_HASH
DPLANE_PLUGIN_HASH="$(jq -r .hash <<< "${DPLANE_PLUGIN_DATA}")"
declare -rx DPLANE_PLUGIN_HASH

declare DPLANE_PLUGIN_COMMIT_DATE
DPLANE_PLUGIN_COMMIT_DATE="$(date --utc --iso-8601=s --date="$(jq -r .date <<< "${DPLANE_PLUGIN_DATA}")")"
declare -rx DPLANE_PLUGIN_COMMIT_DATE

popd

declare frr_repo
frr_repo="$(mktemp --directory --suffix=.dplane-plugin)"
declare -r frr_repo

git clone \
  --filter=blob:none \
  --no-checkout \
  --single-branch \
  --depth=1 \
  --branch="${FRR_BRANCH}" \
  "https://github.com/githedgehog/frr" \
  "${frr_repo}"
cleanup_actions+=("rm -rf ${frr_repo}")
pushd "${frr_repo}"

declare FRR_COMMIT
FRR_COMMIT="$(git rev-parse HEAD)"
declare -rx FRR_COMMIT

declare FRR_DATA
FRR_DATA="$(nix-prefetch-git --rev "${FRR_COMMIT}" https://github.com/githedgehog/frr)"
declare -r FRR_DATA

declare FRR_REV
FRR_REV="$(jq -r .rev <<< "${FRR_DATA}")"
declare -rx FRR_REV

declare FRR_HASH
FRR_HASH="$(jq -r .hash <<< "${FRR_DATA}")"
declare -rx FRR_HASH

declare FRR_COMMIT_DATE
FRR_COMMIT_DATE="$(date --utc --iso-8601=s --date="$(jq -r .date <<< "${FRR_DATA}")")"
declare -rx FRR_COMMIT_DATE

declare frr_agent_repo
frr_agent_repo="$(mktemp --directory --suffix=.dplane-plugin)"
declare -r frr_agent_repo

git clone \
  --filter=blob:none \
  --no-checkout \
  --single-branch \
  --depth=1 \
  --branch="${FRR_AGENT_BRANCH}" \
  "https://github.com/githedgehog/frr-agent" \
  "${frr_agent_repo}"
cleanup_actions+=("rm -rf ${frr_agent_repo}")
pushd "${frr_agent_repo}"

declare FRR_AGENT_COMMIT
FRR_AGENT_COMMIT="$(git rev-parse HEAD)"
declare -rx FRR_AGENT_COMMIT

declare FRR_AGENT_DATA
FRR_AGENT_DATA="$(nix-prefetch-git --rev "${FRR_AGENT_COMMIT}" "https://github.com/githedgehog/frr-agent")"
declare -r FRR_AGENT_DATA

declare FRR_AGENT_REV
FRR_AGENT_REV="$(jq -r .rev <<< "${FRR_AGENT_DATA}")"
declare -rx FRR_AGENT_REV

declare FRR_AGENT_HASH
FRR_AGENT_HASH="$(jq -r .hash <<< "${FRR_AGENT_DATA}")"
declare -rx FRR_AGENT_HASH

declare FRR_AGENT_COMMIT_DATE
FRR_AGENT_COMMIT_DATE="$(date --utc --iso-8601=s --date="$(jq -r .date <<< "${FRR_AGENT_DATA}")")"
declare -rx FRR_AGENT_COMMIT_DATE

declare perftest_repo
perftest_repo="$(mktemp --directory --suffix=.perftest)"
declare -r perftest_repo

git clone \
  --filter=blob:none \
  --no-checkout \
  --single-branch \
  --depth=1 \
  --branch="${PERFTEST_BRANCH}" \
  "https://github.com/linux-rdma/perftest" \
  "${perftest_repo}"
cleanup_actions+=("rm -rf ${perftest_repo}")
pushd "${perftest_repo}"

declare PERFTEST_COMMIT
PERFTEST_COMMIT="$(git rev-parse HEAD)"
declare -rx PERFTEST_COMMIT

declare PERFTEST_DATA
PERFTEST_DATA="$(nix-prefetch-git --rev "${PERFTEST_COMMIT}" "https://github.com/linux-rdma/perftest")"
declare -r PERFTEST_DATA

declare PERFTEST_REV
PERFTEST_REV="$(jq -r .rev <<< "${PERFTEST_DATA}")"
declare -rx PERFTEST_REV

declare PERFTEST_HASH
PERFTEST_HASH="$(jq -r .hash <<< "${PERFTEST_DATA}")"
declare -rx PERFTEST_HASH

declare PERFTEST_COMMIT_DATE
PERFTEST_COMMIT_DATE="$(date --utc --iso-8601=s --date="$(jq -r .date <<< "${PERFTEST_DATA}")")"
declare -rx PERFTEST_COMMIT_DATE


declare -rx WARNING="WARNING: This file is generated by the bump.sh script. Do not edit it manually."
envsubst < "${project_dir}/builds.template.yml" > "${project_dir}/builds.yml"
envsubst < "${project_dir}/nix/versions.nix.template" > "${project_dir}/nix/versions.nix"
