#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export GPU_SUPPORT_NEEDED=true
export USE_DOCKER_IN_DOCKER=true

. ${SCRIPT_DIR}/lib/_install_nvidia_docker.sh

export INSTALL_JOB_POSTINSTALL_HOOK="""
echo '# BEGIN SECTION: testing by running dockerhub'

${INSTALL_NVIDIA_DOCKER1}

nvidia-docker run -it -e DISPLAY -e QT_X11_NO_MITSHM=1 -e XAUTHORITY=\$XAUTH -v \"/tmp/.X11-unix:/tmp/.X11-unix\" -v \"/etc/localtime:/etc/localtime:ro\" -v \"/dev/input:/dev/input\" --network host --rm --privileged --security-opt seccomp=unconfined nkoenig/subt-virtual-testbed tunnel_circuit_practice.ign worldName:=tunnel_circuit_practice_01 robotName1:=X1 robotConfig1:=X1_SENSOR_CONFIG1

echo '# END SECTION'
"""

export DEPENDENCY_PKGS="${DEPENDENCY_PKGS} software-properties-common xauth"

. ${SCRIPT_DIR}/lib/generic-install-base.bash
