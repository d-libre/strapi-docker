#!/usr/bin/env bash

set -e

echo "🚀 Strapi ${VERSION}"

# Use yarn to run the received Command only if it matches with
# any of the available commands for Strapi: strapi, develop, start, build
# -- otherwise, the command will be passed "as is" to be "executed" by system
if [[ "${1}" =~ (develop|start|build|strapi) ]]; then
    echo "Running yarn ${1}..."
    set -- yarn "$@"
fi

exec "$@"
