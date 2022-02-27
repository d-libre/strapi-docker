#!/usr/bin/env bash

set -a

source ${BASH_SOURCE%/*}/print-utils.sh

# Syntax: setEnv VARIABLE_TO_SET value [default_value]
#   if the given value is empty (or equals "-") 
#   it will take the default value instead
setEnv () {
    # value is empty or equals "-"?
    if [[ -z "$2" ]] || [[ "$2" == "-" ]]; then
        printEmpty "${1}"
        # if there is no default_value → bye
        if [[ -z "$3" ]]; then
            return 0
        fi
        # else → use the default value
        export ${1}="${3}"
        printDefault "${1}"
    else
        export ${1}="${2}"
        printVal "${1}"
    fi
    
}

# Resets the "last option argument processed" index
OPTIND=1

while getopts ":S:c:h:p:d:U:P:fqxn" option; do
    case ${option} in
        S ) #Strapi Version
            setEnv STRAPI_VERSION ${OPTARG} ;;
        c ) #DB Client (postgres|mysql|mongo|sqlite)
            setEnv DEFAULT_DB_CLIENT ${OPTARG} sqlite ;;
        h ) #DB Host
            setEnv DEFAULT_DB_HOST ${OPTARG} localhost ;;
        p ) #DB Host Port
            setEnv DEFAULT_DB_PORT ${OPTARG} ;;
        d ) #DB Name
            setEnv DEFAULT_DB_NAME ${OPTARG} strapi ;;
        U ) #DB User
            setEnv DEFAULT_DB_USERNAME ${OPTARG} strapi ;;
        P ) #DB Password
            setEnv DEFAULT_DB_PASSWORD ${OPTARG} secret ;;
        f ) #Force Overwrite Database?
            setEnv DEFAULT_DB_FORCE_OVERWRITE true ;;
        q ) #Quick Start?
            setEnv INSTALL_OP_QUICK_START true ;;
        x ) #Displays the full command to be executed
            setEnv INSTALL_OP_DISPLAY true ;;
        n ) #Not actually executing
            setEnv INSTALL_OP_NOT_EXECUTE true ;;

        \? ) #Otherwise (invalid options)
            echo "☒ Invalid option or argument ${OPTARG}" ;;
    esac
done

IC=()

# Adds a parameter/value pair 
# (if its value is not empty)
# to the command array
addValue() {
    if [[ ! -z "${!2}" ]] && [[ "${!2}" != "-" ]]; then
        IC+=("--${1}=${!2}")
    fi
}

# Adds a parameter pair (if it was set) 
# to the command array
addParam() {
    if [[ ! -z "${!2}" ]]; then
        IC+=("--${1}")
    fi
}

TRUE=1
case ${DEFAULT_DB_CLIENT} in
    postgres ) EXT_SQL=1 ;;
    mysql ) EXT_SQL=1 ;;
    mongo ) EXT_NO_SQL=1 ;;
    sqlite ) FILE_DB=1 ;;
esac

buildCreateCommand() {
    IC+="npx create-strapi-app@${STRAPI_VERSION} ."
    if [[ -z ${FILE_DB} ]]; then
        addValue "dbclient" "DEFAULT_DB_CLIENT"
        addValue "dbhost" "DEFAULT_DB_HOST"
        addValue "dbport" "DEFAULT_DB_PORT"
        addValue "dbname" "DEFAULT_DB_NAME"
        addValue "dbusername" "DEFAULT_DB_USERNAME"
        addValue "dbpassword" "DEFAULT_DB_PASSWORD"
    fi
    addParam "quickstart" "INSTALL_OP_QUICK_START"
    addParam "no-run" "TRUE"
}

printf "Building the Install Command\n"
buildCreateCommand

if [[ ! -z "${INSTALL_OP_DISPLAY}" ]]; then
    printf "Command to be run to Install Strapi:\n"
    printCommandArray "${IC[@]}"
fi

if [[ ! -z "${INSTALL_OP_NOT_EXECUTE}" ]]; then
    echo "Skipping the actual execution (as per requested)"
    exit 0
fi

# Else.. continue installing
echo "- Installing Strapi 🚀 ${VERSION} with npx... [this might take some time] ⌛"
fullcmd=$(printf "%s " "${IC[@]}")
# echo ${fullcmd}
DOCKER=true ${fullcmd}
