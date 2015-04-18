#!/bin/bash -x
set -e

# Identify SDFORMAT_MAJOR_VERSION to help with dependency resolution
SDFORMAT_MAJOR_VERSION=`\
  grep 'set.*SDF_MAJOR_VERSION ' ${WORKSPACE}/sdformat/CMakeLists.txt | \
  tr -d 'a-zA-Z _()'`

# Check sdformat version is integer
if ! [[ ${SDFORMAT_MAJOR_VERSION} =~ ^-?[0-9]+$ ]]; then
   echo "Error! SDFORMAT_MAJOR_VERSION is not an integer, check the detection"
   exit -1
fi

echo '# BEGIN SECTION: setup the testing enviroment'
# Define the name to be used in docker
DOCKER_JOB_NAME="sdformat_ci"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh
echo '# END SECTION'

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

echo '# BEGIN SECTION: configure sdformat ${SDFORMAT_MAJOR_VERSION}'
# Step 2: configure and build
cd $WORKSPACE
cd $WORKSPACE/build
cmake $WORKSPACE/sdformat
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
cd $WORKSPACE/sdformat
sh tools/code_check.sh -xmldir $WORKSPACE/build/cppcheck_results || true
cat $WORKSPACE/build/cppcheck_results/*.xml
echo '# END SECTION'
DELIM

DEPENDENCY_PKGS="${SDFORMAT_BASE_DEPENDENCIES}"
SOFTWARE_DIR="sdformat"
. ${SCRIPT_DIR}/lib/docker_dockerfile_header.bash

echo "# BEGIN SECTION: Docker: built with tag ${DOCKER_TAG}"
sudo docker build -t ${DOCKER_TAG} .
echo '# END SECTION'
echo "# BEGIN SECTION: Docker: run build.sh"
rm -rf $WORKSPACE/build
mkdir -p $WORKSPACE/build
sudo docker run \
            --cidfile=${CIDFILE} \
            -v ${WORKSPACE}/build:${WORKSPACE}/build \
            -t ${DOCKER_TAG} \
            /bin/bash build.sh
echo '# END SECTION'

CID=$(cat ${CIDFILE})

# Try to stop the container if it is running
# Do not fail on error, the container is already stoped
sudo docker ps
sudo docker stop ${CID} || true
sudo docker rm ${CID} || true
