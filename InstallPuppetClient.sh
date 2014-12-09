#!/bin/bash

# Script to install the puppet client on a DigitalOcean Droplet
# Based on:
# https://github.com/adrienthebo/r10k/blob/master/doc/dynamic-environments/quickstart.mkd
# http://terrarum.net/blog/puppet-infrastructure.html 
# http://stdout.no/a-modern-puppet-master-from-scratch/
# 

#uncomment for debug 
#set -x

# Loading params from params file
source ./params.txt

# Defining some variables
HOSTNAME=$1
PACKAGES="puppet htop tmux vim iotop chkconfig"
# Load up the release information
PUPPET_RELEASE="puppetlabs-release-wheezy.deb"
REPO_DEB_URL="http://apt.puppetlabs.com/${PUPPET_RELEASE}"
if [ -z "$2" ]
then
	PORT="22"
else
	PORT="$2"
fi

# Starting the Process #

echo "=== Installing and configuring the Puppet client ==="
ssh -p$PORT -o StrictHostKeyChecking=no -T root@$HOSTNAME << EOF
wget ${REPO_DEB_URL} >/dev/null && \
dpkg -i ${PUPPET_RELEASE} && \
rm -f ${PUPPET_RELEASE} && \
apt-get update && \
apt-get dist-upgrade -y && \
apt-get install -y ${PACKAGES} && \
echo -e "[agent]\n  server = ${PUPPETMASTER_HOSTNAME}" >> /etc/puppet/puppet.conf && \
puppet agent -t || echo "Requesting SSL certificate"
EOF
if [ $? != 0 ]; then
	echo "----> An error ocurred. The script will halt. The script couldn't install the Puppet client"
        exit 1
fi

echo "=== Signing SSL certificate on the Puppet Master  ==="
ssh -p$PORT -o StrictHostKeyChecking=no -T root@${PUPPETMASTER_HOSTNAME} << EOF
puppet cert list |grep ${HOSTNAME} && puppet cert --sign ${HOSTNAME}
EOF
if [ $? != 0 ]; then
	echo "----> An error ocurred. The script will halt. The script couldn't sign the SSL certificate on the puppetmaster"
        exit 1
fi

echo "=== Configuring the Puppet client to run as a daemon ==="
ssh -p$PORT -o StrictHostKeyChecking=no -T root@$HOSTNAME << EOF
sed -i 's/START=no/START=yes/' /etc/default/puppet && \
chkconfig puppet on
service puppet start
EOF
if [ $? != 0 ]; then
	echo "----> An error ocurred. The script will halt. The script configure the Puppet client to run as a daemon"
        exit 1
fi
