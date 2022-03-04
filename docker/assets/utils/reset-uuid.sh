#!/usr/bin/env sh

PACKAGE=${1:-./package.json}
echo "Node Package at: ${PACKAGE}"
# TODO: echo 'WARNING!'
uuid=$(cat /proc/sys/kernel/random/uuid)
echo "New ID will be ${uuid}"
jq '.strapi.uuid = "'${uuid}'"' ${PACKAGE}
