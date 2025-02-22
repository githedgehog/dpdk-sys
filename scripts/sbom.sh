#!/usr/bin/env bash

set -euo pipefail

declare -r sbomnix="github:tiiuae/sbomnix"

just build-sysroot

declare -r builds="/tmp/dpdk-sys/builds"
pushd "${builds}"
declare -r package="env.sysroot"

nix build "${sbomnix}" --out-link /tmp/sbomnix

declare -a cleanup_cmds=()
cleanup() {
  declare cmd
  for cmd in "${cleanup_cmds[@]}"; do
    ${cmd}
  done
}
trap cleanup EXIT

declare summary="${builds}/${package}.summary.md"
truncate --size 0 "${summary}"

for libc in "gnu64"; do
  pushd "$(mktemp -d)" && cleanup_cmds+=("rm -rf $(pwd)")
  nix run \
    "${sbomnix}#sbomnix" \
    -- \
    --csv "${builds}/${package}.${libc}.sbom.csv" \
    --cdx "${builds}/${package}.${libc}.sbom.cdx.json" \
    --spdx "${builds}/${package}.${libc}.sbom.spdx.json" \
    --verbose=1 \
    --include-vulns \
    "${builds}/${package}.${libc}.release"
  pushd "$(mktemp -d)" && cleanup_cmds+=("rm -rf $(pwd)")
  nix run \
    "${sbomnix}#vulnxscan" \
    -- \
    --out "${builds}/${package}.${libc}.vulns.csv" \
    --triage \
    --verbose=1 \
    "${builds}/${package}.${libc}.release"
  pushd "$(mktemp -d)" && cleanup_cmds+=("rm -rf $(pwd)")
  nix run \
    "${sbomnix}#nix_outdated" \
    -- \
    --out "${builds}/${package}.${libc}.outdated.csv" \
    --verbose=1 \
    "${builds}/${package}.${libc}.release"
  pushd "$(mktemp -d)" && cleanup_cmds+=("rm -rf $(pwd)")
  nix run \
    "${sbomnix}#provenance" \
    -- \
    --out "${builds}/${package}.${libc}.provenance.json" \
    --verbose=1 \
    --recursive \
    "${builds}/${package}.${libc}.release"
  pushd "$(mktemp -d)" && cleanup_cmds+=("rm -rf $(pwd)")
  nix run \
    "${sbomnix}#nixgraph" \
    -- \
    --out "${builds}/${package}.${libc}.nixgraph.dot" \
    --depth=99 \
    --verbose=1 \
    "${builds}/${package}.${libc}.release"

  for file in "${builds}/${package}.${libc}."*".csv"; do
    csview --style markdown "$file" > "${file%.csv}.md"
  done

  for file in "${builds}/${package}.${libc}."*".dot"; do
    dot -Tsvg "$file" > "${file%.dot}.svg"
  done

  {
    echo "<details>";
    echo "<summary>";
    echo "";
    echo "## Vuln scan (${libc}):";
    echo "";
    echo "</summary>";
    echo "";
    cat ${builds}/${package}.${libc}.vulns.triage.md;
    echo "";
    echo "</details>";
    echo "";
    echo "<details>";
    echo "<summary>";
    echo "";
    echo "## Outdated packages (${libc}):";
    echo "";
    echo "</summary>";
    echo "";
    cat ${builds}/${package}.${libc}.outdated.md;
    echo "";
    echo "</details>";
    echo "";
    echo "<details>";
    echo "<summary>";
    echo "";
    echo "## SBOM (${libc}):";
    echo "";
    echo "</summary>";
    echo "";
    cat ${builds}/${package}.${libc}.sbom.md;
    echo "";
    echo "</details>";
    echo "";
  } >> "${summary}"
done
