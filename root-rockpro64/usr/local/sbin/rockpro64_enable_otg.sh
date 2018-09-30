#!/bin/bash

set -xe

mkdir -p /sys/kernel/config/usb_gadget/g1

UDC=${1:-fe800000.dwc3}

# create new gadget node
cd /sys/kernel/config/usb_gadget/g1
echo 0x2207 > idVendor
echo 0x2d00 > idProduct

# configure device serials
mkdir -p strings/0x409
echo myserial > strings/0x409/serialnumber
echo "Pine Inc." > strings/0x409/manufacturer
echo "RockPro64" > strings/0x409/product

# create a config
mkdir -p configs/c.1
echo 120 > configs/c.1/MaxPower

# ensure function is loaded
modprobe usb_f_ecm

# create the function (name must match a usb_f_<name> module such as 'ecm')
mkdir -p functions/ecm.0
rm -f configs/c.1/ecm.0

# associate function with config
ln -sf functions/ecm.0 configs/c.1

# enable gadget by binding it to a UDC from /sys/class/udc
echo "$UDC" > UDC
