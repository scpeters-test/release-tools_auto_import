#!/bin/bash -x
set -e

. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex

# Step 1: install everything you need
apt-get install -y ${BASE_DEPENDENCIES} ${SDFORMAT_BASE_DEPENDENCIES}

# Step 2: configure and build
rm -rf $WORKSPACE/build
mkdir -p $WORKSPACE/build
cd $WORKSPACE/build
cmake $WORKSPACE/sdformat
make -j${MAKE_JOBS}
make test ARGS="-VV" || true

# Step 3: code check
cd $WORKSPACE/sdformat
sh tools/code_check.sh -xmldir $WORKSPACE/build/cppcheck_results || true
cat $WORKSPACE/build/cppcheck_results/*.xml
DELIM

# Make project-specific changes here
###################################################

sudo pbuilder  --execute \
    --bindmounts $WORKSPACE \
    --basetgz $basetgz \
    -- build.sh
