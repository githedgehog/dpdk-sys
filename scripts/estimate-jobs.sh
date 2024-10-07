#!/bin/bash

set -euxo pipefail

declare -ri KiB=$((1024**1));
declare -ri GiB=$((1024**3));

# measure total free memory (in GiB)
declare free_memory;
free_memory=$(( "$(grep MemAvailable /proc/meminfo | awk '{print $2}')" * KiB / GiB ));
declare -ri free_memory;

# guess the worst case memory load per core for build (GiB)
declare max_mem_per_core_guess;
max_mem_per_core_guess=10;
declare -ri max_mem_per_core_guess;

# guess the max number of cores we can safely use
declare max_cores_guess;
max_cores_guess=$(( free_memory / max_mem_per_core_guess ));

# check if we have at least one core
max_cores_guess=$(if [ $max_cores_guess -lt 1 ]; then echo 1; else echo ${max_cores_guess}; fi);
declare -ri max_cores_guess;

# ensure we didn't guess more cores than the system has
if [ ${max_cores_guess} -gt "$(nproc)" ];
  then nproc;
else
  echo ${max_cores_guess};
fi;
