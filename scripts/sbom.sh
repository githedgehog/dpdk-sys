#!/usr/bin/env bash

set -euxo pipefail

declare -r sbomnix="github:tiiuae/sbomnix"

just build-sysroot

declare -r builds="/tmp/dpdk-sys/builds"
pushd "${builds}"
declare -r package="env.sysroot"

for libc in "gnu64" "musl64"; do
  for profile in "release" "debug"; do
    for dep_type in "runtime" "buildtime"; do
      # shellcheck disable=SC2046,SC2006
      nix run \
        "${sbomnix}#sbomnix" \
        -- \
        --csv "${builds}/${package}.${libc}.${profile}.${dep_type}.sbom.csv" \
        --cdx "${builds}/${package}.${libc}.${profile}.${dep_type}.sbom.cdx.json" \
        --spdx "${builds}/${package}.${libc}.${profile}.${dep_type}.sbom.spdx.json" \
        --verbose=1 \
        --include-vulns \
        $([ "$dep_type" = "buildtime" ] && echo --buildtime) \
        "${builds}/${package}.${libc}.${profile}"
      # shellcheck disable=SC2046,SC2006
      nix run \
        "${sbomnix}#vulnxscan" \
        -- \
        --out "${builds}/${package}.${libc}.${profile}.vulns.csv" \
        --triage \
        --verbose=1 \
        $([ "$dep_type" = "buildtime" ] && echo --buildtime) \
        "${builds}/${package}.${libc}.${profile}"
      # shellcheck disable=SC2046,SC2006
      nix run \
        "${sbomnix}#nix_outdated" \
        -- \
        --out "${builds}/${package}.${libc}.${profile}.outdated.csv" \
        --verbose=1 \
        $([ "$dep_type" = "buildtime" ] && echo --buildtime) \
        "${builds}/${package}.${libc}.${profile}"
    done
    # shellcheck disable=SC2046,SC2006
    nix run \
      "${sbomnix}#provenance" \
      -- \
      --out "${builds}/${package}.${libc}.${profile}.provenance.json" \
      --verbose=1 \
      --recursive \
      "${builds}/${package}.${libc}.${profile}"
    # shellcheck disable=SC2046,SC2006
    nix run \
      "${sbomnix}#nixgraph" \
      -- \
      --out "${builds}/${package}.${libc}.${profile}.${dep_type}.nixgraph.dot" \
      --depth=15 \
      --verbose=1 \
      "${builds}/${package}.${libc}.${profile}"
  done
done

for file in "${builds}/"*.csv; do
  csview --style markdown "$file" > "${file%.csv}.md"
done

for file in "${builds}/"*.dot; do
  dot -Tsvg "$file" > "${file%.dot}.svg"
  dot -Gdpi=300 -Tpng "$file" > "${file%.dot}.png"
done
