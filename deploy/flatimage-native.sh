#!/usr/bin/env bash

######################################################################
# @description : Assemble gameimage.flatimage from already-built native
#                 binaries (main/boot/wizard/launcher), skipping the Docker
#                 build steps in flatimage-alpine.sh. Used on a dev VM where
#                 those binaries were already built directly via cmake/cargo.
######################################################################

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SRC_DIR="$(dirname "$SCRIPT_DIR")"

BUILD_DIR="$SRC_DIR/build-flatimage"
rm -rf "$BUILD_DIR" && mkdir "$BUILD_DIR"

BIN_DIR="$BUILD_DIR/app/bin"
mkdir -p "$BIN_DIR"

# Use already-built native binaries instead of Docker-building them
cp -v "$SRC_DIR"/src/build/Debug/main "$BIN_DIR"/gameimage-cli
cp -v "$SRC_DIR"/src/build/Debug/boot "$BIN_DIR"/gameimage-boot
cp -v "$SRC_DIR"/gui/target/debug/wizard "$BIN_DIR"/gameimage-wizard
cp -v "$SRC_DIR"/gui/target/debug/launcher "$BIN_DIR"/gameimage-launcher

function _fetch()
{
  local link="$1"
  local out="$2"
  local file="$3"
  echo "Fetch '$link' to '$out'"
  if [[ "$link" =~ .tar.(xz|gz) ]]; then
    wget -q --show-progress --progress=dot:mega "$link" -O - | tar xz "$file" -O > "$out"
  else
    wget -q --show-progress --progress=dot:mega "$link" -O "$out"
  fi
  chmod +x "$out"
}

_fetch "https://github.com/ruanformigoni/unionfs-fuse/releases/download/ebac73a/unionfs" "$BIN_DIR"/unionfs
_fetch "https://github.com/ruanformigoni/fuse-overlayfs/releases/download/af507a2/fuse-overlayfs-x86_64" "$BIN_DIR"/overlayfs
_fetch "https://github.com/mikefarah/yq/releases/download/v4.30.7/yq_linux_amd64.tar.gz" "$BIN_DIR/yq" "./yq_linux_amd64"
_fetch "https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-amd64" "$BIN_DIR"/jq
_fetch "https://github.com/ruanformigoni/7zip_static/releases/download/ed1f3df/7zz" "$BIN_DIR"/7zz
_fetch "https://github.com/ruanformigoni/busybox-static-musl/releases/download/7e2c5b6/busybox-x86_64" "$BIN_DIR"/busybox
_fetch "https://github.com/ruanformigoni/imagemagick-static-musl/releases/download/c1c5775/magick-x86_64" "$BIN_DIR"/magick
_fetch "https://github.com/ruanformigoni/lsof-static-musl/releases/download/12c2552/lsof-x86_64" "$BIN_DIR"/lsof
_fetch "https://github.com/sharkdp/fd/releases/download/v8.7.1/fd-v8.7.1-x86_64-unknown-linux-musl.tar.gz" "$BIN_DIR"/fd "fd-v8.7.1-x86_64-unknown-linux-musl/fd"
_fetch "https://github.com/ruanformigoni/aria2-static-musl/releases/download/2d7f402/aria2c" "$BIN_DIR"/aria2c
_fetch "https://github.com/ruanformigoni/bash-static/releases/download/8ba11cd/bash-x86_64" "$BIN_DIR"/bash

wget -q --show-progress --progress=dot:mega "https://github.com/ruanformigoni/coreutils-static/releases/download/d7f4cd2/coreutils-x86_64.tar.xz" -O "$BUILD_DIR/coreutils.tar.xz"
tar -xf "$BUILD_DIR/coreutils.tar.xz" -C"$BIN_DIR" --strip-components=1
rm "$BUILD_DIR/coreutils.tar.xz"

_fetch "https://github.com/ruanformigoni/gnu-static-musl/releases/download/b122ecc/sed" "$BIN_DIR"/sed
_fetch "https://github.com/ruanformigoni/gnu-static-musl/releases/download/b122ecc/grep" "$BIN_DIR"/grep
_fetch "https://github.com/ruanformigoni/gnu-static-musl/releases/download/b122ecc/tar" "$BIN_DIR"/tar
_fetch "https://github.com/ruanformigoni/xz-static-musl/releases/download/fec8a15/xz" "$BIN_DIR"/xz
_fetch "https://github.com/ruanformigoni/pv-static-musl/releases/download/3398ec0/pv-x86_64" "$BIN_DIR"/pv

for i in "$BUILD_DIR"/app/bin/*; do
  chmod +x "$i"
done

export IMAGE="$BUILD_DIR"/alpine.flatimage
wget -q --show-progress --progress=dot:mega -O"$IMAGE" "https://github.com/flatimage/flatimage/releases/latest/download/alpine-x86_64.flatimage"
chmod +x "$IMAGE"

"$IMAGE" fim-perms add home,media,network,xorg,wayland,dbus_user,dev

"$IMAGE" fim-root apk add wayland-libs-client wayland-libs-cursor pango glib cairo libgcc dbus-libs libxkbcommon libxinerama libxcursor font-noto xz tar libssl3

"$IMAGE" fim-env set 'PATH=/opt/gameimage/bin:"$PATH"' 'GIMG_BACKEND="/opt/gameimage/bin/gameimage-cli"'

"$IMAGE" fim-boot set sh -c '/opt/gameimage/bin/gameimage-wizard'

"$IMAGE" fim-exec cp -r "$BUILD_DIR"/app /opt/gameimage

"$IMAGE" fim-layer commit binary

mv "$IMAGE" "$BUILD_DIR"/gameimage

echo "Built: $BUILD_DIR/gameimage"
