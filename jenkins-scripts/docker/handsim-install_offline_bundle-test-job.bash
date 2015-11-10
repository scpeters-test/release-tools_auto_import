#!/bin/bash -x

# Knowing Script dir beware of symlink
[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

export GPU_SUPPORT_NEEDED=true

export INSTALL_JOB_PKG=""
export INSTALL_JOB_REPOS=""

# To simulate an offline update first install handsim, after it 
# run the unbundler
INSTALL_JOB_POSTINSTALL_HOOK="""
cd /tmp
HANDSIM_LATEST_ZIPS=\$(curl http://packages.osrfoundation.org/haptix/ | sed 's:.*\\(handsim.*.zip\\).*:\1:p' | grep -v latest | grep ^handsim-debs | uniq | sort | tail -n 2)


for zip in \${HANDSIM_LATEST_ZIPS}; do
  echo \"# BEGIN SECTION: installing the version: \${zip}\"
  wget http://packages.osrfoundation.org/haptix/\${zip}
  echo '# END SECTION'
  
  echo '# BEGIN SECTION: run the unbundler'
  unzip \${zip}
  cd handsim-*
  
  # Bundlers released previously did not include the apt-get install command
  if [[ zip = 'handsim-debs-2015-04-09-00-54-45.zip' ]]; then
    bash -x ./handsim-unbundler.bash || true
    sudo apt-get install -f -y -q
  else
    bash -x ./handsim-unbundler.bash
  fi
  echo '# END SECTION'
done

echo '# BEGIN SECTION: test the script'
TEST_START=\`date +%s\`
timeout --preserve-status 180 gazebo --verbose arat.world || true
TEST_END=\`date +%s\`
DIFF=\`echo \"\$TEST_END - \$TEST_START\" | bc\`

if [ \$DIFF -lt 180 ]; then
   echo 'The test took less than 180s. Something bad happened'
   exit 1
fi
echo '# END SECTION'
"""

# Need bc to proper testing and parsing the time
export DEPENDENCY_PKGS="wget curl unzip"

. ${SCRIPT_DIR}/lib/generic-install-base.bash
