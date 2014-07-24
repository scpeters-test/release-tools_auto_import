#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export GPU_SUPPORT_NEEDED=true

export DISTRO=raring
export ROS_DISTRO=groovy
export USE_OLD_SDFORMAT=true

. ${SCRIPT_DIR}/lib/gazebo-base-default.bash
