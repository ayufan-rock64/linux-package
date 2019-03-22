#!/bin/bash

# Taken from https://gist.github.com/ruario/3c873d43eb20553d5014bd4d29fe37f1

set -e

if [[ "$(id -u)" != "0" ]]; then
	echo "This script requires to be run as root."
	exit 1
fi

if [[ "$(dpkg-architecture -qDEB_HOST_ARCH)" != "armhf" ]]; then
  echo "Widevine DRM is only supported on armhf"
  echo "You are using: $(dpkg-architecture -qDEB_HOST_ARCH)"
  exit 1
fi

if ! which kpartx &>/dev/null; then
  echo "Missing kpartx. Installing..."
  apt-get update -y
  apt-get install -y kpartx
fi

# Ensure that symlink is installed
ln -fs /opt/google/chrome/libwidevinecdm.so /usr/lib/chromium-browser/libwidevinecdm.so

if [[ "$1" != "--force" ]] && [[ -e /opt/google/chrome/libwidevinecdm.so ]] && [[ -e /opt/google/chrome/PepperFlash/libpepflashplayer.so ]]; then
  echo "Widevine DRM is already installed"
  echo "Use '$0 --force' to overwrite."
  exit 1
fi

TEMP_DIR=$(mktemp -td ChromeOS-IMG.XXXXXX)
cleanup() {
  rm -rf "$TEMP_DIR"
}
trap 'cleanup' EXIT

cd "$TEMP_DIR/"

echo "Downloading a list of recovery images..."
curl -L https://dl.google.com/dl/edgedl/chromeos/recovery/recovery.conf > recovery.conf

echo "Looking for recovery image for CB5-312T..."
if ! CHROMEOS_URL="$(grep -A11 CB5-312T < recovery.conf | sed -n 's/^url=//p')"; then
  echo "Failed to find recovery image for CB5-312T."
  exit 1
fi

echo "Downloading recovery image..."
curl "$CHROMEOS_URL" | zcat > chromeos.img

echo "Reading recovery image..."
kpartx -a chromeos.img
cleanup() {
  kpartx -d chromeos.img
  rm -rf "$TEMP_DIR"
}

echo "Looking for system partition..."

if ! LOOP_DEV=$(kpartx -l chromeos.img | grep "^loop[0-9]*p3 :" | awk '{print $1}'); then
  echo "Failed to find loop*p3 partition of recovery image."
  exit 1
fi

echo "Mounting recovery image..."
mkdir -p rootfs/
mount -o ro "/dev/mapper/${LOOP_DEV}" rootfs/

cleanup() {
  umount rootfs/
  kpartx -d chromeos.img
  rm -rf "$TEMP_DIR"
}

echo "Copying Widevine DRM..."
mkdir -p /opt/google/chrome/PepperFlash/
cp -av rootfs/opt/google/chrome/libwidevinecdm.so /opt/google/chrome/
cp -av rootfs/opt/google/chrome/pepper/libpepflashplayer.so /opt/google/chrome/PepperFlash/

echo "Done."
