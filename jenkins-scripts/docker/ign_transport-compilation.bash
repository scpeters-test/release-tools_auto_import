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

# Identify IGN_TRANSPORT_MAJOR_VERSION to help with dependency resolution
IGN_TRANSPORT_MAJOR_VERSION=$(\
  python ${SCRIPT_DIR}/../tools/detect_cmake_major_version.py \
  ${WORKSPACE}/ign-transport/CMakeLists.txt)

# Check IGN_TRANSPORT version is integer
if ! [[ ${IGN_TRANSPORT_MAJOR_VERSION} =~ ^-?[0-9]+$ ]]; then
  echo "Error! IGN_TRANSPORT_MAJOR_VERSION is not an integer, check the detection"
  exit -1
fi

export BUILDING_SOFTWARE_DIRECTORY="ign-transport"
export BUILDING_PKG_DEPENDENCIES_VAR_NAME="IGN_TRANSPORT_DEPENDENCIES"
export BUILDING_JOB_REPOSITORIES="stable"
if [[ $(date +%Y%m%d) -le 20180201 ]]; then
  ## need prerelease repo to get ignition-cmake during the development cycle
  export BUILDING_JOB_REPOSITORIES="${BUILDING_JOB_REPOSITORIES} prerelease"
fi
# Install Ignition Tools while we release a .deb package.
# ToDo: Remove this env variable after releasing Ignition Tools.
export DOCKER_POSTINSTALL_HOOK="""\
  apt-get update && \\
  apt-get install -y mercurial && \\
  hg clone https://bitbucket.org/ignitionrobotics/ign-tools &&  \\
  mkdir ign-tools/build && \\
  cd ign-tools/build &&  \\
  cmake .. && \\
  make install
"""

. ${SCRIPT_DIR}/lib/generic-building-base.bash
