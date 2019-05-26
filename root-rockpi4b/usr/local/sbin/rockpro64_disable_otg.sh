#!/bin/bash

set -x

# enable peripheral mode
disable_dtoverlay dwc3_peripheral

# reload dwc3
echo fe800000.dwc3 > /sys/bus/platform/drivers/dwc3/unbind
echo fe800000.dwc3 > /sys/bus/platform/drivers/dwc3/bind

# install eth gadget
uninstall_gadgets
