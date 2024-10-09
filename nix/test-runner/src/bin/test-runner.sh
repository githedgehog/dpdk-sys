#!/bin/bash

set -euo pipefail

die() {
  printf -- "ERROR: %s\n" "$@" >&2
  exit 1
}

_prog="${1}"

if [ -z "${_prog}" ]; then
  die "Usage: ${0} <program> [args...]"
fi

if [ ! -x "${_prog}" ]; then
  die "${_prog} is not executable by user $(id -un)"
fi

if [ -h "${_prog}" ]; then
  die "${_prog} is a symbolic link, refusing to set caps"
fi

if [ ! -O "${_prog}" ]; then
  die "${_prog} is not owned by the current user, refusing to set caps"
fi

if [ ! -G "${_prog}" ]; then
  die "${_prog} is not owned by the current user's group, refusing to set caps"
fi

SUDO="/bin/sudo"
SETCAP="/bin/setcap"
CHMOD="/bin/chmod"

cleanup() {
  "${SUDO}" /bin/setcap -r "${_prog}"
  "${SUDO}" /bin/chmod u=rwx "${_prog}"
}
trap cleanup EXIT

"${SUDO}" "${CHMOD}" u=rx,go= "${_prog}"
"${SUDO}" "${SETCAP}" -r "${_prog}" 2>/dev/null || true
# TODO: work on removing or limiting cap_sys_rawio cuz that's a big one
"${SUDO}" "${SETCAP}" cap_sys_rawio,cap_net_admin,cap_net_raw,cap_ipc_lock=ep "${_prog}"
"${@}"
