echo '# BEGIN SECTION: setup the testing enviroment'
export DOCKER_JOB_NAME="gzdev"
. "${SCRIPT_DIR}/lib/boilerplate_prepare.sh"
echo '# END SECTION'

cat > build.sh << DELIM
###################################################
#
set -ex

export MAKE_JOBS=${MAKE_JOBS}
export DISPLAY=${DISPLAY}

echo '# BEGIN SECTION: install docker (in docker)'
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y docker-ce
echo '# END SECTION'

echo '# BEGIN SECTION: install nvidia-docker (in docker)'
apt-get install -y wget
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb
dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb
echo '# END SECTION'

echo '# BEGIN SECTION: install pip requirements'
cd ${WORKSPACE}/gzdev
pip3 install -r requirements.txt
echo '# END SECTION'

echo '# BEGIN SECTION: run gzdev for gazebo9 with nvidia'
cd ${WORKSPACE}/gzdev
./gzdev.py spawn --gzv=8 --nvidia &
echo '# END SECTION'

echo '# BEGIN SECTION: check that gazebo is running'
gazebo_detection=false
seconds_waiting=0
while (! \$gazebo_detection); do
   sleep 1
   (ps aux | pgrep gazebo) && gazebo_detection=true
   seconds_waiting=\$((seconds_waiting+1))
   [ \$seconds_waiting -gt 30 ] && exit 1
done
echo '# END SECTION'

echo '# BEGIN SECTION: Disply log file.'
cat ./gz8.log
echo '# END SECTION'

DELIM

export USE_DOCKER_IN_DOCKER=true
export OSRF_REPOS_TO_USE="stable"
export DEPENDENCY_PKGS="python3-pip \
                 bash \
                 apt-transport-https \
                 ca-certificates \
                 curl \
                 software-properties-common"

. "${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash"
. "${SCRIPT_DIR}/lib/docker_run.bash"
