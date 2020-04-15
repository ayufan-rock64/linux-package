#!/bin/bash

set -e

DESKTOP="$1"

if [ -z "$DESKTOP" ]; then
	echo "Usage: $0 <mate|i3|gnome|xfce4|lxde|kde>"
	exit 1
fi

DISTRO=""
if hash apt-get 2>/dev/null; then
	DISTRO=$(lsb_release -i -s)
fi

if [ -z "$DISTRO" ]; then
	echo "This script requires a Debian based Linux distribution."
	exit 1
fi

if [ "$(id -u)" -ne "0" ]; then
	echo "This script requires root."
	exit 1
fi

# Default packages.
PACKAGES=(
	mplayer
	smplayer
	smplayer-themes
	smtube
	xserver-xorg
	mesa-utils-extra
)

# Video/3d acceleration packages
PACKAGES+=(
#	xserver-xorg-video-armsoc
#	libdrm-rockchip1
	libgl1
	libgl4es1
	libglvnd-dev
	ffmpeg
	mpv
)

# Additional packages
PACKAGES+=(
	xserver-xorg-input-all
	xfonts-base
	suckless-tools
	network-manager
	pulseaudio
	bluez
	ibus
	xinit # for startx
)

case $DISTRO in
	Ubuntu)
		PACKAGES+=(
			# TODO: for now it fails with `snap` access
			# chromium-browser
			firefox
		)
		;;

	Debian)
		PACKAGES+=(
			chromium
			chromium-widevine
		)
		;;

	*)
		echo "Error: unsupported desktop environment $DESKTOP-$DISTRO"
		exit 2
		;;
esac

# Add packages based on desktop selection.
case $DESKTOP-$DISTRO in
	mate-Ubuntu)
		PACKAGES+=(
			ubuntu-mate-desktop
			ubuntu-mate-wallpapers
			ubuntu-mate-artwork
			mate-applet-brisk-menu
			mate-applet-appmenu
			mate-desktop-environment
			mate-desktop-environment-extra
			mate-desktop-environment-extras
			mate-dock-applet
			mate-menu
			mate-sensors-applet
			mate-tweak
			mate-user-share
			mate-system-monitor
			mate-user-guide
			mate-calc
			mate-accessibility-profiles
			mate-netbook
			mate-window-menu-applet
			mate-window-title-applet
			mate-hud
			network-manager
			network-manager-gnome
			network-manager-openvpn-gnome
			lightdm
			lightdm-gtk-greeter
			ubuntu-mate-lightdm-theme
			unity-greeter
			dconf-editor
		)
		;;

	mate-Debian)
		PACKAGES+=(
			mate-desktop-environment
			mate-desktop-environment-extra
			mate-desktop-environment-extras
			mate-hud
			mate-dock-applet
			mate-menu
			mate-sensors-applet
			mate-tweak
			mate-user-share
			mate-system-monitor
			mate-user-guide
			mate-calc
			mate-accessibility-profiles
			mate-netbook
			mate-window-menu-applet
			mate-window-title-applet
			desktop-base
			dconf-editor
			lightdm
			lightdm-gtk-greeter
		)
		;;

	gnome-Ubuntu)
		PACKAGES+=(
			ubuntu-gnome-desktop
			ubuntu-gnome-wallpapers-xenial
			gdm3
		)
		;;

	gnome-Debian)
		PACKAGES+=(
			gnome
			desktop-base
		)
		;;

	i3-Ubuntu|i3-Debian)
		PACKAGES+=(
			i3
			i3status
			i3lock
			slim
			rxvt-unicode-lite
		)
		;;

	xfce4-Ubuntu)
		PACKAGES+=(
			xubuntu-desktop
			lightdm
			lightdm-gtk-greeter
			ubuntu-mate-lightdm-theme
		)
		;;

	lxde-Ubuntu)
		PACKAGES+=(
			lxde
			lightdm
			lightdm-gtk-greeter
			ubuntu-mate-lightdm-theme
			slick-greeter
			network-manager
			network-manager-gnome
			network-manager-openvpn-gnome
		)
		;;

	lxde-Debian)
		PACKAGES+=(
			lxde
			lightdm
			lightdm-gtk-greeter
		)
		;;

	kde-Ubuntu)
		PACKAGES+=(
			kubuntu-desktop
			lightdm
			lightdm-gtk-greeter
		)
		;;

	*)
		echo "Error: unsupported desktop environment $DESKTOP"
		exit 2
		;;
esac

# Install.
apt -y update
apt -y install ${PACKAGES[@]}

# Kill parport module loading, not available on arm64.
if [ -e "/etc/modules-load.d/cups-filters.conf" ]; then
	echo "" >/etc/modules-load.d/cups-filters.conf
fi

# Disable Pulseaudio timer scheduling which does not work with sndhdmi driver.
if [ -e "/etc/pulse/default.pa" ]; then
	sed -i 's/load-module module-udev-detect$/& tsched=0/g' /etc/pulse/default.pa
fi

# Desktop dependent post installation.
case $DESKTOP in
	i3|i3wm)
		if [ ! -d /usr/share/slim/themes/rock64 ]; then
			cp -ra /usr/share/slim/themes/default /usr/share/slim/themes/rock64
			ln -sf /usr/share/backgrounds/ubuntu-mate-rock64/ROCK64-Wallpaper-6.jpg /usr/share/slim/themes/rock64/background.png
			sed -i "s/^current_theme(.*)/current_theme rock64/g" /etc/slim.conf
		fi
		;;

	mate|lxde)
		# uninstall screensaver as this results in double lock screen on resume
		apt-get purge -y gnome-screensaver
		;;

	*)
		;;
esac

# TODO: it seems to be bad idea due to missing `libgl1` support
# # Disable `swrast` as it kills compositing performance when using glamor
# # This happen due to back/and/forth copy of buffers between mali and mesa
# dpkg-divert --rename --add /usr/lib/arm-linux-gnueabihf/dri/kms_swrast_dri.so
# dpkg-divert --rename --add /usr/lib/arm-linux-gnueabihf/dri/swrast_dri.so

# Fix Ubuntu bug throwing the `Failed to execute program org.blueman.Mechanism`
# https://bugs.launchpad.net/ubuntu/+source/blueman/+bug/1542723
if [[ -e /usr/lib/dbus-1.0/dbus-daemon-launch-helper ]]; then
	chown root:messagebus /usr/lib/dbus-1.0/dbus-daemon-launch-helper
	chmod u+s /usr/lib/dbus-1.0/dbus-daemon-launch-helper
fi

if [[ ! -f /etc/pulse/default.pa ]]; then
	echo "PulseAudio is missing and cannot be configured."
	exit 1
fi

cat <<EOF >> /etc/pulse/default.pa
# Set HDMI (if available)
set-default-sink alsa_output.platform-hdmi-sound.stereo-fallback

# Set speakers (if available)
set-default-sink alsa_output.platform-speaker-sound.stereo-fallback
EOF

echo
echo "Done - $DESKTOP installed - you should reboot now."
