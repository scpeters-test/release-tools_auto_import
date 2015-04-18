#!/bin/bash -x

# Do not use the subprocess_reaper in debbuild. Seems not as needed as in
# testing jobs and seems to be slow at the end of jenkins jobs
export ENABLE_REAPER=false

. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

# If no value for MULTIARCH_SUPPORT was submitted and
# distro is precise, disable the multiarch, this is generally
# since the use of GNUINSTALLDIRs
if [[ -z ${MULTIARCH_SUPPORT} ]]; then
  if [[ $DISTRO == 'precise' ]]; then
    MULTIARCH_SUPPORT=false
  fi
fi

# Use defaul branch if not sending BRANCH parameter
[[ -z ${BRANCH} ]] && export BRANCH=default

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
#!/usr/bin/env bash
set -ex

# Need to run apt-get update to get latest osrf releases
apt-get update

# Step 0: Clean up
rm -rf $WORKSPACE/build
mkdir -p $WORKSPACE/build
cd $WORKSPACE/build

echo '# BEGIN SECTION: clone the git repo'
rm -fr $WORKSPACE/repo
git clone $GIT_REPOSITORY $WORKSPACE/repo
cd $WORKSPACE/repo
git checkout -b ${BRANCH}
echo '# END SECTION'

echo '# BEGIN SECTION: install build dependencies'
mk-build-deps -i debian/control --tool 'apt-get --no-install-recommends --yes'
rm *build-deps*.deb
echo '# END SECTION'

echo '# BEGIN SECTION: build version and distribution'
VERSION=\$(dpkg-parsechangelog  | grep Version | awk '{print \$2}')
VERSION_NO_REVISION=\$(echo \$VERSION | sed 's:-.*::')
OSRF_VERSION=\$VERSION\osrf${RELEASE_VERSION}~${DISTRO}${RELEASE_ARCH_VERSION}
sed -i -e "s:\$VERSION:\$OSRF_VERSION:g" debian/changelog

# Use current distro (unstable or experimental are in debian)
changelog_distro=\$(dpkg-parsechangelog | grep Distribution | awk '{print \$2}')
sed -i -e "1 s:\$changelog_distro:$DISTRO:" debian/changelog

# When backported from Vivid (or above) to Trusty/Utopic some packages are not
# avilable or names are different
if [ $DISTRO = 'trusty' ]; then
  # libbullet-dev is the name in Ubuntu, libbullet2.82.dev is the one in OSRF
  sed -i -e 's:libbullet-dev:libbullet2.82-dev:g' debian/control
fi
if [ $DISTRO = 'trusty' ] || [ $DISTRO = 'utopic' ]; then
  # libsdformat-dev is the name in Ubuntu, libsdformat2-dev is the one in OSRF
  sed -i -e 's:libsdformat-dev:libsdformat2-dev:g' debian/control 
fi

# In precise, no multiarch paths was implemented in GNUInstallDirs. Remove it.
if ! $MULTIARCH_SUPPORT; then
  sed -i -e 's:/\*/:/:g' debian/*.install
fi

# Do not perform symbol checking
rm -fr debian/*.symbols
echo '# END SECTION'

echo "# BEGIN SECTION: create source package \${OSRF_VERSION}"
git-buildpackage -j${MAKE_JOBS} --git-ignore-new -S

cp ../*.dsc $WORKSPACE/pkgs
cp ../*.orig.* $WORKSPACE/pkgs
cp ../*.debian.* $WORKSPACE/pkgs
echo '# END SECTION'

echo '# BEGIN SECTION: create deb packages'
export DEB_BUILD_OPTIONS="parallel=$MAKE_JOBS"
# Step 6: use pbuilder-dist to create binary package(s)
git-buildpackage -j${MAKE_JOBS} --git-ignore-new -S
echo '# END SECTION'

echo '# BEGIN SECTION: export pkgs'
PKGS=\`find /var/lib/jenkins/pbuilder/*_result* -name *.deb || true\`

FOUND_PKG=0
for pkg in \${PKGS}; do
    echo "found \$pkg"
    # Check for correctly generated packages size > 3Kb
    test -z \$(find \$pkg -size +3k) && exit 1
    cp \${pkg} $WORKSPACE/pkgs
    FOUND_PKG=1
done
# check at least one upload
test \$FOUND_PKG -eq 1 || exit 1
echo '# END SECTION'
DELIM

USE_OSRF_REPO=true
DEPENDENCY_PKGS="devscripts \
		 ubuntu-dev-tools \
		 debhelper \
		 wget \
		 ca-certificates \
		 git \
		 git-buildpackage"

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
