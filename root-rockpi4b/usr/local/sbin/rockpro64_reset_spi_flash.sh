#!/bin/bash

if [[ -d /sys/bus/platform/drivers/rockchip-spi/ff1d0000.spi ]]; then
    echo "Unbinding..."
    echo ff1d0000.spi > /sys/bus/platform/drivers/rockchip-spi/unbind
fi

echo "Binding..."
echo ff1d0000.spi > /sys/bus/platform/drivers/rockchip-spi/bind

echo "Finished"
