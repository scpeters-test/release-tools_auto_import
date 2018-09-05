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

. "${SCRIPT_DIR}/lib/_gz11_hook.bash"
# All branches requires gz11 support
export NEEDS_GZ11_SUPPORT=true

export BUILDING_SOFTWARE_DIRECTORY="ign-sensors"

if ${NEEDS_GZ11_SUPPORT}; then
  # all dependencies of ign-sensors are ignition/sdformat
  export BUILD_IGN_CMAKE=true
  export BUILD_IGN_TOOLS=true
  export BUILD_IGN_MATH=true
  export BUILD_IGN_COMMON=true
  export BUILD_IGN_MSGS=true
  export BUILD_IGN_TRANSPORT=true
  export BUILD_IGN_RENDERING=true
  export BUILD_SDFORMAT=true
  export BUILDING_PKG_DEPENDENCIES_VAR_NAME="IGN_SENSORS_NO_IGN_DEPENDENCIES"
else
  export BUILDING_PKG_DEPENDENCIES_VAR_NAME="IGN_SENSORS_DEPENDENCIES"
  export BUILDING_JOB_REPOSITORIES="stable"
fi

if [[ $(date +%Y%m%d) -le 20181231 ]]; then
  ## need prerelease repo to get ignition-cmake1 for ign-rendering
  export BUILDING_JOB_REPOSITORIES="${BUILDING_JOB_REPOSITORIES} prerelease"
fi

export GPU_SUPPORT_NEEDED=true

. ${SCRIPT_DIR}/lib/generic-building-base.bash
