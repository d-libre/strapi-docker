#!/usr/bin/env sh

echo "Starting symlink.sh"
SOURCE_PATH=${1}
# Removes the first argument (the base path)
shift
echo "Source Directory: ${SOURCE_PATH}"
# echo "Source Directory Content:" && ls -la ${SOURCE_PATH}

function relativeToBin() {
    local fullDir=$(dirname ${1})
    local fileName=$(basename ${1})
    echo ../${fullDir##/usr/local/}/${fileName}
}

function linkAll() {
    local EXT=${1}
    echo "Linking all .${EXT} files..."
    find ${SOURCE_PATH} -type f -name "*.${EXT}" | while read f; do
        fileName=$(basename ${f});
        relative=$(relativeToBin ${f})
        echo "Linking ${fileName} [${relative}]"
        ln -s "${relative}" "/usr/local/bin/${fileName%.${EXT}}";
    done
}

echo $@
for i in "${@}";
do
    linkAll ${i}
done
