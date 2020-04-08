#!/bin/bash

if [[ "$(id -u)" -ne "0" ]]; then
	echo "This script requires root."
	exit 1
fi

dev=$(findmnt / -n -o SOURCE)

case $dev in
	/dev/mmcblk?p?)
		DISK=${dev:0:12}
		PART=${dev:13}
		NAME="sd/emmc"
		;;

	/dev/sd??)
		DISK=${dev:0:8}
		PART=${dev:8}
		NAME="hdd/ssd"
		;;

	/dev/nvme?n?p?)
		DISK=${dev:0:12}
		PART=${dev:13}
		NAME="pcie/nvme"
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

# resize partition 4 to as much as possible
echo ",+,,," | sfdisk "${DISK}" "-N$PART" --force

# re-read partition table
partprobe "$DISK"

# online resize filesystem
resize2fs "$dev"
