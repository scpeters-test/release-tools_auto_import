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

# No explicit activation means no coverage
[ -z ${COVERAGE_ENABLED} ] && COVERAGE_ENABLED=false

. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

set +x # keep password secret
BULLSEYE_LICENSE=`cat $HOME/bullseye-jenkins-license`
set -x # back to debug

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

# Required stuff for Gazebo
apt-get update
apt-get install -y --force-yes  ${BASE_DEPENDENCIES} ${GAZEBO_BASE_DEPENDENCIES} ${GAZEBO_EXTRA_DEPENDENCIES} ${EXTRA_PACKAGES}

# Optional stuff. Check for graphic card support
if ${GRAPHIC_CARD_FOUND}; then
    apt-get install -y ${GRAPHIC_CARD_PKG}
    # Check to be sure version of kernel graphic card support is the same.
    # It will kill DRI otherwise
    CHROOT_GRAPHIC_CARD_PKG_VERSION=\$(dpkg -l | grep "^ii.*${GRAPHIC_CARD_PKG}\ " | awk '{ print \$3 }' | sed 's:-.*::')
    if [ "\${CHROOT_GRAPHIC_CARD_PKG_VERSION}" != "${GRAPHIC_CARD_PKG_VERSION}" ]; then
       echo "Package ${GRAPHIC_CARD_PKG} has different version in chroot and host system. Maybe you need to update your host" 
       exit 1
    fi
fi


if ${COVERAGE_ENABLED} ; then
  # Clean previous content
  rm -fr $WORKSPACE/coverage
  # Download and install Bullseyes
  cd $WORKSPACE
  rm -fr $WORKSPACE/Bulls*
  
  # Look for current version. NOT IN USE since we lost the maintenance support on 2014 
  # reenable if the support is back.
  # wget http://www.bullseye.com/download/ -O bull_index.html
  # BULL_TAR=\$( grep -R BullseyeCoverage-.*-Linux-x64.tar bull_index.html | head -n 1 | sed 's/.*">//' | sed 's/<.*//' )
  # wget http://www.bullseye.com/download/\$BULL_TAR -O bullseye.tar

  # Download package
  wget https://www.dropbox.com/s/i1ay7t8sg8i77jr/bullseye-8.8.9.tar -O bullseye.tar
  tar -xf bullseye.tar
  cd Bulls*
  # Set up the license
  echo $PATH >install-path
  rm -fr /usr/bullseyes
  set +x # keep password secret
  ./install --prefix /usr/bullseyes --key $BULLSEYE_LICENSE
  set -x # back to debug
  # Set up Bullseyes for compiling
  export PATH=/usr/bullseyes/bin:\$PATH
  export COVFILE=$WORKSPACE/gazebo/test.cov
  cd $WORKSPACE/gazebo
  covselect --file test.cov --add .
  cov01 --on
fi

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

# Normal cmake routine for Gazebo
rm -rf $WORKSPACE/build $WORKSPACE/install
mkdir -p $WORKSPACE/build $WORKSPACE/install
cd $WORKSPACE/build
cmake ${GZ_CMAKE_BUILD_TYPE}         \\
    -DCMAKE_INSTALL_PREFIX=/usr      \\
    -DENABLE_SCREEN_TESTS:BOOL=False \\
  $WORKSPACE/gazebo
make -j${MAKE_JOBS}
make install
. /usr/share/gazebo/setup.sh

# Need to clean up from previous built
rm -fr $WORKSPACE/cppcheck_results
rm -fr $WORKSPACE/test_results

# Run tests
make test ARGS="-VV -R UNIT_*" || true
make test ARGS="-VV -R INTEGRATION_*" || true
make test ARGS="-VV -R REGRESSION_*" || true
make test ARGS="-VV -R EXAMPLE_*" || true

# Only run cppcheck on trusty
if [ "$DISTRO" = "trusty" ]; then 
  # Step 3: code check
  cd $WORKSPACE/gazebo
  sh tools/code_check.sh -xmldir $WORKSPACE/build/cppcheck_results || true
else
  mkdir -p $WORKSPACE/build/cppcheck_results/
  echo "<results></results>" >> $WORKSPACE/build/cppcheck_results/empty.xml 
fi

# Step 4: generate code coverage if enabled
if ${COVERAGE_ENABLED} ; then
  rm -fr $WORKSPACE/coverage
  rm -fr $WORKSPACE/bullshtml
  mkdir -p $WORKSPACE/coverage
  covselect --add '!$WORKSPACE/build/' '!../build/' '!test/' '!tools/test/' '!deps/' '!/opt/' '!gazebo/rendering/skyx/' '!/tmp/'
  covhtml --srcdir $WORKSPACE/gazebo/ $WORKSPACE/coverage
  # Generate valid cover.xml file using the bullshtml software
  # java is needed to run bullshtml
  apt-get install -y default-jre
  cd $WORKSPACE
  wget http://bullshtml.googlecode.com/files/bullshtml_1.0.5.tar.gz -O bullshtml.tar.gz
  tar -xzf bullshtml.tar.gz
  cd bullshtml
  sh bullshtml .
  # Hack to remove long paths from report
  find . -name '*.html' -exec sed -i -e 's:${WORKSPACE}::g' {} \;
fi

# Step 4: copy test log
# Broken http://build.osrfoundation.org/job/gazebo-any-devel-precise-amd64-gpu-nvidia/6/console
# Need fix
# mkdir $WORKSPACE/logs
# cp $HOME/.gazebo/logs/*.log $WORKSPACE/logs/

# Step 5. Need to clean build/ directory so disk space is under control
# Move cppcheck and test results out of build
# Copy the results
mv $WORKSPACE/build/cppcheck_results $WORKSPACE/cppcheck_results
mv $WORKSPACE/build/test_results $WORKSPACE/test_results
rm -fr $WORKSPACE/build
mkdir -p $WORKSPACE/build
# To keep backwards compatibility with current configurations keep a copy
# of tests_results in the build path.
cp -a $WORKSPACE/cppcheck_results $WORKSPACE/build/cppcheck_results
cp -a $WORKSPACE/test_results $WORKSPACE/build/test_results
DELIM

# Make project-specific changes here
###################################################

sudo pbuilder  --execute \
    --bindmounts $WORKSPACE \
    --basetgz $basetgz \
    -- build.sh

