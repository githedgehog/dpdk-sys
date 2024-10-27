#!/usr/bin/env bash

set -euo pipefail

declare project_dir
project_dir="$(readlink -e "$(dirname "$(readlink -e "${BASH_SOURCE[0]}/..")")")"
declare -r project_dir

declare expected_nix32_sha256_sum
expected_nix32_sha256_sum="$(nix eval --raw --file "${project_dir}/nix/versions.nix" "nixpkgs.hash.nix32.packed.sha256")"
declare -r expected_nix32_sha256_sum

if [ -z "${expected_nix32_sha256_sum}" ]; then
  >&2 echo "FATAL: The nixpkgs sha256 hash is not available!"
  exit 1
fi

declare expected_nix32_sha512_sum
expected_nix32_sha512_sum="$(nix eval --raw --file "${project_dir}/nix/versions.nix" "nixpkgs.hash.nix32.packed.sha512")"
declare -r expected_nix32_sha512_sum

if [ -z "${expected_nix32_sha512_sum}" ]; then
  >&2 echo "FATAL: The nixpkgs sha512 hash is not available!"
  exit 1
fi

# If the file is already in the nix cache, then this will just confirm that the hash matches.
# If the file is not already cached, this will download it and check that the hash matches.
declare nixpkgs_path
nixpkgs_path="$(nix-prefetch-url \
  --type sha256 \
  --name nixpkgs-unstable \
  --print-path \
  "$(nix eval --raw --file ./nix/versions.nix 'nixpkgs.source_url')" \
  "${expected_nix32_sha256_sum}" | tail -n 1
)"
declare -r nixpkgs_path

[ -f "${nixpkgs_path}" ] || { >&2 echo "Could not determine nixpkgs_path"; exit 1; }
[ -r "${nixpkgs_path}" ] || { >&2 echo "Could not read nixpkgs_path"; exit 1; }

echo "OK: Nix sha256 sum for nixpkgs-unstable matches expectations"

# If the file is already in the nix cache, then this will just confirm that the hash matches.
# If the file is not already cached, this will download it and check that the hash matches.
nix-prefetch-url \
  --type sha512 \
  --name nixpkgs-unstable \
  "$(nix eval --raw --file ./nix/versions.nix 'nixpkgs.source_url')" \
  "${expected_nix32_sha512_sum}" &>/dev/null
echo "OK: Nix sha512 sum for nixpkgs-unstable matches expectations"

# Now check that the nix32 encoding of the sha256 matches the openssl encoding of the sha256 for that same file.
declare expected_openssl_sha256_sum
expected_openssl_sha256_sum="$(nix eval --raw --file ./nix/versions.nix "nixpkgs.hash.tar.sha256")"
declare -r expected_openssl_sha256_sum

declare converted_nix32_sha256_sum
converted_nix32_sha256_sum="$(nix hash convert --from nix32 --to base16 --hash-algo sha256 "$expected_nix32_sha256_sum")"
declare -r converted_nix32_sha256_sum

if [ "${expected_openssl_sha256_sum}" != "${converted_nix32_sha256_sum}" ]; then
  >&2 echo "The nix32 sha256 sum does not match the openssl hash!"
  >&2 echo "Expected: ${expected_openssl_sha256_sum}"
  >&2 echo "Got: ${converted_nix32_sha256_sum}"
  exit 1
fi

echo "OK: OpenSSL sha256 sum matches the (converted) nix32-sha256 hash!"

declare expected_openssl_sha512_sum
expected_openssl_sha512_sum="$(nix eval --raw --file ./nix/versions.nix "nixpkgs.hash.tar.sha512")"
declare -r expected_openssl_sha512_sum

declare converted_nix32_sha512_sum
converted_nix32_sha512_sum="$(nix hash convert --from nix32 --to base16 --hash-algo sha512 "$expected_nix32_sha512_sum")"
declare -r converted_nix32_sha512_sum

if [ "${expected_openssl_sha512_sum}" != "${converted_nix32_sha512_sum}" ]; then
  >&2 echo "The nix32 sha512 sum does not match the openssl hash!"
  >&2 echo "Expected: ${expected_openssl_sha512_sum}"
  >&2 echo "Got: ${converted_nix32_sha512_sum}"
  exit 1
fi

echo "OK: OpenSSL sha512 sum matches the (converted) nix32-sha512 hash!"

hash_file() {
  declare -r algo="$1"
  declare -r file="$2"
  openssl dgst "-${algo}" < "${file}" | cut -d' ' -f2
}

declare -A EXPECTED_NIXPKGS_TAR;
EXPECTED_NIXPKGS_TAR[SHA256]="$(nix eval --raw --file ./nix/versions.nix 'nixpkgs.hash.tar.sha256')"
EXPECTED_NIXPKGS_TAR[SHA384]="$(nix eval --raw --file ./nix/versions.nix 'nixpkgs.hash.tar.sha384')"
EXPECTED_NIXPKGS_TAR[SHA512]="$(nix eval --raw --file ./nix/versions.nix 'nixpkgs.hash.tar.sha512')"
EXPECTED_NIXPKGS_TAR[SHA3_256]="$(nix eval --raw --file ./nix/versions.nix 'nixpkgs.hash.tar.sha3_256')"
EXPECTED_NIXPKGS_TAR[SHA3_384]="$(nix eval --raw --file ./nix/versions.nix 'nixpkgs.hash.tar.sha3_384')"
EXPECTED_NIXPKGS_TAR[SHA3_512]="$(nix eval --raw --file ./nix/versions.nix 'nixpkgs.hash.tar.sha3_512')"
EXPECTED_NIXPKGS_TAR[B2B512]="$(nix eval --raw --file ./nix/versions.nix 'nixpkgs.hash.tar.blake2b512')"
EXPECTED_NIXPKGS_TAR[B2S256]="$(nix eval --raw --file ./nix/versions.nix 'nixpkgs.hash.tar.blake2s256')"
declare -Ar EXPECTED_NIXPKGS_TAR

declare -A NIXPKGS_TAR
NIXPKGS_TAR[SHA256]="$(hash_file sha256 "${nixpkgs_path}")"
NIXPKGS_TAR[SHA384]="$(hash_file sha384 "${nixpkgs_path}")"
NIXPKGS_TAR[SHA512]="$(hash_file sha512 "${nixpkgs_path}")"
NIXPKGS_TAR[SHA3_256]="$(hash_file sha3-256 "${nixpkgs_path}")"
NIXPKGS_TAR[SHA3_384]="$(hash_file sha3-384 "${nixpkgs_path}")"
NIXPKGS_TAR[SHA3_512]="$(hash_file sha3-512 "${nixpkgs_path}")"
NIXPKGS_TAR[B2B512]="$(hash_file blake2b512 "${nixpkgs_path}")"
NIXPKGS_TAR[B2S256]="$(hash_file blake2s256 "${nixpkgs_path}")"
declare -Ar NIXPKGS_TAR

declare fail=""

for file in "${!NIXPKGS_TAR[@]}"; do
  if [ "${EXPECTED_NIXPKGS_TAR[${file}]}" != "${NIXPKGS_TAR[${file}]}" ]; then
    >&2 echo "ERROR: the tarball ${file} hash does not match the expected value!"
    >&2 echo "EXPECTED: ${EXPECTED_NIXPKGS_TAR[${file}]}"
    >&2 echo "ACTUAL:   ${NIXPKGS_TAR[${file}]}"
    fail=true
  else
    >&2 echo "OK: ${nixpkgs_path} ${file} hash matches the expected value."
  fi
done

if [ -n "${fail}" ]; then
  exit 1
fi
