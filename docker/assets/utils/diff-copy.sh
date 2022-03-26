#!/usr/bin/env bash

_SOURCE=${1%/}
_UPDATE=${2%/}
_TARGET=${3%/}
_DEPTH=${4:-2}

diff_dirs() {
    for dir in $(find ${_SOURCE} -maxdepth ${_DEPTH} -type d | grep ${_SOURCE}/); do
        _dir2=${dir/${_SOURCE}/${_UPDATE}}
        diff ${dir} ${_dir2}
    done | awk -vORS=' ' '/Only in/ { gsub(":",""); print $3"/"$4 }'
}

for _d in $(diff_dirs); do
    _t=${_d/${_UPDATE}/${_TARGET}}
    mkdir -p $(dirname ${_t})
    cp -r $_d $_t
    echo "☑ [${_d}] → [${_t}]"
done
