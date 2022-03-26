#!/usr/bin/env bash

set -e

echo "🚀 Strapi ${VERSION}"

function setDbConfigFile {
    # TODO: Validate CLIENT and other related DB environment variables
    if [[ -n "${DATABASE_CLIENT}" ]]; then
        if [[ ! "${DATABASE_CLIENT}" =~ (postgres|mysql|mongo|sqlite) ]]; then
            printf "Unrecognized Database Client ${DATABASE_CLIENT}. Continuing with Sqlite\n"
            return 0
        fi
        if [[ "${DATABASE_CLIENT}" != 'sqlite' ]]; then
            if [[ -d "${DB_CONFIGS_PATH}" ]] && [[ -f "${DB_CONFIGS_PATH}${DATABASE_CLIENT}.js" ]]; then
                echo "DataBase Client: ${DATABASE_CLIENT}"
                cp ${DB_CONFIGS_PATH}${DATABASE_CLIENT}.js ${APP_PATH}/config/database.js
                return 0
            else
                echo "Unable to find the DB Client configuration File. Will default to Sqlite"
            fi
        fi
    fi
    echo "DataBase Client: sqlite (default)"
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
