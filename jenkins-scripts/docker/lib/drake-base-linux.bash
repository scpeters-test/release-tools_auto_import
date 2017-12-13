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

echo '# BEGIN SECTION: install Drake dependencies'
INSTALL_PREREQS_DIR="${WORKSPACE}/repo/setup/ubuntu/16.04"
INSTALL_PREREQS_FILE="\$INSTALL_PREREQS_DIR/install_prereqs.sh"
# Remove last cmake dependencies
sed -i -e '/# TODO\(jamiesnape\).*/,\$d' \$INSTALL_PREREQS_FILE
# Install automatically all apt commands
sed -i -e 's:no-install-recommends:no-install-recommends -y:g' \$INSTALL_PREREQS_FILE
# Remove question to user
sed -i -e 's:.* read .*:yn=Y:g' \$INSTALL_PREREQS_FILE
chmod +x \$INSTALL_PREREQS_FILE
bash \$INSTALL_PREREQS_FILE
echo '# END SECTION'

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

echo '# BEGIN SECTION: compile tests'
cd ${WORKSPACE}
[[ -d drake-shambhala ]] && rm -fr drake-shambhala
git clone https://github.com/RobotLocomotion/drake-shambhala
cd drake-shambhala/drake_cmake_installed
mkdir build
cd build
cmake -Ddrake_DIR=/opt/drake/lib/cmake/drake ..
make -j${MAKE_JOBS}
echo '# END SECTION'

echo '# BEGIN SECTION: particle test'
cd ${WORKSPACE}/drake-shambhala/drake_cmake_installed/build/src/particles
./uniformly_accelerated_particle_demo -simulation_time 5
echo '# END SECTION'

echo '# BEGIN SECTION: pcl test'
cd ${WORKSPACE}/drake-shambhala/drake_cmake_installed/build/src/pcl
./simple_pcl_example
echo '# END SECTION'
DELIM

SOFTWARE_DIR="repo"
OSRF_REPOS_TO_USE="stable"
USE_ROS_REPO="true" # Needed for libfcl-0.5-dev package
# pcl and proj for the PCL example
DEPENDENCY_PKGS="git \
                 wget \
                 libpcl-dev \
                 libproj-dev \
                 ${BASE_DEPENDENCIES} \
                 ${DRAKE_DEPENDENCIES}"

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
