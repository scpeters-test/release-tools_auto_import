#!/bin/bash -x

# Use always GPU in drcsim project
export GPU_SUPPORT_NEEDED=true

# Do not use the subprocess_reaper in debbuild. Seems not as needed as in
# testing jobs and seems to be slow at the end of jenkins jobs
export ENABLE_REAPER=false

DOCKER_JOB_NAME="gazebo_ros_pkgs_ci"
. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

# Generate the first part of the build.sh file for ROS
CATKIN_EXTRA_ARGS="--cmake-args -DENABLE_DISPLAY_TESTS:BOOL=ON"
ROS_SETUP_PREINSTALL_HOOK="wget https://bitbucket.org/osrf/gazebo_models/get/default.zip && unzip -d \$HOME default.zip"

. ${SCRIPT_DIR}/lib/_ros_setup_buildsh.bash "gazebo_ros_pkgs"

# don't have rosdep at this point and want gazebo to be cached by docker
DEPENDENCY_PKGS="${ROS_GAZEBO_PKGS_DEPENDENCIES} ${_GZ_ROS_PACKAGES} unzip wget"
USE_ROS_REPO=true

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
