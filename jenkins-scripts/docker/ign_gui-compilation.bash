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

export BUILDING_SOFTWARE_DIRECTORY="ign-gui"
export BUILDING_PKG_DEPENDENCIES_VAR_NAME="IGN_GUI_DEPENDENCIES"
export BUILDING_JOB_REPOSITORIES="stable"
if [[ $(date +%Y%m%d) -le 20171229 ]]; then
  ## need prerelease repo to get ignition-cmake during the development cycle
  export BUILDING_JOB_REPOSITORIES="${BUILDING_JOB_REPOSITORIES} prerelease"
fi

# TODO: stop building dependencies from source after there's a release
export BUILD_IGN_TRANSPORT=true
export BUILD_IGN_RENDERING=true

export GPU_SUPPORT_NEEDED=true

. ${SCRIPT_DIR}/lib/generic-building-base.bash
