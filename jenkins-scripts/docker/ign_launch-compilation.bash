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

export BUILDING_SOFTWARE_DIRECTORY="ign-launch"
export BUILDING_PKG_DEPENDENCIES_VAR_NAME="IGN_LAUNCH_DEPENDENCIES"

# Identify IGN_LAUNCH_MAJOR_VERSION to help with dependency resolution
IGN_LAUNCH_MAJOR_VERSION=$(\
  python ${SCRIPT_DIR}/../tools/detect_cmake_major_version.py \
  ${WORKSPACE}/ign-launch/CMakeLists.txt)

# Check IGN_LAUNCH version is integer
if ! [[ ${IGN_LAUNCH_MAJOR_VERSION} =~ ^-?[0-9]+$ ]]; then
  echo "Error! IGN_LAUNCH_MAJOR_VERSION is not an integer, check the detection"
  exit -1
fi

if [[ ${IGN_LAUNCH_MAJOR_VERSION} -eq 2 ]]; then
  export BUILD_IGN_FUEL_TOOLS=true
  export IGN_FUEL_TOOLS_MAJOR_VERSION=4
  export IGN_FUEL_TOOLS_BRANCH=default
  export BUILD_IGN_SENSORS=true
  export IGN_SENSORS_MAJOR_VERSION=3
  export IGN_SENSORS_BRANCH=default
  export BUILD_IGN_GAZEBO=true
  export IGN_GAZEBO_MAJOR_VERSION=3
  export IGN_GAZEBO_BRANCH=default
fi

export USE_GCC8=true

export GZDEV_PROJECT_NAME="ignition-launch${IGN_LAUNCH_MAJOR_VERSION}"

. ${SCRIPT_DIR}/lib/generic-building-base.bash
