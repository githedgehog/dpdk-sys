#!/bin/bash

set -euo pipefail

sleep infinity &
frrinit.sh start &

wait
