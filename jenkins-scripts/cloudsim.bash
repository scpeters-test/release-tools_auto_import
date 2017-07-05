#!/bin/bash -x

[[ -L ${0} ]] && SCRIPT_DIR=$(readlink ${0}) || SCRIPT_DIR=${0}
SCRIPT_DIR="${SCRIPT_DIR%/*}"

. ${SCRIPT_DIR}/lib/boilerplate_prepare.sh

set +x # keep password secret
MAIL_PASS=`cat $HOME/mail_pass`
set -x # back to debug


cat > build.sh << DELIM
###################################################
# Make project-specific changes here
#
set -ex


##### From: http://old.gazebosim.org/wiki/Tutorials/CloudSim/setup  ###############

echo "installing packages for Cloudsim: http://old.gazebosim.org/wiki/Tutorials/CloudSim/setup"

apt-get install -y redis-server python-pip python-redis python-novaclient

# CloudSim is compatible with boto 2.8.0 and up, so you can't use the default 
# package in Ubuntu 12.04

pip install --upgrade boto
apt-get install -y expect
pip install softlayer

pip install unittest-xml-reporting

python -c"import boto; print('*** BOTO version: %s' % boto.Version)"
########################################################333####################

## necessary for jenkins machine
apt-get install -y python-dateutil
apt-get install -y openssh-client
apt-get install -y zip

## other
apt-get install -y cmake 
apt-get install -y python-software-properties

# run redis-server as it does not seem to start on its own
/etc/init.d/redis-server start

rm -rf $WORKSPACE/build $WORKSPACE/cloudsim/test-reports
mkdir -p $WORKSPACE/build
cd $WORKSPACE/build
cmake $WORKSPACE/cloudsim
PYTHONPATH=$WORKSPACE/cloudsim/inside/cgi-bin make test ARGS="-VV" || true
# Sanitize XML output files, to save Jenkins's parser from throwing an
# error.  This step could be moved into CloudSim itself.
$WORKSPACE/cloudsim/tools/sanitize_junitxml.py $WORKSPACE/cloudsim/test-reports/*.xml || true

DELIM

# Copy in my boto config file, to allow launching of AWS machines.
cp $HOME/boto.test-osrfoundation.org $WORKSPACE/boto.ini

# Make project-specific changes here
###################################################

sudo pbuilder  --execute \
    --bindmounts $WORKSPACE \
    --basetgz $basetgz \
    -- build.sh