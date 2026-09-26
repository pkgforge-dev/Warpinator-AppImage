#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm warpinator

echo "Making warpinator relocatable..."
echo "---------------------------------------------------------------"
# make the application look for its files relative to where it is
# installed instead of the hardcoded /usr paths
patch -p1 -d / < ./patches/warpinator-relocatable-paths.patch

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano
