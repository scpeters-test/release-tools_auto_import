#!/bin/bash -xe

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

echo '# BEGIN SECTION: cleanup brew installation'
. ${SCRIPT_DIR}/lib/_homebrew_cleanup.bash
echo '# END SECTION'

echo '# BEGIN SECTION: run the one-liner installation'
curl -ssL https://bitbucket.org/osrf/release-tools/raw/homebrew_remove_all/one-line-installations/gazebo.sh | sh -x
echo '# END SECTION'
