#!/usr/bin/env bash

set -e

echo "🚀 Strapi ${VERSION}"

function setDbConfigFile {
    # TODO: Validate CLIENT and other related DB environment variables
    dbClient=${DATABASE_CLIENT:-sqlite}
    echo "DataBase Client: ${dbClient}"
    cp ${DB_CONFIGS_PATH}${dbClient}.js ${APP_PATH}config/database.js
}
setDbConfigFile

# Use yarn to run the received Command only if it matches with
# any of the available commands for Strapi: strapi, develop, start, build
# -- otherwise, the command will be passed "as is" to be "executed" by system
if [[ "${1}" =~ (develop|start|build|strapi) ]]; then
    echo "Running yarn ${1}..."
    set -- yarn "$@"
fi

exec "$@"
