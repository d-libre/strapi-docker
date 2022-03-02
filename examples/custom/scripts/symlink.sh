#!/usr/bin/env sh

find ${PWD} -type f -name '*.sh' | while read f; do
    fileName=$(basename ${f});
    ln -s "../lib/${LIB_PATH}/${fileName}" "/usr/local/bin/${fileName%.sh}";
done

fileName=get-all-db-dependencies
ln -s "../lib/${LIB_PATH}/${fileName}" "/usr/local/bin/${fileName}";