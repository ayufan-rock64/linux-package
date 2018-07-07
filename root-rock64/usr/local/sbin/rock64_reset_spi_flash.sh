#!/bin/bash

if [[ -d /sys/bus/platform/drivers/rockchip-spi/ff190000.spi ]]; then
    echo "Unbinding..."
    echo ff190000.spi > /sys/bus/platform/drivers/rockchip-spi/unbind
fi

echo "Binding..."
echo ff190000.spi > /sys/bus/platform/drivers/rockchip-spi/bind

echo "Finished"
