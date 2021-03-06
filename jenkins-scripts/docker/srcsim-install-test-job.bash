#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export GPU_SUPPORT_NEEDED=true

# Import library
. ${SCRIPT_DIR}/lib/_srcsim_lib.bash

INSTALL_JOB_PREINSTALL_HOOK="""\
${SRCSIM_SETUP_REPOSITORIES}
"""

INSTALL_JOB_POSTINSTALL_HOOK="""
echo '# BEGIN SECTION: testing by running qual1 launch file'
${SRCSIM_INIT_SETUP}
${SRCSIM_ENV_SETUP}

TEST_TIMEOUT=400

TEST_START=\`date +%s\`
timeout --preserve-status \$TEST_TIMEOUT roslaunch srcsim qual2.launch extra_gazebo_args:=\"-r\" init:=\"true\" walk_test:=true || true
TEST_END=\`date +%s\`
DIFF=\`echo \"\$TEST_END - \$TEST_START\" | bc\`

if [ \$DIFF -lt \$TEST_TIMEOUT ]; then
   echo 'The test took less than \$TEST_TIMEOUT. Something bad happened'
   exit 1
fi
echo '# END SECTION'
"""
# Need bc to proper testing and parsing the time
export DEPENDENCY_PKGS="wget bc"
export INSTALL_JOB_PKG="srcsim"

. ${SCRIPT_DIR}/lib/generic-install-base.bash
