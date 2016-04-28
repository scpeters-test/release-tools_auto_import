#!/bin/bash -x

# Do not use the subprocess_reaper in debbuild. Seems not as needed as in
# testing jobs and seems to be slow at the end of jenkins jobs
export ENABLE_REAPER=false

. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

# Use defaul branch if not sending BRANCH parameter
[[ -z ${BRANCH} ]] && export BRANCH=master

# Workaround to make this work on ARM since git over qemu
# is broken
echo '# BEGIN SECTION: clone the git repo'
rm -fr $WORKSPACE/repo
git clone $GIT_REPOSITORY $WORKSPACE/repo
cd $WORKSPACE/repo
git checkout -b ${BRANCH}
echo '# END SECTION'

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
#!/usr/bin/env bash
set -ex

echo '# BEGIN SECTION: install build dependencies'
mk-build-deps -r -i debian/control --tool 'apt-get --yes -o Debug::pkgProblemResolver=yes -o  Debug::BuildDeps=yes'
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

# Do not perform symbol checking
rm -fr debian/*.symbols
echo '# END SECTION'

echo "# BEGIN SECTION: create source package \${OSRF_VERSION}"
gbp buildpackage -j${MAKE_JOBS} --git-ignore-new -S -uc -us

cp ../*.dsc $WORKSPACE/pkgs
cp ../*.tar.gz $WORKSPACE/pkgs
cp ../*.orig.* $WORKSPACE/pkgs
cp ../*.debian.* $WORKSPACE/pkgs
echo '# END SECTION'

echo '# BEGIN SECTION: create deb packages'
gbp buildpackage -j${MAKE_JOBS} --git-ignore-new -uc -us
echo '# END SECTION'

echo '# BEGIN SECTION: export pkgs'
PKGS=\`find ../ -name *.deb || true\`

FOUND_PKG=0
for pkg in \${PKGS}; do
    echo "found \$pkg"
    cp \${pkg} $WORKSPACE/pkgs
    FOUND_PKG=1
done
# check at least one upload
test \$FOUND_PKG -eq 1 || exit 1
echo '# END SECTION'
DELIM

OSRF_REPOS_TO_USE="${OSRF_REPOS_TO_USE:-stable}"
DEPENDENCY_PKGS="devscripts \
		 ubuntu-dev-tools \
		 debhelper \
		 wget \
		 ca-certificates \
		 equivs \
		 git \
		 git-buildpackage"

. ${SCRIPT_DIR}/lib/docker_generate_dockerfile.bash
. ${SCRIPT_DIR}/lib/docker_run.bash
