#!/bin/bash
# Install the MacBook8,1 speaker driver (thomas-shirley/macbook8.1-speaker-driver)
# with the dkms.conf fix that dkms 3.0.x (Ubuntu 24.04 / Linux Mint 22) needs.
set -euo pipefail

UPSTREAM=https://github.com/thomas-shirley/macbook8.1-speaker-driver.git
# Commit tested on MacBook8,1 / Linux Mint 22.3; override with UPSTREAM_REF=main
REF=${UPSTREAM_REF:-fe54ad1aa7d8448fc49c0b5c8b353c50e2b1b8a1}
# DKMS links its source to this tree and rebuilds from it on every kernel update,
# so it must stay in place and be writable only by root.
DIR=/opt/macbook8.1-speaker-driver

if [[ $EUID -ne 0 || -z ${SUDO_USER:-} ]]; then
    echo "Run from your normal user with sudo: sudo ./install.sh" >&2
    exit 1
fi

apt-get install -y gcc make dkms wget git "linux-headers-$(uname -r)"

if [[ -d $DIR/.git ]]; then
    git -C "$DIR" checkout -- dkms.conf
    git -C "$DIR" fetch --quiet origin
else
    git clone --quiet "$UPSTREAM" "$DIR"
fi
git -C "$DIR" checkout --quiet "$REF"

# DKMS runs CLEAN after PRE_BUILD; "rm -rf build" would delete the modules
# PRE_BUILD just built. Upstream PR #9; a no-op once it is merged.
sed -i 's/^CLEAN="rm -rf build"$/CLEAN="true"/' "$DIR/dkms.conf"

cd "$DIR"
bash install.sh

echo
echo "Done. Reboot, then check: wpctl status | grep -i speaker"
