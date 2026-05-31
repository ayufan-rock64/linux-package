#!/bin/bash

set -x

# enable peripheral mode
disable_dtoverlay dwc3_peripheral

# reload dwc3
echo ff600000.dwc3 > /sys/bus/platform/drivers/dwc3/unbind
echo ff600000.dwc3 > /sys/bus/platform/drivers/dwc3/bind

# install eth gadget
uninstall_gadgets
