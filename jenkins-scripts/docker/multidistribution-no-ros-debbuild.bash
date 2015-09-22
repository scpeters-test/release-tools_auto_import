#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export ENABLE_ROS=false
export OSRF_REPOS_TO_USE=${OSRF_REPOS_TO_USE:=stable}

. ${SCRIPT_DIR}/lib/debbuild-base.bash
