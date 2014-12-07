PuppetInstallPartyScripts
=========================

Two scripts to install the puppet master and the puppet clients on a Digital Ocean droplet. Used for the Puppet install Party http://www.meetup.com/Alicante-Puppet-Users-Group/events/213374572/

InstallPuppetMaster.sh
======================

Install and configures the Puppet Master on a Debian Server

./InstallPuppetMaster.sh puppetmaster.example.org

An screencast can be seen on the following link:
https://asciinema.org/a/14495

InstallPuppetClient.sh
======================
Install and configures the Puppet Client on a Debian Server

./InstallPuppetClient.sh puppetclient.example.org

An screencast can be seen on the following link:
https://asciinema.org/a/14496

params.txt
==========
Contains the default parameters to be used by both scripts

Those parameters are:
GIT_REPO_PATH='https://github.com/juasiepo/PuppetInstallPartyGitRepo.git' #Default value. Populate it with your Git repository path
PUPPETMASTER_HOSTNAME=''  # Populate it with your puppet master hostname
