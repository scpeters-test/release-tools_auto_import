#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

BUILD_SH_SCRIPT="${SCRIPT_DIR}/build/build-gazebo1.4-quantal.sh"

. ${SCRIPT_DIR}/generators/generator-quantal.sh
