DRAKE_BAZEL_INSTALL="""
echo '# BEGIN SECTION: install bazel'
apt-get update
apt-get install -o Dpkg::Options::=\"--force-overwrite\" -y openjdk-8-jdk bash-completion zlib1g-dev
update-alternatives --install \"/usr/bin/java\" \"java\" \"/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java\" 1
update-alternatives --install \"/usr/bin/javac\" \"javac\" \"/usr/lib/jvm/java-8-openjdk-amd64/bin/javac\" 1
update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
# Install Bazel. Part of the install_prereq.sh script from Drake. They are not using the latest version of bazel
wget -O /tmp/bazel_0.6.1-linux-x86_64.deb https://github.com/bazelbuild/bazel/releases/download/0.6.1/bazel_0.6.1-linux-x86_64.deb
if echo '5012d064a6e95836db899fec0a2ee2209d2726fae4a79b08c8ceb61049a115cd /tmp/bazel_0.6.1-linux-x86_64.deb' | sha256sum -c -; then
  dpkg -i /tmp/bazel_0.6.1-linux-x86_64.deb
else
  echo 'The Bazel deb does not have the expected SHA256.  Not installing Bazel.'
  exit -1
fi
echo '# END SECTION'
"""

DRAKE_INSTALL_PREREQ="""
echo '# BEGIN SECTION: install Drake dependencies'
INSTALL_PREREQS_DIR=\"${WORKSPACE}/repo/setup/ubuntu/16.04\"
INSTALL_PREREQS_FILE=\"\\\$INSTALL_PREREQS_DIR/install_prereqs.sh\"
# Remove last cmake dependencies
sed -i -e '/# TODO\(jamiesnape\).*/,\$d' \\\$INSTALL_PREREQS_FILE
# Install automatically all apt commands
sed -i -e 's:no-install-recommends:no-install-recommends -y:g' \\\$INSTALL_PREREQS_FILE
# Remove question to user
sed -i -e 's:.* read .*:yn=Y:g' \\\$INSTALL_PREREQS_FILE
chmod +x \\\$INSTALL_PREREQS_FILE
bash \\\$INSTALL_PREREQS_FILE
echo '# END SECTION'
"""

DRAKE_SHAMBHALA_TESTS="""
echo '# BEGIN SECTION: compile drake-shambhala tests'
cd ${WORKSPACE}
[[ -d drake-shambhala ]] && rm -fr drake-shambhala
git clone https://github.com/RobotLocomotion/drake-shambhala
cd drake-shambhala/drake_cmake_installed
mkdir build
cd build
cmake -Ddrake_DIR=/opt/drake/lib/cmake/drake ..
make -j${MAKE_JOBS}
echo '# END SECTION'

echo '# BEGIN SECTION: particle test'
cd ${WORKSPACE}/drake-shambhala/drake_cmake_installed/build/src/particles
./uniformly_accelerated_particle_demo -simulation_time 5
echo '# END SECTION'

echo '# BEGIN SECTION: pcl test'
cd ${WORKSPACE}/drake-shambhala/drake_cmake_installed/build/src/pcl
./simple_pcl_example
echo '# END SECTION'

"""

# Bazel test result parsing
cat > ${WORKSPACE}/bazel.parser << DELIM_PARSER
warning /^TIMEOUT: /
DELIM_PARSER
