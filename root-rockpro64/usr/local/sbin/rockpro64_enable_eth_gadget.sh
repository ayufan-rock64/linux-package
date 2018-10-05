#!/bin/bash

set -xe

# enable peripheral mode
enable_dtoverlay usb0_dwc3_peripheral usb0/dwc3@fe800000 okay \
  'dr_mode="peripheral"'

# reload dwc3
echo fe800000.dwc3 > /sys/bus/platform/drivers/dwc3/unbind
echo fe800000.dwc3 > /sys/bus/platform/drivers/dwc3/bind

# install eth gadget
install_gadget RockPro64 fe800000.dwc3 ecm
