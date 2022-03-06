#!/usr/bin/env bash

set -ea

titleOf() { set ${*//_/ } ; set ${*,,} ; echo ${*^} ; }

printVal() {
    local title=$(titleOf ${1})
    echo "☑  ${title}: ${!1}" >&2
}

printEmpty() {
    local title=$(titleOf ${1})
    echo "☐  ${title}: ☓" 1>&2
}

printDefault() {
    echo "   ╙── ${!1}" >&2
}

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

while getopts ":t:p:o:d:s:in" option; do
    case ${option} in
        t ) # Template's GitHub Repository Url or "Shorthand"
            setEnv TEMPLATE_GITHUB ${OPTARG} ;;
        p ) # Path to the main files (inside the repository). Defaults to "template/"
            setEnv TEMPLATE_SUBDIR ${OPTARG%/} template ;;
        o ) # Output folder (combined with -n allows to download first for later install)
            setEnv TEMPLATE_OUTPUT ${OPTARG%/} ;;
        d ) # From Source Directory (if present, it will try to
            # take the sources from this directory instead of the repository)
            setEnv TEMPLATE_SOURCE ${OPTARG%/} ;;
        s ) # Name of the Secret file (in /run/secrets)
            # required to have the github user's API access Token
            # to grant this script permissions to access to private repositories
            setEnv TEMPLATE_SECRET ${OPTARG} ;;
        i ) # Allow to override the app's own GUID with 
            # the one in the template's package.json (if exists)
            setEnv TEMPLATE_ALLOW_ID true ;;
        n ) # No-Merge: No actual copy/merge will be performed 
            # (just download and untar the files to the "o" location)
            setEnv TEMPLATE_NO_MERGE true ;;

        \? ) # Otherwise (invalid options)
            echo "☒ Invalid option or argument ${option}" ;;
    esac
done

# No template GitHub URL nor Source path (or just simply no args at all)
if [[ -z "$1" ]] || [[ -z "${TEMPLATE_GITHUB}${TEMPLATE_SOURCE}" ]] ; then
    echo "No Template to Import."
    exit 0
fi

sourcePath=${TEMPLATE_SUBDIR:-template}

getValue() {
    printf "${1[@]}" | awk "/${2}/ { print $2 }"
}

function getStatus() {
    curl -sI -u ${owner}:${TOKEN} -o /dev/null -w "%{http_code}" ${1}
}

tmpDir=${TEMPLATE_OUTPUT:-$(mktemp -d -t strapi-template-XXXXXXXX)}

function download() {

    if [[ ! -z "${TEMPLATE_SECRET}" ]]; then
        echo "Files in /run/secrets:"
        ls /run/secrets
        if [[ -f /run/secrets/${TEMPLATE_SECRET} ]]; then
            # Token Found in Secrets!
            TOKEN=$(cat /run/secrets/${TEMPLATE_SECRET})
        else
            echo "No secrets found with such filename ${TEMPLATE_SECRET}"
        fi
    fi

    API_BASE_URL=https://api.github.com
    ACCEPT_GITHUB_RAW="Accept:application/vnd.github.v3.raw"

    url="${TEMPLATE_GITHUB}"
    echo Template: ${url}

    # Any pair some-user/the-repo will match
    re_pair="^([[:alnum:]-]+)\/([[:alnum:]-]+)*$"

    # Any valid git repository URL shall match
    #   https://github.com/some-user/the-repo
    #   https://github.com/some-user/the-repo.git
    #   git@github.com:some-user/the-repo.git
    #   git://github.com/some-user/the-repo.git
    re_full="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/([^.]+)(.git)*$"

    # Template "shorthand" (pair: Owner/TemplateName)
    if [[ "$url" =~ $re_pair ]]; then
        hostname=github.com
        owner=${BASH_REMATCH[1]}
        repo=${BASH_REMATCH[2]}
        # Prepend the "strapi-template-" suffix 
        # if not included in the repo name
        if [[ ! "${repo}" =~ ^strapi-template-.* ]]; then
            repo=strapi-template-${repo}
        fi
    # Full git URLs
    elif [[ "$url" =~ $re_full ]]; then
        hostname=${BASH_REMATCH[3]}
        owner=${BASH_REMATCH[4]}
        repo=${BASH_REMATCH[5]}
    else
        echo "That url seems to not related to a valid git repository"
        exit 400
    fi

    echo "Provider: ${hostname}"
    echo "Owner:    ${owner}"
    echo "Repo:     ${repo}"

    # e.g.: https://api.github.com/repos/strapi/strapi-template-blog
    getUrl=${API_BASE_URL}/repos/${owner}/${repo}
    printf "Trying to download the template from\n\t  ${getUrl}\n"
    status=$(getStatus ${getUrl})

    if [[ $status != 200 ]]; then
        printf "Response: HTTP [${status}]\n-END-"
        exit $status
    else
        echo "Repository Found"
    fi

    # Default Branch (default if ref is omitted)
    # ref=$(curl -s $url | jq '.default_branch')

    downloadUrl=${API_BASE_URL}/repos/${owner}/${repo}/tarball
    mkdir -p ${tmpDir} && rm -rf ${tmpDir}/*

    # Direct Download via API (will properly follow the returned redirection)
    curl -sL -u ${owner}:${TOKEN} -H ${ACCEPT_GITHUB_RAW} ${downloadUrl} | tar xz --strip=1 -C ${tmpDir}

}

if [[ -z "${TEMPLATE_SOURCE}" ]]; then
    echo "Preparing to download the source files directly from the repository"
    download
fi

if [[ ! -z "${TEMPLATE_NO_MERGE}" ]]; then
    # Only download was required - (not-to-merge)
    echo "Template files have been properly downloaded and available at ${tmpDir}"
    exit 0
fi

tmpDir=${TEMPLATE_SOURCE:-${tmpDir}}

# ls ${tmpDir}
cp -r ${tmpDir}/${sourcePath}/* .

## Merging package.json ##
if [[ ! -z "${TEMPLATE_SOURCE}" ]]; then
    tempDir=${TEMPLATE_SOURCE}
fi

# TODO: Validate that files & folders structure is ok

jsConfigPath=${tmpDir}/template.js
jsonConfigPath=${tmpDir}/template.json
currentConfigPath=$(pwd)/package.json
tmpPackagePath=${tmpDir}/package.json

if [[ -f "$jsConfigPath" ]]; then
    echo "Function Config file found! Generating the static JSON..."
    node -e 'const t=require("'${jsConfigPath%.*}'");console.log("%j",t({"strapiVersion":"'${VERSION}'"}))' > ${jsonConfigPath}
fi

# Recursively merge the inner .package json node of the template.json
# into the app's package.json (outputs to a temp file first)
jq -s '.[0] * .[1].package' ${currentConfigPath} ${jsonConfigPath} > ${tmpPackagePath}
# Replacing the package.json
mv ${tmpPackagePath} ${currentConfigPath}

# TODO: Inject the template's URL

echo "Done!"
