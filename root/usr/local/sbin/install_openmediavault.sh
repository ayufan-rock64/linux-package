#!/bin/bash

PYTHON_PATCH=
NETATALK=
MKCONF_CMD="/usr/sbin/omv-mkconf"

case "$(lsb_release -c -s)" in
	jessie)
		RELEASE="erasmus"
		EXTRAS_URL="https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/openmediavault-omvextrasorg_latest_all3.deb"
		NETATALK=1
		;;

	stretch)
		RELEASE="arrakis"
		EXTRAS_URL="https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/openmediavault-omvextrasorg_latest_all4.deb"
		NETATALK=1
		PYTHON_PATCH=1
		;;

	buster)
		RELEASE="usul"
		EXTRAS_URL="https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/openmediavault-omvextrasorg_latest_all5.deb"
		MKCONF_CMD="/usr/sbin/omv-salt deploy run"
		;;

	*)
		echo "This script only works on Debian/Jessie|Stretch|Buster"
		exit 1
esac

echo "OpenMediaVault installation script"
echo "Script is based on Armbian, OMV and tkaiser work: https://github.com/armbian/build/blob/master/config/templates/customize-image.sh.template"
echo ""
echo "This script overwrites network interfaces."
echo "Make sure that you configured them in OpenMediaVault interface before rebooting."
echo ""

if [[ -t 0 ]]; then
	echo "In order to continue type YES or cancel:"
	while read PROMPT; do
		if [[ "$PROMPT" == "YES" ]]; then
			break
		fi
	done
fi

set -xe

#Add OMV source.list and Update System
cat > /etc/apt/sources.list.d/openmediavault.list <<- EOF
# deb http://packages.openmediavault.org/public $RELEASE main
deb https://openmediavault.github.io/packages/ $RELEASE main
## Uncomment the following line to add software from the proposed repository.
# deb http://packages.openmediavault.org/public $RELEASE-proposed main
deb https://openmediavault.github.io/packages/ $RELEASE-proposed main

## This software is not part of OpenMediaVault, but is offered by third-party
## developers as a service to OpenMediaVault users.
# deb http://packages.openmediavault.org/public $RELEASE partner
EOF

# Add OMV and OMV Plugin developer keys
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 24863F0C716B980B
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7E7A6C592EF35D13
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7AA630A1EDEE7D73
apt-get update -y

# install debconf-utils, postfix and OMV
debconf-set-selections <<< "postfix postfix/mailname string openmediavault"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No configuration'"
apt-get -y install debconf-utils postfix

# install openmediavault
apt-get --yes install openmediavault openmediavault-keyring

# install OMV extras, enable folder2ram, tweak some settings
FILE=$(mktemp)
wget "$EXTRAS_URL" -qO $FILE
dpkg -i $FILE
/usr/sbin/omv-update

# FIX TFTPD ipv4
[ -f /etc/default/tftpd-hpa ] && sed -i 's/--secure/--secure --ipv4/' /etc/default/tftpd-hpa

# load OMV helpers
. /usr/share/openmediavault/scripts/helper-functions

# use folder2ram
apt-get -y install openmediavault-flashmemory
xmlstarlet ed -L -u "/config/services/flashmemory/enable" -v "1" ${OMV_CONFIG_FILE}

# enable ssh, but disallow root login
xmlstarlet ed -L -u "/config/services/ssh/enable" -v "1" ${OMV_CONFIG_FILE}
xmlstarlet ed -L -u "/config/services/ssh/permitrootlogin" -v "0" ${OMV_CONFIG_FILE}

# enable ntp
xmlstarlet ed -L -u "/config/system/time/ntp/enable" -v "1" ${OMV_CONFIG_FILE}

if [[ -n "$NETATALK" ]]; then
	# improve netatalk performance
	apt-get -y install openmediavault-netatalk
	AFP_Options="mimic model = Macmini"
	xmlstarlet ed -L -u "/config/services/afp/extraoptions" -v "$(echo -e "${AFP_Options}")" ${OMV_CONFIG_FILE}
fi

# improve samba performance
SMB_Options="min receivefile size = 16384\nwrite cache size = 524288\ngetwd cache = yes\nsocket options = TCP_NODELAY IPTOS_LOWDELAY"
xmlstarlet ed -L -u "/config/services/smb/extraoptions" -v "$(echo -e "${SMB_Options}")" ${OMV_CONFIG_FILE}

# fix timezone
xmlstarlet ed -L -u "/config/system/time/timezone" -v "UTC" ${OMV_CONFIG_FILE}

# fix hostname
xmlstarlet ed -L -u "/config/system/network/dns/hostname" -v "$(cat /etc/hostname)" ${OMV_CONFIG_FILE}

# disable monitoring
xmlstarlet ed -L -u "/config/system/monitoring/perfstats/enable" -v "0" ${OMV_CONFIG_FILE}

# disable journal for rrdcached
sed -i 's|-j /var/lib/rrdcached/journal/ ||' /etc/init.d/rrdcached

# add eth0 interface
xmlstarlet ed -L \
	-s /config/system/network/interfaces -t elem -n interface \
	-s /config/system/network/interfaces/interface -t elem -n uuid -v 4fa8fd59-e5be-40f6-a76d-be6a73ed1407 \
	-s /config/system/network/interfaces/interface -t elem -n type -v ethernet \
	-s /config/system/network/interfaces/interface -t elem -n devicename -v eth0 \
	-s /config/system/network/interfaces/interface -t elem -n method -v dhcp \
	-s /config/system/network/interfaces/interface -t elem -n method6 -v manual \
	/etc/openmediavault/config.xml

# configure cpufreq
cat <<EOF >>/etc/default/openmediavault
OMV_CPUFREQUTILS_GOVERNOR=ondemand
OMV_CPUFREQUTILS_MINSPEED=0
OMV_CPUFREQUTILS_MAXSPEED=0
EOF

cat <<EOF >>/etc/rsyslog.d/omv-armbian.conf
:msg, contains, "do ionice -c1" ~
:msg, contains, "action " ~
:msg, contains, "netsnmp_assert" ~
:msg, contains, "Failed to initiate sched scan" ~
EOF

# ensure that dmidecode is removed
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=923988:
apt-get purge -y dmidecode

# update configs
$MKCONF_CMD monit
$MKCONF_CMD netatalk || true
$MKCONF_CMD samba
$MKCONF_CMD hostname || true
$MKCONF_CMD timezone || true
$MKCONF_CMD collectd
$MKCONF_CMD flashmemory
$MKCONF_CMD ssh
$MKCONF_CMD ntp || true
$MKCONF_CMD cpufrequtils || true
$MKCONF_CMD interfaces || true
$MKCONF_CMD systemd-networkd || true

# make sure that rrdcached/php does exist
mkdir -p /var/lib/rrdcached /var/lib/php

# init OMV
# /usr/sbin/omv-initsystem

if [[ -n "$PYTHON_PATCH" ]]; then
	# hotfix python 3.5
	# taken from: https://github.com/ayufan-rock64/linux-build/issues/136#issuecomment-477483779
	cat <<EOF | patch -d /usr/lib/python3.5 -p1 || true
--- a/weakref.py  2018-09-28 00:02:01.000000000 +0800
+++ b/weakref.py  2019-03-28 15:35:03.677097971 +0800
@@ -106,7 +106,7 @@
         self, *args = args
         if len(args) > 1:
             raise TypeError('expected at most 1 arguments, got %d' % len(args))
-        def remove(wr, selfref=ref(self)):
+        def remove(wr, selfref=ref(self), _atomic_removal=_remove_dead_weakref):
             self = selfref()
             if self is not None:
                 if self._iterating:
@@ -114,7 +114,7 @@
                 else:
                     # Atomic removal is necessary since this function
                     # can be called asynchronously by the GC
-                    _remove_dead_weakref(d, wr.key)
+                    _atomic_removal(d, wr.key)
         self._remove = remove
         # A list of keys to be removed
         self._pending_removals = []
EOF
fi
