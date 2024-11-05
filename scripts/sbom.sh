#!/usr/bin/env bash

set -euxo pipefail

declare -r sbomnix="github:tiiuae/sbomnix"

just build-sysroot

declare -r builds="/tmp/dpdk-sys/builds"
pushd "${builds}"
declare -r package="env.sysroot"

nix build "${sbomnix}" --out-link /tmp/sbomnix

for libc in "gnu64" "musl64"; do
  cd "$(mktemp -d)"
  nix run \
    "${sbomnix}#sbomnix" \
    -- \
    --csv "${builds}/${package}.${libc}.sbom.csv" \
    --cdx "${builds}/${package}.${libc}.sbom.cdx.json" \
    --spdx "${builds}/${package}.${libc}.sbom.spdx.json" \
    --verbose=1 \
    --include-vulns \
    "${builds}/${package}.${libc}.release" &
  cd "$(mktemp -d)"
  nix run \
    "${sbomnix}#vulnxscan" \
    -- \
    --out "${builds}/${package}.${libc}.vulns.csv" \
    --triage \
    --verbose=1 \
    "${builds}/${package}.${libc}.release" &
  cd "$(mktemp -d)"
  nix run \
    "${sbomnix}#nix_outdated" \
    -- \
    --out "${builds}/${package}.${libc}.outdated.csv" \
    --verbose=1 \
    "${builds}/${package}.${libc}.release" &
  cd "$(mktemp -d)"
  nix run \
    "${sbomnix}#provenance" \
    -- \
    --out "${builds}/${package}.${libc}.provenance.json" \
    --verbose=1 \
    --recursive \
    "${builds}/${package}.${libc}.release" &
  cd "$(mktemp -d)"
  nix run \
    "${sbomnix}#nixgraph" \
    -- \
    --out "${builds}/${package}.${libc}.nixgraph.dot" \
    --depth=15 \
    --verbose=1 \
    "${builds}/${package}.${libc}.release" &
done

wait

for file in "${builds}/"*.csv; do
  csview --style markdown "$file" > "${file%.csv}.md"
done

for file in "${builds}/"*.dot; do
  dot -Tsvg "$file" > "${file%.dot}.svg"
  dot -Gdpi=300 -Tpng "$file" > "${file%.dot}.png"
done
