#!/bin/bash

set -xe

# enable peripheral mode
enable_dtoverlay dwc3_peripheral usb@ff600000/dwc3@ff600000 okay \
  'dr_mode="peripheral"'

# reload dwc3
echo ff600000.dwc3 > /sys/bus/platform/drivers/dwc3/unbind
echo ff600000.dwc3 > /sys/bus/platform/drivers/dwc3/bind

# install eth gadget
install_gadget Rock64 ff600000.dwc3 ecm
