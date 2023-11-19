#!/bin/bash

set -eo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "Usage: $0 [latest] [kernel-version]"
  exit 1
fi

find() {
  if [[ "$2" != "latest" ]]; then
    set -- "$1" "tags/$2"
  fi
  curl --silent --fail "https://api.github.com/repos/ayufan-rock64/$1/releases/$2" \
    | jq -r '.assets | .[] | .browser_download_url' \
    | grep -E 'linux-image|linux-headers' \
    | grep -v '\-dbg'
}

if FILES=$(find linux-mainline-kernel "$1"); then
  echo "Installing $1..."
  echo "$FILES"
  install_deb.sh $FILES
elif FILES=$(find linux-kernel "$1"); then
  echo "Installing $1..."
  echo "$FILES"
  install_deb.sh $FILES
else
  echo "Did not find kernel '$1' in:"
  echo "- https://github.com/ayufan-rock64/linux-kernel/releases"
  echo "- https://github.com/ayufan-rock64/linux-mainline-kernel/releases"
  exit 1
fi

echo 'Now run `change-default-kernel.sh` to switch the used kernel.'
exit 0
