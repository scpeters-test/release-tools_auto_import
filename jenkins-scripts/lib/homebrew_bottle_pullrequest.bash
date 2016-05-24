#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_LIBDIR=$(readlink ${0}) || SCRIPT_LIBDIR=${0}
SCRIPT_LIBDIR="${SCRIPT_LIBDIR%/*}"

set +e

# directory to find the .rb file generated by brew-bot with the hash
# TODO: send the directory from the DSL
BOTTLE_RB_DIR=${WORKSPACE}/pkgs

get_osX_distribution()
{
  local hash_line=${1}

  echo ${hash_line/*:}
}

echo '# BEGIN SECTION: check variables'
if [ -z "${BRANCH}" ]; then
  echo BRANCH not specified
  exit -1
fi

if [ -z "${PACKAGE_ALIAS}" ]; then
  echo PACKAGE_ALIAS not specified
  exit -1
fi

if [[ $(ls ${BOTTLE_RB_DIR}/*.rb | wc -l) != 1 ]]; then
  echo "There is more than one .rb file in ${BOTTLE_RB_DIR}"
  exit -1
fi

FILE_WITH_NEW_HASH="$(ls ${BOTTLE_RB_DIR}/*.rb)"

if [[ ! -f "${FILE_WITH_NEW_HASH}" ]]; then
  echo "Can not find the bottle.rb file with the new hash"
  exit -1
fi

echo '# END SECTION'

# call to github setup
. ${SCRIPT_LIBDIR}/_homebrew_github_setup.bash

if [ -z "${FORMULA_PATH}" ]; then
  echo FORMULA_PATH not specified
  exit -1
fi

if [ -z "${TAP_PREFIX}" ]; then
  echo TAP_PREFIX not specified
  exit -1
fi

echo '# BEGIN SECTION: checkout pull request branch'
GIT="git -C ${TAP_PREFIX}"
${GIT} checkout ${BRANCH}
echo '# END SECTION'

echo '# BEGIN SECTION: update hash in formula'
NEW_HASH_LINE=$(grep 'sha256[[:space:]]*.* => :' ${FILE_WITH_NEW_HASH})
DISTRO=$(get_osX_distribution "${NEW_HASH_LINE}")
CURRENT_HASH=$(sed -n "s/sha256[[:space:]]*\"\(.*\)\".*=>.*${DISTRO}.*/\1/p" ${FORMULA_PATH} | sed 's/^ *//')
# NEW_HASH_LINE has double quotes. Do not include it in double quotes :)
sed -i -e 's/^ *sha256.*=>.*'"${DISTRO}/${NEW_HASH_LINE}/"'g' ${FORMULA_PATH}
echo '# END SECTION'

COMMIT_MESSAGE_SUFFIX=" bottle"
. ${SCRIPT_LIBDIR}/_homebrew_github_commit.bash
