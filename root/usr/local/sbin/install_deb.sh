#!/bin/bash

if [[ $# -lt 0 ]]; then
  echo "usage: $0 <deb-urls(s)...>"
  exit 1
fi

TMPDIR=$(mktemp -d)

trap 'cd; rm -rf "$TMPDIR"' exit

cd "$TMPDIR"

for url; do
  wget "$url"
done

apt install /$PWD/*.deb
