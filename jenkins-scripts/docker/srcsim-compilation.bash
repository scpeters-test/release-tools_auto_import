#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

if [[ -z ${ARCH} ]]; then
  echo "ARCH variable not set!"
  exit 1
fi

if [[ -z ${DISTRO} ]]; then
  echo "DISTRO variable not set!"
  exit 1
fi

case ${DISTRO} in
  'trusty')
    ROS_DISTRO=indigo
    PKG_VERSION="7"
    ;;
  'xenial')
    ROS_DISTRO=kinetic
    PKG_VERSION="" # xenial uses 7 by default
    ;;
  *)
    echo "Unsupported DISTRO: ${DISTRO}"
    exit 1
esac

export GPU_SUPPORT_NEEDED=true

# Import library
. ${SCRIPT_DIR}/lib/_srcsim_lib.bash

export BUILDING_SOFTWARE_DIRECTORY="srcsim"
export BUILDING_DEPENDENCIES="ros-${ROS_DISTRO}-gazebo${PKG_VERSION}-plugins \\
                              ros-${ROS_DISTRO}-gazebo${PKG_VERSION}-ros \\
                              ros-${ROS_DISTRO}-message-generation \\
                              ros-${ROS_DISTRO}-message-runtime \\
                              ros-${ROS_DISTRO}-xacro"
# Use src temporary repo
export DOCKER_PREINSTALL_HOOK="""\
${SRCSIM_SETUP_REPOSITORIES}
"""

export BUILDING_JOB_REPOSITORIES="stable"

. ${SCRIPT_DIR}/lib/generic-building-base.bash
