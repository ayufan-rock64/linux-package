#!/bin/bash

set -eo pipefail

if [[ "$(id -u)" -ne "0" ]]; then
	echo "This script requires root."
	exit 1
fi

case "$1" in
  minimal)
    # no-op
    ;;

  mate|i3|lxde|xfce4|kde|gnome)
    /usr/local/sbin/install_desktop.sh "$1"
    systemctl set-default graphical.target
    ;;

  openmediavault)
    /usr/local/sbin/install_openmediavault.sh
    ;;

  containers)
    /usr/local/sbin/install_container_linux.sh
    ;;

  *)
    echo "Unknown variant: $1"
    exit 1
    ;;
esac
