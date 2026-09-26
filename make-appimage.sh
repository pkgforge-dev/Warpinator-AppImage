#!/bin/sh
set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q warpinator | awk '{print $2; exit}')
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DESKTOP=/usr/share/applications/org.x.Warpinator.desktop
export ICON=/usr/share/icons/hicolor/256x256/apps/org.x.Warpinator.png
export DEPLOY_PYTHON=1
export DEPLOY_GTK=1

# Deploy dependencies
quick-sharun \
	/usr/bin/warpinator*        \
	/usr/lib/warpinator         \
	/usr/share/warpinator       \
	/usr/lib/libgtk-3.so*       \
	/usr/lib/libxapp.so*

# Deploy additional .desktop files
mkdir -p ./AppDir/share/applications
cp -f /etc/xdg/autostart/warpinator-autostart.desktop ./AppDir/share/applications/

# Guarantee complete transitive dependency closure for C extensions (e.g. grpcio, cygrpc)
while :; do
	new_libs=0
	for elf in $(find ./AppDir/lib ./AppDir/bin -type f \( -name '*.so*' -o -perm /111 \)); do
		for dep in $(ldd "$elf" 2>/dev/null | awk '/=> \//{print $3}'); do
			base="${dep##*/}"
			if [ ! -f "./AppDir/lib/$base" ] && [ -f "$dep" ]; then
				cp -Lv "$dep" "./AppDir/lib/"
				new_libs=1
			fi
		done
	done
	[ "$new_libs" = 0 ] && break
done

# Refresh lib.path for sharun runtime discovery
./AppDir/sharun -g

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the AppImage
quick-sharun --simple-test ./dist/*.AppImage
