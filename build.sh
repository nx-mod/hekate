#!/bin/bash
# Builds hekate (+ Nyx, bootloader modules) inside the devkitPro MSYS2 shell.
# Invoked by build.bat in this same folder (and usable standalone from msys2):
#   bash build.sh [target] [jobs] [--dryrun]
#     target  all (default) | clean

source /etc/profile.d/devkit-env.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

TARGET="${1:-all}"
JOBS="${2:-2}"
DRYRUN=""
[ "${3}" = "--dryrun" ] && DRYRUN="-n"

echo "DEVKITPRO=$DEVKITPRO DEVKITARM=$DEVKITARM"
echo "Target=$TARGET Jobs=$JOBS DryRun=${DRYRUN:-no} CWD=$(pwd)"

if [ "$TARGET" = "clean" ]; then
    make clean
    exit $?
fi

make $DRYRUN -j"$JOBS" "$TARGET"
STATUS=$?

if [ $STATUS -eq 0 ] && [ -z "$DRYRUN" ]; then
    echo "== Build ok. Output: =="
    ls -la output/ 2>/dev/null

    # Package a drag-and-drop release zip mirroring the SD card root:
    # hekate_ctcaer_*.bin at the SD root, bootloader/ folder alongside it.
    # See PACKAGING.md at the switch-cfw root.
    BIN="$(ls output/hekate_ctcaer_*.bin 2>/dev/null | head -1)"
    if [ -n "$BIN" ]; then
        ZIPS_DIR="$SCRIPT_DIR/../_ZIPS_"
        SDCARD_DIR="$SCRIPT_DIR/../_SDCARD_/hekate"
        PKG="$SCRIPT_DIR/.release-pkg"
        rm -rf "$PKG" "$SDCARD_DIR"
        mkdir -p "$PKG" "$SDCARD_DIR"
        cp "$BIN" "$PKG/"
        cp -r bootloader "$PKG/bootloader"
        mkdir -p "$ZIPS_DIR"
        ( cd "$PKG" && zip -r -X "$ZIPS_DIR/hekate-release.zip" ./* >/dev/null )
        cp -r "$PKG"/* "$SDCARD_DIR/"
        rm -rf "$PKG"
        echo "== Packaged: $ZIPS_DIR/hekate-release.zip =="
        echo "== Extracted: $SDCARD_DIR =="
    else
        echo "== WARNING: build reported success but no output/hekate_ctcaer_*.bin found =="
    fi
fi

exit $STATUS
