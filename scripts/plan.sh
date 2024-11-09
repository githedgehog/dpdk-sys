#!/usr/bin/env bash

set -euxo pipefail
# usage: apply_template /path/to/template.txt
apply_template() {
  trap 'rm -f ${tempfile}' RETURN
  declare tempfile;
  tempfile="$(mktemp)";
  declare -r tempfile;
  {
    echo 'cat <<END_TEMPLATE';
    cat "${1}";
    echo 'END_TEMPLATE';
  } > "${tempfile}";
  source "${tempfile}"
}

apply_template ./plan.template.md >> "${1:-/proc/self/fd/1}"

