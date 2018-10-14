#!/bin/bash
set -ex

if [[ $MYSQL_VERSION =~ (mysql-5\.[67]) ]]; then
  sudo service mysql stop
  sudo apt-get install python-software-properties
  cat <<EOC | sudo debconf-set-selections
mysql-apt-config mysql-apt-config/select-server select $MYSQL_VERSION
mysql-apt-config mysql-apt-config/repo-distro   select  ubuntu
EOC
  wget https://dev.mysql.com/get/mysql-apt-config_0.8.4-1_all.deb
  sudo dpkg --install mysql-apt-config_0.8.4-1_all.deb
  sudo apt-get update -q
  sudo apt-get install -q -y -o Dpkg::Options::=--force-confnew mysql-server
  sudo mysql_upgrade
fi
