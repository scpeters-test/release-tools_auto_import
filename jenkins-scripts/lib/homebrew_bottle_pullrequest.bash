#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_LIBDIR=$(readlink ${0}) || SCRIPT_LIBDIR=${0}
SCRIPT_LIBDIR="${SCRIPT_LIBDIR%/*}"

set -e

# directory to find the .json file generated by brew-bot with the hash
# TODO: send the directory from the DSL
BOTTLE_JSON_DIR=${WORKSPACE}/pkgs

echo '# BEGIN SECTION: check variables'
if [ -z "${PULL_REQUEST_URL}" ]; then
  echo PULL_REQUEST_URL not specified
  exit -1
fi
PULL_REQUEST_API_URL=$(echo ${PULL_REQUEST_URL} \
  | sed -e 's@^https://github\.com/@https://api.github.com/repos/@' \
        -e 's@/pull/\([0-9]\+\)/*$@/pulls/\1@')
PULL_REQUEST_HEAD_REPO=$(curl ${PULL_REQUEST_API_URL} \
  | python -c 'import json, sys; print(json.loads(sys.stdin.read())["head"]["repo"]["ssh_url"])')
PULL_REQUEST_BRANCH=$(curl ${PULL_REQUEST_API_URL} \
  | python -c 'import json, sys; print(json.loads(sys.stdin.read())["head"]["ref"])')
echo '# END SECTION'

FILES_WITH_NEW_HASH="$(ls ${BOTTLE_JSON_DIR}/*.json)"

# call to github setup
. ${SCRIPT_LIBDIR}/_homebrew_github_setup.bash

if [ -z "${TAP_PREFIX}" ]; then
	echo TAP_PREFIX not specified
	exit -1
fi

for F_WITH_NEW_HASH in ${FILES_WITH_NEW_HASH}; do
  # Need to get the formula name and version from json
  VERSION=$(${BREW} ruby -e \
  "puts JSON.load(IO.read(\"${F_WITH_NEW_HASH}\")).values[0]['formula']['pkg_version']")
  FORMULA_FULL_NAME=$(${BREW} ruby -e \
    "puts JSON.load(IO.read(\"${F_WITH_NEW_HASH}\")).keys[0]")
  # FORMULA_FULL_NAME is osrf/similation/$package_name
  PACKAGE_ALIAS=${FORMULA_FULL_NAME##*/}
  # Use it to get the formula path
  . ${SCRIPT_LIBDIR}/_homebrew_github_get_formula_path.bash

  if [ -z "${FORMULA_PATH}" ]; then
    echo FORMULA_PATH not specified
    echo "MARK_AS_UNSTABLE"
    continue
  fi

  echo '# BEGIN SECTION: checkout pull request branch'
  GIT="git -C ${TAP_PREFIX}"
  ${GIT} checkout ${PULL_REQUEST_BRANCH}
  echo '# END SECTION'

  echo "# BEGIN SECTION: update hash in formula ${PACKAGE_ALIAS}"
  DISTRO=$(${BREW} ruby -e \
    "puts JSON.load(IO.read(\"${F_WITH_NEW_HASH}\") \
        ).values[0]['bottle']['tags'].keys[0]")
  echo DISTRO: ${DISTRO}
  # Print sha256 for this DISTRO's bottle
  NEW_HASH=$(${BREW} ruby -e \
    "puts JSON.load(IO.read(\"${F_WITH_NEW_HASH}\") \
        ).values[0]['bottle']['tags'][\"${DISTRO}\"]['sha256']")
  echo NEW_HASH: ${NEW_HASH}
  # Check if formula has existing bottle entry for this DISTRO
  if ${BREW} ruby -e \
    "exit (\"${PACKAGE_ALIAS}\".f.bottle_specification.checksums[:sha256].select \
    { |d| d.value?(:${DISTRO}) }).length == 1"
  then
    DISTRO_SYMBOL=${DISTRO}
  # Check if formula has existing bottle entry for this DISTRO_or_later
  elif ${BREW} ruby -e \
    "exit (\"${PACKAGE_ALIAS}\".f.bottle_specification.checksums[:sha256].select \
    { |d| d.value?(:${DISTRO}_or_later) }).length == 1"
  then
    DISTRO_SYMBOL=${DISTRO}_or_later
  else
    echo bottle specification for distro ${DISTRO} not found
    echo unable to update formula
    echo "MARK_AS_UNSTABLE"
    continue
  fi
  echo bottle specification for distro ${DISTRO_SYMBOL} found
  OLD_HASH=$(${BREW} ruby -e \
    "puts \"${PACKAGE_ALIAS}\".f.bottle_specification.checksums[:sha256].select \
    { |d| d.value?(:${DISTRO_SYMBOL}) }[0].keys[0]")
  echo OLD_HASH: ${OLD_HASH}
  SED_FIND___="sha256 \"${OLD_HASH}\" => :${DISTRO_SYMBOL}"
  SED_REPLACE="sha256 \"${NEW_HASH}\" => :${DISTRO_SYMBOL}"
  sed -i -e "s@${SED_FIND___}@${SED_REPLACE}@" ${FORMULA_PATH}
  echo '# END SECTION'

  COMMIT_MESSAGE_SUFFIX=" ${DISTRO_SYMBOL} bottle"
  . ${SCRIPT_LIBDIR}/_homebrew_github_commit.bash
done
