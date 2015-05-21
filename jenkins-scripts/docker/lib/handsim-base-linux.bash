#!/bin/bash -x

echo '# BEGIN SECTION: setup the testing enviroment'
USE_OSRF_REPO=true
USE_GPU_DOCKER=true
SOFTWARE_DIR="handsim"
DEPENDENCY_PKGS="${HANDSIM_DEPENDENCIES}"

DOCKER_JOB_NAME="handsim_ci"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh
echo '# END SECTION'

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

# Not really needed?
# export DISPLAY=${DISPLAY}

echo '# BEGIN SECTION: configuring"
mkdir -p $WORKSPACE/build
cd $WORKSPACE/build
cmake $WORKSPACE/handsim
echo '# END SECTION'

echo '# BEGIN SECTION: compiling'
make -j${MAKE_JOBS}
echo '# END SECTION'

echo '# BEGIN SECTION: installing'
make install
echo '# END SECTION'

echo '# BEGIN SECTION: running tests'
mkdir -p \$HOME
make test ARGS="-VV" || true
echo '# END SECTION'

echo '# BEGIN SECTION: cppcheck'
cd $WORKSPACE/handsim
sh tools/code_check.sh -xmldir $WORKSPACE/build/cppcheck_results || true
cat $WORKSPACE/build/cppcheck_results/*.xml
echo '# END SECTION'
DELIM

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
