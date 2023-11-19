#!/bin/bash

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <product-name> <udc> <functions...>"
  exit 1
fi

BOARD="$1"
UDC="$2"
shift 2

set -xe

mkdir -p /sys/kernel/config/usb_gadget/g1
cd /sys/kernel/config/usb_gadget/g1
echo 0x2207 > idVendor
echo 0x2d00 > idProduct

# configure device serials
mkdir -p strings/0x409
echo myserial > strings/0x409/serialnumber
echo "Pine Inc." > strings/0x409/manufacturer
echo "$BOARD" > strings/0x409/product

# create a config
mkdir -p configs/c.1
echo 120 > configs/c.1/MaxPower

# add all requested functions
for i
do
  # ensure function is loaded
  modprobe "usb_f_$i"

  # create the function (name must match a usb_f_<name> module such as 'ecm')
  mkdir -p "functions/$i.0"
  rm -f "configs/c.1/$i.0"

  # associate function with config
  ln -sf "functions/$i.0" "configs/c.1"
done

# enable gadget by binding it to a UDC from /sys/class/udc
echo "$UDC" > UDC
