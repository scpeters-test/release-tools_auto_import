#!/bin/bash -x

#stop on error
set -e

# Keep the option of default to not really send a build type and let our own gazebo cmake rules
# to decide what is the default mode.
if [ -z ${GZ_BUILD_TYPE} ]; then
    GZ_CMAKE_BUILD_TYPE=
else
    GZ_CMAKE_BUILD_TYPE="-DCMAKE_BUILD_TYPE=${GZ_BUILD_TYPE}"
fi

. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

# Default to install plain gazebo in gazebo_pkg is not speficied
if [[ -z $GAZEBO_PKG ]]; then
    export GAZEBO_PKG=gazebo3
fi

# Split package in gazebo3 needs -dev to explore the headers
if [[ $GAZEBO_PKG == 'gazebo3' ]]; then
    GAZEBO_PKG=libgazebo-dev
fi

# Install gazebo from package and git to retrieve api checker
export EXTRA_PACKAGES="${GAZEBO_PKG} git exuberant-ctags"

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

# OSRF repository to get bullet
apt-get install -y wget
sh -c 'echo "deb http://packages.osrfoundation.org/drc/ubuntu ${DISTRO} main" > /etc/apt/sources.list.d/drc-latest.list'
wget http://packages.osrfoundation.org/drc.key -O - | apt-key add -

# Dart repositories
if $DART_FROM_PKGS; then
  # software-properties for apt-add-repository
  apt-get install -y python-software-properties apt-utils software-properties-common
  apt-add-repository -y ppa:libccd-debs
  apt-add-repository -y ppa:fcl-debs
  apt-add-repository -y ppa:dartsim
fi

if $DART_COMPILE_FROM_SOURCE; then
  apt-get install -y python-software-properties apt-utils software-properties-common git
  apt-add-repository -y ppa:libccd-debs
  apt-add-repository -y ppa:fcl-debs
  apt-add-repository -y ppa:dartsim
fi

# Step 1: install everything you need

# Required stuff for Gazebo and install gazebo binary itself
apt-get update
apt-get install -y ${BASE_DEPENDENCIES} ${GAZEBO_BASE_DEPENDENCIES} ${GAZEBO_EXTRA_DEPENDENCIES} ${EXTRA_PACKAGES}

# Step 2: configure and build
# Check for DART
if $DART_COMPILE_FROM_SOURCE; then
  if [ -d $WORKSPACE/dart ]; then
      cd $WORKSPACE/dart
      git pull
  else
     git clone https://github.com/dartsim/dart.git $WORKSPACE/dart
  fi
  rm -fr $WORKSPACE/dart/build
  mkdir -p $WORKSPACE/dart/build
  cd $WORKSPACE/dart/build
  cmake .. \
      -DCMAKE_INSTALL_PREFIX=/usr
  #make -j${MAKE_JOBS}
  make -j1
  make install
fi

# Need multiarch to properly compare against the package version
DEB_HOST_MULTIARCH=\$(dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null)

# Normal cmake routine for Gazebo
rm -rf $WORKSPACE/build $WORKSPACE/install
mkdir -p $WORKSPACE/build $WORKSPACE/install
cd $WORKSPACE/build
cmake ${GZ_CMAKE_BUILD_TYPE}         \\
    -DCMAKE_INSTALL_PREFIX=/usr/local\\
    -DENABLE_SCREEN_TESTS:BOOL=False \\
    -DCMAKE_INSTALL_LIBDIR:STRING="lib/\${DEB_HOST_MULTIARCH}" \\
  $WORKSPACE/gazebo
make -j${MAKE_JOBS}
make install

# Install abi-compliance-checker.git
cd $WORKSPACE
rm -fr $WORKSPACE/abi-compliance-checker
git clone git://github.com/lvc/abi-compliance-checker.git  
cd abi-compliance-checker
perl Makefile.pl -install --prefix=/usr

# Search all packages installed called *gazebo* and list of *.so.* files in these packages
GAZEBO_LIBS=\$(dpkg -L \$(dpkg -l | grep ^ii | grep gazebo | awk '{ print \$2 }' | tr '\\n' ' ') | grep 'lib.*.so.*')
GAZEBO_LIBS_LOCAL=\$(echo \${GAZEBO_LIBS} | tr ' ' '\\n' | sed -e 's:^/usr:/usr/local:g')
BIN_VERSION=\$(dpkg -l ${GAZEBO_PKG} | tail -n 1 | awk '{ print  \$3 }')

GAZEBO_INC_DIR=\$(find /usr/include -name gazebo-* -type d | sed -e 's:.*/::')
GAZEBO_LOCAL_INC_DIR=\$(find /usr/local/include -name gazebo-* -type d | sed -e 's:.*/::')

mkdir -p $WORKSPACE/abi_checker
cd $WORKSPACE/abi_checker
cat > pkg.xml << CURRENT_DELIM
 <version>
     .deb pkg version: \$BIN_VERSION
 </version>

 <headers>
   /usr/include/\$GAZEBO_INC_DIR/gazebo
 </headers>

 <skip_headers>
   /usr/include/\$GAZEBO_INC_DIR/gazebo/GIMPACT
   /usr/include/\$GAZEBO_INC_DIR/gazebo/opcode
   /usr/include/\$GAZEBO_INC_DIR/gazebo/test
 </skip_headers>

 <libs>
  \$GAZEBO_LIBS
 </libs>
CURRENT_DELIM

cat > devel.xml << DEVEL_DELIM
 <version>
     branch: $BRANCH
 </version>
 
  <headers>
   /usr/local/include/\$GAZEBO_LOCAL_INC_DIR/gazebo
 </headers>
 
 <skip_headers>
   /usr/local/include/\$GAZEBO_LOCAL_INC_DIR/gazebo/GIMPACT
   /usr/local/include/\$GAZEBO_LOCAL_INC_DIR/gazebo/opcode
   /usr/local/include/\$GAZEBO_LOCAL_INC_DIR/gazebo/test
 </skip_headers>
 
 <libs>
  \$GAZEBO_LIBS_LOCAL
 </libs>
DEVEL_DELIM

# clean previous reports
rm -fr $WORKSPACE/compat_report.html
rm -fr compat_reports/
# run report tool
abi-compliance-checker -lib gazebo -old pkg.xml -new devel.xml || true
# copy method version independant ( cp ... /*/ ... was not working)
find compat_reports/ -name compat_report.html -exec cp {} $WORKSPACE/ \;
DELIM

# Make project-specific changes here
###################################################

sudo pbuilder  --execute \
    --bindmounts $WORKSPACE \
    --basetgz $basetgz \
    -- build.sh

