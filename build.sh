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

    # Package a drag-and-drop release zip mirroring the SD card root.
    # NOTE: "bootloader" is ALSO the name of hekate's own source dir
    # (SOURCEDIR in Makefile) -- do NOT copy that wholesale, it's C sources,
    # not the SD runtime folder. Assemble the runtime bootloader/ folder from
    # build output (output/) + config templates (res/) instead.
    # emummc.kipm/res.pak/thk.bin (mentioned in README) aren't produced by
    # this build -- not required for a working install.
    # See PACKAGING.md at the switch-cfw root.
    BIN="output/hekate.bin"
    if [ -f "$BIN" ]; then
        ZIPS_DIR="$SCRIPT_DIR/../_ZIPS_"
        SDCARD_DIR="$SCRIPT_DIR/../_SDCARD_/hekate"
        PKG="$SCRIPT_DIR/.release-pkg"
        rm -rf "$PKG" "$SDCARD_DIR"
        mkdir -p "$PKG/bootloader/sys" "$PKG/bootloader/ini" "$PKG/bootloader/res" "$PKG/bootloader/payloads"
        cp "$BIN" "$PKG/hekate.bin"
        cp output/nyx.bin output/libsys_lp0.bso output/libsys_minerva.bso "$PKG/bootloader/sys/"
        cp res/hekate_ipl_template.ini "$PKG/bootloader/hekate_ipl.ini"
        cp res/patches_template.ini "$PKG/bootloader/patches.ini"
        mkdir -p "$ZIPS_DIR"
        ( cd "$PKG" && zip -r -X "$ZIPS_DIR/hekate-release.zip" ./* >/dev/null )
        cp -r "$PKG"/* "$SDCARD_DIR/"
        rm -rf "$PKG"
        echo "== Packaged: $ZIPS_DIR/hekate-release.zip =="
        echo "== Extracted: $SDCARD_DIR =="
    else
        echo "== WARNING: build reported success but no $BIN found =="
    fi
fi

exit $STATUS
