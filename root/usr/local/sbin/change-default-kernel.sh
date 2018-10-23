#!/bin/bash

set -eo pipefail

. /etc/default/extlinux

VERSIONS=( $(linux-version list | linux-version sort --reverse) )

echo "Current kernel append parameters:"
echo "append=$APPEND"
echo ""

echo "Select kernel version:"

for version in "${!VERSIONS[@]}"
do
  echo -n "$version: "
  echo -n "${VERSIONS[$version]}"
  if [[ "${VERSIONS[$version]}" == "$1" ]]; then
    USER_CHOICE="$version"
    echo -n " - user selected"
  fi
  if [[ "kernel-${VERSIONS[$version]}" == "$DEFAULT" ]]; then
    echo " - current default"
  else
    echo
  fi
done

if [[ -z "$USER_CHOICE" ]]; then
  if [[ -n "$1" ]]; then
    echo "$1: invalid kernel version"
    exit 1
  fi
  read USER_CHOICE
fi

while [[ -z "${VERSIONS[$USER_CHOICE]}" ]]; do
  echo "Invalid version."
  read USER_CHOICE
done

echo
echo "Selected: kernel-${VERSIONS[$USER_CHOICE]}"
echo

echo "Updating configuration..." 1>&2
cat <<EOF >> /etc/default/extlinux
# kernel choosen at $(date)
DEFAULT="kernel-${VERSIONS[$USER_CHOICE]}"
EOF

update-extlinux.sh
