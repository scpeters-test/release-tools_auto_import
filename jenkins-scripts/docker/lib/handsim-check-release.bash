#!/bin/bash -x

echo '# BEGIN SECTION: setup the testing enviroment'
DOCKER_JOB_NAME="handsim_check_release"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh
echo '# END SECTION'

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

echo '# BEGIN SECTION: handsim installation'
apt-get install -y handsim
echo '# END SECTION'

echo '# BEGIN SECTION: test arat.world'
# In our nvidia machines, run the test to launch altas
# Seems like there is no failure in runs on precise pbuilder in
# our trusty machine. So we do not check for GRAPHIC_TESTS=true
mkdir -p \$HOME/.gazebo

# Workaround to issue:
# https://bitbucket.org/osrf/handsim/issue/91
locale-gen en_GB.utf8
export LC_ALL=en_GB.utf8
export LANG=en_GB.utf8
export LANGUAGE=en_GB

# Docker has problems with Qt X11 MIT-SHM extension
export QT_X11_NO_MITSHM=1

timeout 180 gazebo worlds/arat.world || { echo "Failure response in the launch command" ; exit 1 ; }
echo "180 testing seconds finished successfully"
echo '# END SECTION'
DELIM

USE_OSRF_REPO=true
# Install gazebo dependencies to reduce the installation time
# Don't install handsim dependencies to be sure that package manager
# pulls all needed packages
DEPENDENCY_PKGS="${BASE_DEPENDENCIES} ${GAZEBO_BASE_DEPENDENCIES} ${GAZEBO_EXTRA_DEPENDENCIES}"

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
