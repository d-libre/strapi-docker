#!/usr/bin/env bash

# Exit on [e]rrors ([E]ven inside functions)
set -eE
# Globally export all [a]ssigned Env. Variable
set -a

declare -r __IMPORT_VERSION=0.1.0
declare -r __IMPORT_GITHUB_URL=https://github.com/d-libre/strapi-docker

printf "Import Strapi App|Template v${__IMPORT_VERSION}\n"

source base 2>/dev/null || {
    printf "
    This script requires its |__base| library to be installed along with it.\n
    Please read the installation notes first from
       ${__IMPORT_GITHUB_URL}#readme\n"
    exit 2
}

declare -r __IMPORT_SCRIPT_LOCATION=$(base::where ${BASH_SOURCE[0]})
echo ":: ${__IMPORT_SCRIPT_LOCATION}"

__showHelp() {
    # TODO: Tool to properly handle/render the markdown instead of just "cat" it
    cat ${__IMPORT_SCRIPT_LOCATION}/docs/import.md 2>/dev/null || {
        printf "
Import Strapi App/Template directly from either a public/private repository
or from any directory in your file system.

Usage:
  From GitHub:
    import-strapi [OPTIONS] <github-user>/<repository> | <full-github-repository-url>
  From any existing path:
    import-strapi [OPTIONS] --from <path/to/your/template/>

Please Read https://github.com/d-libre/strapi-docker#readme for more details

";  }
}

# Immediately exit if no arguments
[[ -z ${1} ]] && __showHelp && exit 0 || true

trap 'base::onExit $? $LINENO' EXIT
trap 'base::onError $? $LINENO' ERR

declare -r __BASE_ENV_VARS="^(IMPORT_|_+import_+)"
declare -a __IMPORT_ALLOWED_PATHS=(api components config/functions data database plugins public scripts src)

import::parseArguments() {
    # Try
    local _ggetArgs=""
    local _importOptions=$(getopt \
        -n "import" \
        -s bash \
        -l "branch:,tag:,output:,prefix:,user:,secret:,from:,subdir:,extra-dirs:,no-merge,install,build,lockfile,package-only" \
        -o "b:t:o:p:u:s:f:d:x:nIBl" \
        -- "${@}"
    ) || { # Catch
        echo "Incorrect options provided"
        __showHelp
        exit 1
    }
    local _trailingArgs=$(base::trailingArguments "${_importOptions}")
    local _firstTrailing="${_trailingArgs%% *}"
    if [[ ! -z "${_firstTrailing}" ]]; then
        # Assign (first) trailing value as the repository URL/ShortHand
        base::setEnv IMPORT_REPO_SH_URL "${_firstTrailing}" 'Git Shorthand/URL'
    fi
    eval set -- "$_importOptions"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--prefix)
                base::setEnv IMPORT_REPO_PREFIX "${2}" "Prefix Repo name "
                shift 2
                ;;
            -o|--output)
                base::setEnv IMPORT_OUTPUT_PATH "${2}" "Output Directory "
                shift 2
                ;;
            -f|--from)
                base::setEnv IMPORT_TEMPLATE_SOURCE "${2}" "From Files in Dir"
                shift 2
                ;;
            -d|--subdir)
                base::setEnv IMPORT_TEMPLATE_SUBDIR "${2}" "Template's Folder"
                shift 2
                ;;
            -x|--extra-dirs)
                base::setEnv IMPORT_TEMPLATE_EXTRA_DIRS "${2}" "ExtraDirs Allowed"
                shift 2
                ;;
            -n|--no-merge)
                base::setEnv IMPORT_TEMPLATE_NO_MERGE true "Do not merge dirs"
                shift 1
                ;;
            --package-only)
                base::setEnv IMPORT_TEMPLATE_PACKAGE_ONLY true "Package.json only"
                shift 1
                ;;
            -I|--install)
                base::setEnv IMPORT_TEMPLATE_INSTALL true "Install once done"
                shift 1
                ;;
            -l|--lockfile)
                base::setEnv IMPORT_TEMPLATE_LOCK true "Freezing Packages"
                shift 1
                ;;
            -B|--build)
                base::setEnv IMPORT_TEMPLATE_BUILD true "Build final files"
                shift 1
                ;;
            --)
                shift
                break
                ;;
            *)  _ggetArgs+="${1} "
                shift
                continue
                ;;
        esac
    done
    export GGET_EXTRA_ARGUMENTS=${_ggetArgs}
}

import::setupFromArguments() {
    _import_directories="${__IMPORT_ALLOWED_PATHS[@]} ${IMPORT_TEMPLATE_EXTRA_DIRS}"
    [[ -z ${IMPORT_REPO_SH_URL} ]] && _skip_downloadingFiles=true || true
    [[ -n ${IMPORT_TEMPLATE_NO_MERGE}${IMPORT_TEMPLATE_PACKAGE_ONLY} ]] && _skip_mergingFiles=true || true
    [[ -n ${IMPORT_TEMPLATE_NO_MERGE} ]] && [[ -z ${IMPORT_TEMPLATE_PACKAGE_ONLY} ]] && _skip_mergingPackages=true || true
    [[ -n ${IMPORT_REPO_SH_URL}${IMPORT_TEMPLATE_SOURCE} ]] || {
        printf "You need to set either
        the fully qualified URL or Shorthand of the repository with the app/template
        or The directory where you want to import the files from [with --from]
        "
        __showHelp
        exit 19
    }
}

import::getFilesFromRepository() {
    if [[ -n $_skip_downloadingFiles ]]; then
        # Download from repository has not been required
        return 0
    fi
    _targetDir=${IMPORT_OUTPUT_PATH:-$(mktemp -d -t strapi-template-XXXXXXXX)}
    _urlPrefix=${IMPORT_REPO_PREFIX:-strapi-template-}
    echo "Import with gget from ${IMPORT_REPO_SH_URL} to ${_targetDir}/"
    echo "Extra Arguments: ${GGET_EXTRA_ARGUMENTS} --prefix ${_urlPrefix}"
    gget ${GGET_EXTRA_ARGUMENTS} -p ${_urlPrefix} -o ${_targetDir} ${IMPORT_REPO_SH_URL}
    if [[ -n $_skip_mergingFiles ]]; then
        # Only download was required - (not-to-merge-files)
        echo "Template files have been properly downloaded and available at ${_targetDir}"
    fi
    export IMPORT_TEMPLATE_SOURCE=${_targetDir}
}

import::mergeAllFiles() {
    if [[ -n $_skip_mergingFiles ]]; then
        echo "Skip merging files."
        return 0
    fi
    _templateDir=${IMPORT_TEMPLATE_SOURCE}
    _innerPath=${IMPORT_TEMPLATE_SUBDIR:-template}
    if [[ ! -d ${_templateDir} ]]; then
        echo "Unable to reach the source path ${_templateDir}!"
        exit 7
    fi
    for dir in ${_import_directories[@]}; do
        _sourceDir=${_templateDir}/${_innerPath}/${dir}
        if [[ -d ${_sourceDir} ]]; then
            _destDir=$(dirname ${dir})
            mkdir -p ${_destDir}
            printf "Importing ${_sourceDir} to ${_destDir} "
            cp -r ${_sourceDir} ${_destDir}
            printf "☑\n"
        else
            printf "Not found ${_sourceDir} ☐\n"
        fi
    done
}

import::mergePackages() {
    if [[ -n ${_skip_mergingPackages} ]]; then
        echo "Skip merging package.json."
        return 0
    fi
    _templateDir=${IMPORT_TEMPLATE_SOURCE}
    _innerPath=${IMPORT_TEMPLATE_SUBDIR:-template}
    jsConfigPath=${_templateDir}/template.js
    jsonConfigPath=${_templateDir}/template.json
    currentConfigPath=$(pwd)/package.json
    innerPackagePath=${_templateDir}/${_innerPath}/package.json
    tmpPackagePath=${_templateDir}/package.json
    innerPath=${IMPORT_TEMPLATE_SUBDIR:-template}

    if [[ -f "${innerPackagePath}" ]]; then
        mv "${innerPackagePath}" "${tmpPackagePath}"
    fi
    if [[ -f "${jsConfigPath}" ]]; then
        echo "Function Config file found! Generating the static JSON..."
        node -e 'const t=require("'${jsConfigPath%.*}'");console.log("%j",t({"strapiVersion":"'${VERSION}'"}))' > ${jsonConfigPath}
    elif [[ -f "${tmpPackagePath}" ]]; then
        jq '{ "package": . }' <${tmpPackagePath} >${jsonConfigPath}
    elif [[ ! -f "${jsonConfigPath}" ]]; then
        printf "You need to have either a template.js or template.json or package.json 
in your template's root directory in order to properly import the template/app package
Skipping package merge..."
        return 0
    fi

    # Recursively merge the inner .package json node of the template.json
    # into the app's package.json (outputs to a temp file first)
    jq -s '.[0] * .[1].package' ${currentConfigPath} ${jsonConfigPath} > ${tmpPackagePath}
    # Replacing the package.json
    # TODO: Inject the template's URL
    mv ${tmpPackagePath} ${currentConfigPath}
}

import::install() {
    if [[ -z ${IMPORT_TEMPLATE_INSTALL} ]]; then
        return 0
    fi
    if [[ -n ${IMPORT_TEMPLATE_LOCK} ]]; then
        _lockFile=--frozen-lockfile
    else
        base::removeAny *lock*
    fi
    echo "Proceed to install with Yarn ${_lockFile}"
    yarn --production ${_lockFile}
}

import::build() {
    if [[ -z ${IMPORT_TEMPLATE_BUILD} ]]; then
        return 0
    fi
    echo "Proceed to build with Yarn.."
    yarn build
}

# MAIN
import::parseArguments "${@}"

import::setupFromArguments

# Import files from repository with gget
import::getFilesFromRepository

# Merges template's configuration (package.json) into main app's config
import::mergePackages

# Merges template files into main app (in current directory)
import::mergeAllFiles

# Yarn Install (if required)
import::install

# Yarn Build (if required)
import::build

echo "Done!"
