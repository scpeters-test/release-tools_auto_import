#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export GPU_SUPPORT_NEEDED=true
export USE_DOCKER_IN_DOCKER=true

. ${SCRIPT_DIR}/lib/_install_nvidia_docker.sh

export INSTALL_JOB_POSTINSTALL_HOOK="""
${INSTALL_NVIDIA_DOCKER2}
xhost +
echo '# BEGIN SECTION: testing - download'
cd $WORKSPACE
mkdir -p ~/subt_docker/subt && cd ~/subt_docker/subt
wget https://bitbucket.org/osrf/subt/raw/tunnel_circuit/docker/subt_shell/Dockerfile
# need to workaround the fact of using root for docker
sed -i -e s:--uid\\ \\$\\{user_id\\}:: Dockerfile
cd ..
wget https://bitbucket.org/osrf/subt/raw/tunnel_circuit/docker/build.bash
wget https://bitbucket.org/osrf/subt/raw/tunnel_circuit/docker/run.bash
wget https://bitbucket.org/osrf/subt/raw/tunnel_circuit/docker/join.bash
chmod u+x build.bash run.bash join.bash
echo '# END SECTION'
echo '# BEGIN SECTION: testing - build'
./build.bash subt
echo '# END SECTION'
echo '# BEGIN SECTION: testing - run'
touch /root/.Xauthority
./run.bash subt
echo '# END SECTION'
"""

export DEPENDENCY_PKGS="${DEPENDENCY_PKGS} software-properties-common wget x11-xserver-utils"

. ${SCRIPT_DIR}/lib/generic-install-base.bash
