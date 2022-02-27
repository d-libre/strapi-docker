RED='\x1B[31m'
GREEN='\x1B[32m'
CYAN='\x1B[36m'
CLEAR='\x1B[0m' # Restores default console color

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

function printCommandArray() {
    arr=("$@")
    printf "${GREEN}${arr[0]}${CLEAR}"
    unset arr[0]
    for i in "${arr[@]}";
      do
          printf " /\n${GREEN}$i${CLEAR}"
      done
    printf "\n"
}
