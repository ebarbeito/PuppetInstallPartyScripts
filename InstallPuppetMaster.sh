#!/bin/bash

# Script to install the puppetmaster on a DigitalOcean Droplet
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
PACKAGES="puppetserver htop tmux vim iotop chkconfig"
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

echo "=== Installing and configuring the Puppet master ==="
ssh -p$PORT -o StrictHostKeyChecking=no -T root@$HOSTNAME << EOF
wget ${REPO_DEB_URL} >/dev/null && \
dpkg -i ${PUPPET_RELEASE} && \
rm -f ${PUPPET_RELEASE} && \
apt-get update && \
apt-get dist-upgrade -y && \
apt-get install -y ${PACKAGES} && \
echo '  environmentpath = \$confdir/environments' >> /etc/puppet/puppet.conf && \
echo -e "[agent]\n  server = ${PUPPETMASTER_HOSTNAME}" >> /etc/puppet/puppet.conf 
EOF
if [ $? != 0 ]; then
	echo "----> An error ocurred. The script will halt. The script couldn't install the Puppet master"
        exit 1
fi

echo "=== Installing and configuring R10k ==="
ssh -p$PORT -o StrictHostKeyChecking=no -T root@$HOSTNAME << EOF
gem install r10k  && \
echo '# The location to use for storing cached Git repos' >> /etc/r10k.yaml && \
echo ":cachedir: '/var/cache/r10k'" >> /etc/r10k.yaml && \
echo "# A list of git repositories to create" >> /etc/r10k.yaml && \
echo ":sources:" >> /etc/r10k.yaml && \
echo "# This will clone the git repository and instantiate an environment per" >> /etc/r10k.yaml && \
echo "# branch in /etc/puppet/environments" >> /etc/r10k.yaml && \
echo "  :my-org:" >> /etc/r10k.yaml && \
echo "    remote: '${GIT_REPO_PATH}'" >> /etc/r10k.yaml && \
echo "    basedir: '/etc/puppet/environments'" >> /etc/r10k.yaml && \
chmod 750 /etc/r10k.yaml
EOF
if [ $? != 0 ]; then
	echo "----> An error ocurred. The script will halt. The script couldn't install the r10k tool"
        exit 1
fi

echo "=== Configuring Hiera ==="
ssh -p$PORT -o StrictHostKeyChecking=no -T root@$HOSTNAME << EOF
echo "---" > /etc/hiera.yaml && \
echo ":backends:" >> /etc/hiera.yaml && \
echo "  - yaml" >> /etc/hiera.yaml && \
echo ":hierarchy:" >> /etc/hiera.yaml && \
echo "  - common" >> /etc/hiera.yaml && \
echo "  - \"nodes/%{::fqdn}\"" >> /etc/hiera.yaml && \
echo "  - default" >> /etc/hiera.yaml && \
echo "" >> /etc/hiera.yaml && \
echo ":yaml:" >> /etc/hiera.yaml && \
echo "  :datadir: \"/etc/puppet/environments/%{::environment}/hiera\"" >> /etc/hiera.yaml && \
echo "merge_behavior: deeper" >> /etc/hiera.yaml && \
chmod 744 /etc/hiera.yaml && \
ln -s /etc/hiera.yaml /etc/puppet/hiera.yaml
EOF
if [ $? != 0 ]; then
	echo "----> An error ocurred. The script will halt. The script couldn't configure Hiera"
        exit 1
fi

echo "=== Populating the first production environment from git repo ==="
ssh -p$PORT -o StrictHostKeyChecking=no -T root@$HOSTNAME << EOF
r10k deploy environment -p && \
chown -R puppet:puppet /etc/puppet/environments/production && \
rm -rf /var/lib/puppet/ssl && \
service puppetserver start && \
chkconfig puppetserver on 
EOF
if [ $? != 0 ]; then
	echo "----> An error ocurred. The script will halt. The script couldn't populate the production environment"
        exit 1
fi

echo "=== Configuring the Puppet client to run as a daemon ==="
ssh -p$PORT -o StrictHostKeyChecking=no -T root@$HOSTNAME << EOF
sed -i 's/START=no/START=yes/' /etc/default/puppet && \
chkconfig puppet on
EOF
if [ $? != 0 ]; then
        echo "----> An error ocurred. The script will halt. The script configure the Puppet client to run as a daemon"
        exit 1
fi
