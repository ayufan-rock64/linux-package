#!/bin/bash

set -eo pipefail

if [[ -e /etc/board-package ]]; then
  source /etc/board-package
fi

BOARD_NAMES=()
[[ -n "$BOARD" ]] && BOARD_NAMES+=("$BOARD")

_pkg_board=$(dpkg -l 'u-boot-*' 2>/dev/null | awk '/^ii/ {print $2}' | sed 's/^u-boot-//' | head -1)
[[ -n "$_pkg_board" && "$_pkg_board" != "$BOARD" ]] && BOARD_NAMES+=("$_pkg_board")

if [[ "${#BOARD_NAMES[@]}" -eq 0 ]]; then
  echo "Could not detect board from /etc/board-package or installed u-boot package"
  exit 1
fi

BOARD_PATTERN=$(IFS='|'; echo "${BOARD_NAMES[*]}")

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
    | grep -E "u-boot-($BOARD_PATTERN)-"
}

if FILES=$(find linux-mainline-u-boot "$1"); then
  echo "Installing $1..."
  echo "$FILES"
  install_deb.sh $FILES
else
  echo "Did not find u-boot '$1' for board(s) [${BOARD_NAMES[*]}] in:"
  echo "- https://github.com/ayufan-rock64/linux-mainline-u-boot/releases"
  exit 1
fi

exit 0
