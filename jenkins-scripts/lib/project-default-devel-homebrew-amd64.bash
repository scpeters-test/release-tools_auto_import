#!/bin/bash -x
set -e

export HOMEBREW_MAKE_JOBS=${MAKE_JOBS}

# Get project name as first argument to this script
PROJECT=$1 # project will have the major version included (ex gazebo2)
PROJECT_ARGS=${2}

# In ignition projects, the name of the repo and the formula does not match
PROJECT_PATH=${PROJECT}
if [[ ${PROJECT/ignition} != ${PROJECT} ]]; then
    PROJECT_PATH="ign${PROJECT/ignition}"
fi

export HOMEBREW_PREFIX=/usr/local
export HOMEBREW_CELLAR=${HOMEBREW_PREFIX}/Cellar

# make verbose mode?
MAKE_VERBOSE_STR=""
if [[ ${MAKE_VERBOSE} ]]; then
  MAKE_VERBOSE_STR="VERBOSE=1"
fi

# Step 0. Ensure that brew group exists and that current user is member.
if ! dscl . -list /groups/brew; then
  echo Creating brew group
  sudo dseditgroup -o create brew
fi
if ! dsmemberutil checkmembership -U "$(whoami)" -G "brew" \
   | grep "is a member" > /dev/null; then
  echo Adding "$(whoami)" to brew group
  sudo dseditgroup -o edit -a "$(whoami)" -t user brew
fi

# Step 1. Set up homebrew
echo "# BEGIN SECTION: clean up ${HOMEBREW_PREFIX}"
sudo chown -R $(whoami):brew ${HOMEBREW_PREFIX}
cd ${HOMEBREW_PREFIX}
[[ -f .git ]] && git clean -fdx
rm -rf ${HOMEBREW_CELLAR} ${HOMEBREW_PREFIX}/.git && brew cleanup
echo '# END SECTION'

echo '# BEGIN SECTION: install latest homebrew'
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
echo '# END SECTION'

echo '# BEGIN SECTION: brew information'
# Run brew update to get latest versions of formulae
brew update
# Run brew config to print system information
brew config
# Run brew doctor to check for problems with the system
# brew prune to fix some of this problems
brew doctor || brew prune && brew doctor
echo '# END SECTION'

echo '# BEGIN SECTION: setup the osrf/simulation tap'
brew tap osrf/simulation
echo '# END SECTION'

IS_A_HEAD_FORMULA=${IS_A_HEAD_PROJECT:-false}
HEAD_STR=""
if $IS_A_HEAD_PROJECT; then
    HEAD_STR="--HEAD"
fi

echo "# BEGIN SECTION: install ${PROJECT} dependencies"
# Process the package dependencies
brew install ${HEAD_STR} ${PROJECT} ${PROJECT_ARGS} --only-dependencies
echo '# END SECTION'

echo "# BEGIN SECTION: configuring ${PROJECT}"
# Step 3. Manually compile and install ${PROJECT}
cd ${WORKSPACE}/${PROJECT_PATH}
# Need the sudo since the test are running with roots perms to access to GUI
sudo rm -fr ${WORKSPACE}/build
mkdir -p ${WORKSPACE}/build
cd ${WORKSPACE}/build
 
# add X11 path so glxinfo can be found
export PATH="${PATH}:/opt/X11/bin"

# set display before cmake
# search for Xquartz instance owned by current user
export DISPLAY=$(ps ax \
  | grep '[[:digit:]]*:[[:digit:]][[:digit:]].[[:digit:]][[:digit:]] /opt/X11/bin/Xquartz' \
  | grep "auth /Users/$(whoami)/" \
  | sed -e 's@.*Xquartz @@' -e 's@ .*@@'
)
 

cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_INSTALL_PREFIX=/usr/local/Cellar/${PROJECT}/HEAD \
     ${WORKSPACE}/${PROJECT_PATH}
echo "# BEGIN SECTION: compile and install ${PROJECT} ${VERSION}"

echo "# BEGIN SECTION: compile and install ${PROJECT} ${VERSION}"
make -j${MAKE_JOBS} ${MAKE_VERBOSE_STR} install
brew link ${PROJECT}
echo '# END SECTION'

echo "#BEGIN SECTION: docker analysis"
brew doctor
echo '# END SECTION'

echo "# BEGIN SECTION: run tests"
# Need to clean up models before run tests (issue 27)
rm -fr \$HOME/.gazebo/models

cd $WORKSPACE/build/
make test ARGS="-VV" || true
echo '# END SECTION'
