#!/bin/bash -x

#stop on error
set -e

# Drake can not work with ccache
export ENABLE_CCACHE=false

echo '# BEGIN SECTION: setup the testing enviroment'
DOCKER_JOB_NAME="drake_ci"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh
echo '# END SECTION'

export CHECK_BINARY_SYMBOLS=${CHECK_BINARY_SYMBOLS:=false}

. ${SCRIPT_DIR}/lib/_drake_lib.bash

cat > build.sh << DELIM
###################################################
#
set -ex

${DRAKE_BAZEL_INSTALL}

${DRAKE_INSTALL_PREREQ}

echo '# BEGIN SECTION: compilation'
cd ${WORKSPACE}/repo
bazel build --compiler=gcc-5 --jobs=${MAKE_JOBS} //...
echo '# END SECTION'

echo '# BEGIN SECTION: tests'
bazel test //... || true
echo '# END SECTION'

echo '# BEGIN SECTION: install'
bazel run :install --jobs=${MAKE_JOBS} -- /opt/drake
echo '# END SECTION'

if ${CHECK_BINARY_SYMBOLS}; then
  echo '# BEGIN SECTION: find fcl symbols'
  nm -D /opt/drake/lib/libdrake.so | grep fcl || true
  echo '# END SECTION'
  echo '# BEGIN SECTION: find ccd symbols'
  nm -D /opt/drake/lib/libdrake.so | grep ' ccd' || true
  echo '# END SECTION'
  echo '# BEGIN SECTION: find octomap symbols'
  nm -D /opt/drake/lib/libdrake.so | grep octomap || true
  echo '# END SECTION'
fi

${DRAKE_SHAMBHALA_TESTS}
DELIM

SOFTWARE_DIR="repo"
OSRF_REPOS_TO_USE="stable"
USE_ROS_REPO="true" # Needed for libfcl-0.5-dev package
# pcl and proj for the PCL example
DEPENDENCY_PKGS="git \
                 wget \
                 libvtk6-dev \
                 libpcl-dev \
                 libproj-dev \
                 ${BASE_DEPENDENCIES} \
                 ${DRAKE_DEPENDENCIES}"

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
