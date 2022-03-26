#!/usr/bin/env sh

echo "BinLink v0.1"
SOURCE_PATH=${1}
# Removes the first argument (the base path)
shift
echo "Source Directory: ${SOURCE_PATH}"
# Set maxdepth if 2nd argument is numeric
if [[ $1 =~ ^[0-9]+$ ]]; then
    _DEPTH="-maxdepth ${1}"
    shift
fi

function relativeToBin() {
    local fullDir=$(dirname ${1})
    local fileName=$(basename ${1})
    echo ../${fullDir##/usr/local/}/${fileName}
}

function linkAll() {
    local EXT=${1}
    echo "Linking all .${EXT} files..."
    find ${SOURCE_PATH} -type f ${_DEPTH} -name "*.${EXT}" | while read f; do
        fileName=$(basename ${f});
        relative=$(relativeToBin ${f})
        ln -s "${relative}" "/usr/local/bin/${fileName%.${EXT}}";
        echo "☑  Linked ${fileName%.${EXT}} → [${relative}]"
    done
}

for i in "${@}";
do
    linkAll ${i}
done
