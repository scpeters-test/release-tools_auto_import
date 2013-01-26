#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export GAZEBO_DEB_PACKAGE=gazebo-prerelease

. ${SCRIPT_DIR}/lib/drcsim-base.bash
