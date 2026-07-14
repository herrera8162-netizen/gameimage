#!/usr/bin/env bash

######################################################################
# @description : Assemble gameimage.flatimage from already-built native
#                 binaries (main/boot/wizard/launcher), skipping the Docker
#                 build steps in flatimage-alpine.sh. Used on a dev VM where
#                 those binaries were already built directly via cmake/cargo
#                 (glibc, not musl) - so this uses an Arch (glibc) FlatImage
#                 base instead of Alpine (musl), matching what wizard/
#                 launcher actually link against. gameimage-cli/gameimage-boot
#                 are fully static either way (see src/CMakeLists.txt's
#                 -static linker flag) so the base distro doesn't matter for
#                 those two.
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

# These are all statically-linked (libc-independent) tools, so they run fine
# regardless of the base distro's libc
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

# Arch (glibc) base instead of Alpine (musl) - matches what wizard/launcher
# actually need. Same base image container/build-arch.sh uses for the
# runner/game layers.
export IMAGE="$BUILD_DIR"/arch.flatimage
wget -q --show-progress --progress=dot:mega -O"$IMAGE" "https://github.com/flatimage/flatimage/releases/download/v2.0.0/arch-x86_64.flatimage"
chmod +x "$IMAGE"

"$IMAGE" fim-perms add home,media,network,xorg,wayland,dbus_user,dev

"$IMAGE" fim-root pacman -Syu --noconfirm
"$IMAGE" fim-root pacman -S --noconfirm wayland pango glib2 cairo libxkbcommon libxinerama libxcursor libxrender libxfixes libxft noto-fonts dbus openssl mesa

# dbus installs a setuid-root helper unreadable by the unprivileged user that
# later runs `fim-layer commit` - mkdwarfs (the layer compressor) exits
# non-zero when it can't read a file during scanning (even though it just
# substitutes an empty placeholder and continues), which flatimage's wrapper
# then surfaces as a hard "Failed to commit layer" error. Dropping the setuid
# bit avoids triggering that in the first place; this helper isn't needed for
# the wizard/launcher's own dbus usage (session bus client only).
"$IMAGE" fim-root chmod 644 /usr/lib/dbus-daemon-launch-helper

"$IMAGE" fim-env set 'PATH=/opt/gameimage/bin:"$PATH"' 'GIMG_BACKEND="/opt/gameimage/bin/gameimage-cli"'

"$IMAGE" fim-boot set sh -c '/opt/gameimage/bin/gameimage-wizard'

"$IMAGE" fim-exec cp -r "$BUILD_DIR"/app /opt/gameimage

"$IMAGE" fim-layer commit binary

mv "$IMAGE" "$BUILD_DIR"/gameimage

echo "Built: $BUILD_DIR/gameimage"
