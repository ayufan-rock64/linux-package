#!/bin/bash

set -eo pipefail

if [[ -e /etc/board-package ]]; then
  source /etc/board-package
fi
if [[ -z "$BOARD" ]]; then
  echo "The BOARD= is not defined in /etc/board-package"
fi

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 [latest] [u-boot-version]"
  exit 1
fi

find() {
  if [[ "$2" != "latest" ]]; then
    set -- "$1" "tags/$2"
  fi
  curl --silent --fail "https://api.github.com/repos/ayufan-rock64/$1/releases/$2" \
    | jq -r '.assets | .[] | .browser_download_url' \
    | grep -E "u-boot-$BOARD-"
}

if FILES=$(find linux-mainline-u-boot "$1"); then
  echo "Installing $1..."
  echo "$FILES"
  install_deb $FILES
else
  echo "Did not find u-boot '$1' in:"
  echo "- https://github.com/ayufan-rock64/linux-mainline-u-boot/releases"
  exit 1
fi

exit 0
