#!/usr/bin/env bash

set -e

if [[ -z "$1" ]]; then
    echo "No Template to Import. Continuing with Build"
    exit 0
fi

tmpDir=$(mktemp -d -t strapi-template-XXXXXXXX)
sourcePath=/template
API_BASE_URL=https://api.github.com
ACCEPT_GITHUB_RAW="Accept:application/vnd.github.v3.raw"

getValue() {
    printf "${1[@]}" | awk "/${2}/ { print $2 }"
}

function getStatus() {
    curl -sI -o /dev/null -w "%{http_code}" ${1}
}

url="${1}"
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

# TODO: Add extra Authorization header with the User's Token (from secrets) for Private repositories
# Direct Download via API (will properly follow the returned redirection)
curl -sL -H ${ACCEPT_GITHUB_RAW} ${downloadUrl} | tar xz --strip=1 -C ${tmpDir}

# ls ${tmpDir}
cp -r ${tmpDir}${sourcePath}/* .

## Merging package.json ##

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
