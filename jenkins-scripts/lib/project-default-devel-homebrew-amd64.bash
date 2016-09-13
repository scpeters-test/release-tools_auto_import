#!/bin/bash -x
set -e

[[ -L ${0} ]] && SCRIPT_LIBDIR=$(readlink ${0}) || SCRIPT_LIBDIR=${0}
SCRIPT_LIBDIR="${SCRIPT_LIBDIR%/*}"
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
export PATH=${HOMEBREW_PREFIX}/bin:$PATH

# make verbose mode?
MAKE_VERBOSE_STR=""
if [[ ${MAKE_VERBOSE} ]]; then
  MAKE_VERBOSE_STR="VERBOSE=1"
fi

# Step 1. Set up homebrew
echo "# BEGIN SECTION: clean up ${HOMEBREW_PREFIX}"
. ${SCRIPT_LIBDIR}/_homebrew_cleanup.bash
brew cleanup || echo "brew cleanup couldn't be run"
mkdir -p ${HOMEBREW_CELLAR}
sudo chmod -R ug+rwx ${HOMEBREW_CELLAR}
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

if [[ "${RERUN_FAILED_TESTS}" -gt 0 ]]; then
  # Install lxml for flaky_junit_merge.py
  PIP_PACKAGES_NEEDED="${PIP_PACKAGES_NEEDED} lxml"
fi

if [[ -n "${PIP_PACKAGES_NEEDED}" ]]; then
  brew install python
  export PYTHONPATH=/usr/local/lib/python2.7/site-packages:$PYTHONPATH
  pip install ${PIP_PACKAGES_NEEDED}
fi

if [[ -z "${DISABLE_CCACHE}" ]]; then
  brew install ccache
  export PATH=/usr/local/opt/ccache/libexec:$PATH
fi

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
echo '# END SECTION'

echo "# BEGIN SECTION: configure ${PROJECT}"
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_INSTALL_PREFIX=/usr/local/Cellar/${PROJECT}/HEAD \
     ${WORKSPACE}/${PROJECT_PATH}
echo '# END SECTION'

echo "# BEGIN SECTION: compile and install ${PROJECT}"
make -j${MAKE_JOBS} ${MAKE_VERBOSE_STR} install
brew link ${PROJECT}
echo '# END SECTION'

echo "#BEGIN SECTION: brew doctor analysis"
brew doctor
echo '# END SECTION'

echo "# BEGIN SECTION: run tests"
# Need to clean up models before run tests (issue 27)
rm -fr \$HOME/.gazebo/models test_results*

# Run `make test`
# If it has any failures, then rerun the failed tests one time
# and merge the junit results
if ! make test ARGS="-VV" && [[ "${RERUN_FAILED_TESTS}" -gt 0 ]]; then
  mv test_results test_results0
  mkdir test_results
  # we can't just run ctest --rerun-failed
  # because that might not run the check_test_ran for failed tests
  echo Failed tests:
  ctest -N --rerun-failed
  FAILED_TESTS=$(ctest -N --rerun-failed \
    | grep 'Test  *#[0-9][0-9]*:' \
    | sed -e 's@^ *Test  *#[0-9]*: *@@' \
  )
  for i in ${FAILED_TESTS}; do
    make test ARGS="-VV -R ${i}\$$" || true
  done
  mkdir test_results_tmp
  for i in $(ls test_results); do
    echo looking for flaky tests in test_results0/$i and test_results/$i
    python ${WORKSPACE}/scripts/jenkins-scripts/tools/flaky_junit_merge.py \
      test_results0/$i test_results/$i \
      > test_results_tmp/$i
    mv test_results_tmp/$i test_results0
  done
  mv test_results test_results1
  mv test_results0 test_results
fi
echo '# END SECTION'

echo "# BEGIN SECTION: re-add group write permissions"
sudo chmod -R ug+rwx ${HOMEBREW_CELLAR}
echo '# END SECTION'
