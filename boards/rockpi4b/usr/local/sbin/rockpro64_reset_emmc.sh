#!/bin/bash

if [[ "$1" != "--force" ]]; then
    MNT_DEV=$(findmnt / -n -o SOURCE)
    if [[ "$MNT_DEV" == /dev/mmcblk1* ]]; then
        echo "Cannot reset when running from eMMC, use: $0 --force."
        exit 1
    fi
fi

if [[ -d /sys/bus/platform/drivers/sdhci-arasan/fe330000.sdhci ]]; then
    echo "Unbinding..."
    echo fe330000.sdhci > /sys/bus/platform/drivers/sdhci-arasan/unbind
fi

echo "Binding..."
echo fe330000.sdhci > /sys/bus/platform/drivers/sdhci-arasan/bind

echo "Finished"
