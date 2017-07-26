#!/bin/bash -x

echo '# BEGIN SECTION: setup the testing enviroment'
DOCKER_JOB_NAME="drake_ci"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh
echo '# END SECTION'

cat > build.sh << DELIM
###################################################
#
set -ex

echo '# BEGIN SECTION: install bazel'
echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list
curl https://bazel.build/bazel-release.pub.gpg | apt-key add -
apt-get update
apt-get install -y bazel
echo '# END SECTION'

echo '# BEGIN SECTION: compilation'
cd ${WORKSPACE}/repo
bazel run :install --jobs=${MAKE_JOBS} -- ${WORKSPACE}/install
echo '# END SECTION'
DELIM

SOFTWARE_DIR="repo"
OSRF_REPOS_TO_USE="stable"
DEPENDENCY_PKGS="${BASE_DEPENDENCIES} \
                 openjdk-8-jdk \
                 python2.7"

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
