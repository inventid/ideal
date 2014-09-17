#!/bin/bash

# This improves performance since the Google DNS is much quicker than the local Vagrant Virtualbox combination
printf "nameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf

echo "Updating the Operating System..."
sudo apt-get update >> /tmp/provision.log 2>&1
sudo apt-get upgrade -y >> /tmp/provision.log 2>&1

echo "Installing extra packages..."
sudo apt-get install curl wget git g++ libreadline6-dev zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 autoconf libgdbm-dev libncurses5-dev automake libtool bison pkg-config libffi-dev -y >> /tmp/provision.log 2>&1

echo "Installing rvm..."
curl -sSL https://get.rvm.io | bash -s stable --ruby >> /tmp/provision.log 2>&1
source /usr/local/rvm/scripts/rvm

echo "Installing Ruby-2.1.2..."
rvm install ruby-2.1.2 >> /tmp/provision.log 2>&1
rvm use ruby-2.1.2 --default >> /tmp/provision.log 2>&1

cd /vagrant && bundle install >> /tmp/provision.log 2>&1

echo ""
echo "And we are done! Check /tmp/provision.log for a full log file \`vagrant ssh -c \"cat /tmp/provision.log\"\`"
