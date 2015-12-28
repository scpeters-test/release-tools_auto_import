
# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

set +e

# directory to find the .rb file generated by brew-bot with the hash
BOTTLE_RB_DIR=${WORKSPACE}

get_osX_distribution()
{
  local hash_line=${1}

  echo ${hash_line/*:}
}

echo '# BEGIN SECTION: check variables'
if [ -z "${PACKAGE_ALIAS}" ]; then
  echo PACKAGE_ALIAS not specified
  exit -1
fi

if [[ -f "${BOTTLE_RB_DIR}/*.rb" ]]; then
  echo "Can not find the bottle.rb file with the new hash"
  exit -1
fi
echo '# END SECTION'

# call to github setup
. ${SCRIPT_DIR}/lib/_homebrew_github_setup.bash

if [ -z "${FORMULA_PATH}" ]; then
  echo FORMULA_PATH not specified
  exit -1
fi


echo '# BEGIN SECTION: update hash in formula'
cat "${BOTTLE_RB_DIR}/*.rb"
# DISTRO=$(get_osX_distribution ${NEW_HASH_LINE})
# NEW_HASH_LINE=$(sed -n "s/sha256[[:space:]]*"\(.*\)".*=>.*${DISTRO}.*/\1/p" ${FORMULA_PATH} | sed 's/^ *//')
# echo "New HASH: ${NEW_HASH_LINE}"
# sed -i -e "s/sha256.*=>.*${DISTRO}/\${NEW_HASH_LINE}/g" ${FORMULA_PATH}
echo '# END SECTION'

. ${SCRIPT_DIR}/lib/_homebrew_github_commit.bash
