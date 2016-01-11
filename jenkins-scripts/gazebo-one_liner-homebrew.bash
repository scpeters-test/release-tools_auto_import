#!/bin/bash -xe

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

echo '# BEGIN SECTION: cleanup brew installation'
bash -x ${SCRIPT_DIR}/lib/dependencies_archive.sh
bash -x ${SCRIPT_DIR}/lib/_homebrew_cleanup.bash
echo '# END SECTION'

echo '# BEGIN SECTION: run the one-liner installation'
curl -ssL https://bitbucket.org/osrf/release-tools/raw/default/one-line-installations/gazebo.sh | sh
echo '# END SECTION'
