#!/bin/bash

if [[ "$(id -u)" -ne "0" ]]; then
	echo "This script requires root."
	exit 1
fi

dev=$(findmnt / -n -o SOURCE)

case $dev in
	/dev/mmcblk*)
		DISK=${dev:0:12}
		NAME="sd/emmc"
		;;

	/dev/sd*)
		DISK=${dev:0:8}
		NAME="hdd/ssd"
		;;

	*)
		echo "Unknown disk for $dev"
		exit 1
		;;
esac

echo "Resizing $DISK ($NAME -- $dev)..."

set -xe

# move GPT alternate header to end of disk
sgdisk -e "$DISK"

# resize partition 7 to as much as possible
echo ",+,,," | sfdisk "${DISK}" -N4 --force

# re-read partition table
partprobe "$DISK"

# online resize filesystem
resize2fs "$dev"
