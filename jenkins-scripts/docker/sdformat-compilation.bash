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

. "${SCRIPT_DIR}/lib/_sdformat_version_hook.bash"

# Check IGN_MATH version is integer
if ! [[ ${SDFORMAT_MAJOR_VERSION} =~ ^-?[0-9]+$ ]]; then
  echo "Error! SDFORMAT_MAJOR_VERSION is not an integer, check the detection"
  exit -1
fi

. "${SCRIPT_DIR}/lib/_gz11_hook.bash"

export BUILDING_SOFTWARE_DIRECTORY="sdformat"

if [[ ${SDFORMAT_MAJOR_VERSION} -ge 6 ]]; then
  export BUILDING_EXTRA_CMAKE_PARAMS="-DUSE_INTERNAL_URDF:BOOL=True"
fi

if [[ ${SDFORMAT_MAJOR_VERSION} -ge 8 ]]; then
  export USE_GCC8=true
  export BUILDING_JOB_REPOSITORIES="stable prerelease"
else
  export BUILDING_JOB_REPOSITORIES="stable"
fi

# default and major branches compilations
export BUILDING_PKG_DEPENDENCIES_VAR_NAME="SDFORMAT_BASE_DEPENDENCIES"

. "${SCRIPT_DIR}/lib/generic-building-base.bash"
