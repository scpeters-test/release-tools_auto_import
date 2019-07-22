INSTALL_NVIDIA_DOCKER1="""
echo '# BEGIN SECTION: install docker (in docker)'
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\"
apt-get update
apt-get install -y docker-ce
echo '# END SECTION'

echo '# BEGIN SECTION: install nvidia-docker (in docker)'
apt-get install -y wget nvidia-340 nvidia-modprobe
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb
dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb
echo '# END SECTION'
"""
