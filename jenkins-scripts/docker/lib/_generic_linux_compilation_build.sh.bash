# Parameters
#  - WORKSPACE
#  - TIMING_DIR
#  - SOFTWARE_DIR: directory relative path to find sources
#  - GENERIC_ENABLE_TIMING (optional) [default true]
#  - GENERIC_ENABLE_CPPCHECK (optional) [default true] run cppcheck
#  - GENERIC_ENABLE_TESTS (optional) [default true] run tests
#  - BUILDING_EXTRA_CMAKE_PARAMS (optional) extra cmake params

if [[ -z ${SOFTWARE_DIR} ]]; then
    echo "SOFTWARE_DIR variable is unset. Please fix the code"
    exit 1
fi

[[ -z $GENERIC_ENABLE_TIMING ]] && GENERIC_ENABLE_TIMING=true
[[ -z $GENERIC_ENABLE_CPPCHECK ]] && GENERIC_ENABLE_CPPCHECK=true
[[ -z $GENERIC_ENABLE_TESTS ]] && GENERIC_ENABLE_TESTS=true

cat > build.sh << DELIM
#!/bin/bash
set -ex
if $GENERIC_ENABLE_TIMING; then
  source ${TIMING_DIR}/_time_lib.sh ${WORKSPACE}
fi

echo '# BEGIN SECTION: configure'
# Step 2: configure and build
cd $WORKSPACE
[[ ! -d $WORKSPACE/build ]] && mkdir -p $WORKSPACE/build
cd $WORKSPACE/build
if $GENERIC_ENABLE_TESTS; then
  cmake $WORKSPACE/${SOFTWARE_DIR} ${BUILDING_EXTRA_CMAKE_PARAMS} \
      -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_TESTS_COMPILATION=false
else
  cmake $WORKSPACE/${SOFTWARE_DIR} ${BUILDING_EXTRA_CMAKE_PARAMS} \
      -DCMAKE_INSTALL_PREFIX=/usr
fi
echo '# END SECTION'

echo '# BEGIN SECTION: compiling'
init_stopwatch COMPILATION
make -j${MAKE_JOBS}
echo '# END SECTION'

echo '# BEGIN SECTION: installing'
make install
stop_stopwatch COMPILATION
echo '# END SECTION'

if $GENERIC_ENABLE_TESTS; then
  echo '# BEGIN SECTION: running tests'
  init_stopwatch TEST
  mkdir -p \$HOME
  make test ARGS="-VV" || true
  stop_stopwatch TEST
  echo '# END SECTION'
else
  echo "Requested: no test run"
fi

if $GENERIC_ENABLE_CPPCHECK; then
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
else
  echo "Requested: no ccpcheck run"
fi
DELIM
