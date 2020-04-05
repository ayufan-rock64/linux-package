#!/bin/bash

TIMEOUT=""
DEFAULT=""
APPEND="rw"
APPEND="$APPEND panic=10"
APPEND="$APPEND init=/sbin/init"
APPEND="$APPEND coherent_pool=1M"
APPEND="$APPEND ethaddr=\${ethaddr} eth1addr=\${eth1addr} serial=\${serial#}"
APPEND="$APPEND cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory swapaccount=1"

set -eo pipefail

. /etc/default/extlinux

echo "Creating new extlinux.conf..." 1>&2

mkdir -p /boot/extlinux/
exec 1> /boot/extlinux/extlinux.conf.new

echo "timeout ${TIMEOUT:-10}"
echo "menu title select kernel"
[[ -n "$DEFAULT" ]] && echo "default $DEFAULT"
echo ""

emit_kernel() {
  local VERSION="$1"
  local APPEND="$2"
  local NAME="$3"

  echo "label kernel-$VERSION$NAME"
  echo "    kernel $MOUNT_PREFIX/vmlinuz-$VERSION"
  if [[ -f "/boot/initrd.img-$VERSION" ]]; then
    echo "    initrd $MOUNT_PREFIX/initrd.img-$VERSION"
  fi
  if [[ -f "/boot/dtb-$VERSION" ]]; then
    echo "    fdt $MOUNT_PREFIX/dtb-$VERSION"
  else
    if [[ ! -d "/boot/dtbs/$VERSION" ]]; then
      mkdir -p /boot/dtbs
      cp -au "/usr/lib/linux-image-$VERSION" "/boot/dtbs/$VERSION"
    fi
    echo "    devicetreedir $MOUNT_PREFIX/dtbs/$VERSION"
  fi
  echo "    append $APPEND"
  echo ""
}

if findmnt /boot >/dev/null; then
  # If we have `/boot` the files are in `/`
  MOUNT_PREFIX=
else
  # If we don't have `/boot` mount the files are in `/boot`
  MOUNT_PREFIX=/boot
fi

linux-version list | linux-version sort --reverse | while read VERSION; do
  emit_kernel "$VERSION" "$APPEND"
  emit_kernel "$VERSION" "$APPEND memtest" "-memtest"
done

exec 1<&-

echo "Installing new extlinux.conf..." 1>&2
mv /boot/extlinux/extlinux.conf.new /boot/extlinux/extlinux.conf
