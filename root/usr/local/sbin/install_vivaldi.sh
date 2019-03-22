#!/bin/bash

set -e

if [[ "$(id -u)" != "0" ]]; then
	echo "This script requires to be run as root."
	exit 1
fi

if [[ "$(dpkg-architecture -qDEB_HOST_ARCH)" != "armhf" ]]; then
  echo "Vivaldi is only supported on armhf"
  echo "You are using: $(dpkg-architecture -qDEB_HOST_ARCH)"
  exit 1
fi

set -x

curl https://repo.vivaldi.com/archive/linux_signing_key.pub | apt-key add -

echo "deb [arch=armhf,i386,amd64] http://repo.vivaldi.com/stable/deb/ stable main" > /etc/apt/sources.list.d/repo-vivaldi-com.list

apt-get update -y
apt-get install -y vivaldi-stable

echo Done.
