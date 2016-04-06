if [[ -z ${SOFTWARE_DIR} ]]; then
    echo "SOFTWARE_DIR variable is unset. Please fix the code"
    exit 1
fi

cat > build.sh << DELIM
#!/bin/bash
###################################################
# Make project-specific changes here
#
set -ex
source ${TIMING_DIR}/_time_lib.sh ${WORKSPACE}

echo '# BEGIN SECTION: configure'
# Step 2: configure and build
cd $WORKSPACE
cd $WORKSPACE/build
cmake $WORKSPACE/${SOFTWARE_DIR} \
    -DCMAKE_INSTALL_PREFIX=/usr
echo '# END SECTION'

echo '# BEGIN SECTION: compiling'
init_stopwatch COMPILATION
make -j${MAKE_JOBS}
echo '# END SECTION'

echo '# BEGIN SECTION: installing'
make install
stop_stopwatch COMPILATION
echo '# END SECTION'

echo '# BEGIN SECTION: running tests'
init_stopwatch TEST
mkdir -p \$HOME
make test ARGS="-VV" || true
stop_stopwatch TEST
echo '# END SECTION'

echo '# BEGIN SECTION: cppcheck'
cd $WORKSPACE/${SOFTWARE_DIR}
if [ ! -f tools/cpplint_to_cppcheckxml.py ]; then
  mkdir -p tools
  cp $WORKSPACE/scripts/jenkins-scripts/tools/cpplint_to_cppcheckxml.py tools/
fi
init_stopwatch CPPCHECK
sh tools/code_check.sh -xmldir $WORKSPACE/build/cppcheck_results || true
stop_stopwatch CPPCHECK
echo '# END SECTION'

echo "at the end"
DELIM
