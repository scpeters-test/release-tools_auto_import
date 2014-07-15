#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

# Hack to pick from current processes the DISPLAY available
for i in `ls /tmp/.X11-unix/ | head -1 | sed -e 's@^X@:@'`
do
  ps aux | grep bin/X.*$i | grep -v grep
  if [ $? -eq 0 ] ; then
    export DISPLAY=$i
  fi
done

export DISTRO=trusty
export ROS_DISTRO=groovy
export DART_USE_4_VERSION=true

. ${SCRIPT_DIR}/lib/gazebo-base-default.bash
