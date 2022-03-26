#!/usr/bin/env bash

config=docker/config/example.ini

cd $(dirname "${0}") && cd ..

# Validating Action
[[ "${1}" =~ (build|push) ]] && action="${1}" || {
    printf "Wrong action ${1}!\n" && exit 1
}
# Validating Stage
[[ "${2}" =~ (live|cli|base|cache|demo) ]] && stage="${2}" || {
    printf "Wrong stage ${2}!\n" && exit 1
}

build() {
    target=${1}
    shift
    args="${@}"
    docker compose \
        -f docker/builder-compose.yml \
        --env-file ${config} \
        build ${args} ${target}
}

push() {
    target=${1}
    docker compose \
        -f docker/builder-compose.yml \
        --env-file ${config} \
        push ${target}
}

demo() { echo "${1}"; }

live() { ${1} 'live' --no-cache; }

cli() { ${1} 'cli' --no-cache && live ${1}; }

base() { ${1} 'base' --no-cache && cli ${1}; }

cache() { ${1} 'cache' && base ${1}; }

START_T=$(date +%s%N)

echo "Command to execute: docker compose ${action} ${stage}"

set -ex
${stage} ${action}
set +ex

FINAL_T=$(date +%s%N)
ELAPSED=$(( (${FINAL_T} - ${START_T}) / 10**5 ))
IN_SECS=$(awk "BEGIN { print ${ELAPSED}/10**4; }")
printf "Total Elapsed Time: ${IN_SECS} secs.\n"
