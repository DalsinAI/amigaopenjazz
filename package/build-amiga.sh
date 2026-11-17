#!/bin/sh
# The release archive, for Cradle's stove_build (target package, STOVE= and
# OUT= set): the engine built as build-amigaos3.sh builds it, its ReadMe
# (package/ReadMe), GPL text (the source's COPYING) and the GlowIcons from
# icons/ put in the OpenJazz drawer, then the drawer, its icon and the
# Installer script beside it packed as OpenJazz-VERSION-68040.lha
# (tools/pack_dist.py, tools/lha_archive.py) with its .sha256 and a short
# .readme. VERSION is the Installer script's $VER. The game data is not in
# it (gameports/catalog.json): the player copies it into the drawer. SRC is
# the pinned upstream source; when it is not there,
# scripts/game_port_prepare.py fetches it. Nothing is published from here.
# MIT, Copyright (c) 2026 AmiCradle Team.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$HERE/.." && pwd)
STOVE=${STOVE:-"$HOME/AmigaChrome/stoves/os32-gcc16"}
OUT=${OUT:-"$ROOT/build-amiga-package"}
SRC=${SRC:-"$ROOT/build/game-ports/sources/openjazz"}
mkdir -p "$OUT"
OUT=$(CDPATH= cd -- "$OUT" && pwd)
cd "$ROOT"
if [ ! -d "$SRC" ]; then
    python3 "$ROOT/scripts/game_port_prepare.py" prepare --game openjazz --allow-network
fi
BUILD=$(mktemp -d "${TMPDIR:-/tmp}/openjazz-package.XXXXXX")
trap 'rm -rf "$BUILD"' EXIT INT TERM

STOVE="$STOVE" sh "$ROOT/build-amigaos3.sh" "$SRC" "$BUILD/out" > "$OUT/build-output.txt" 2>&1 \
    || { tail -n 60 "$OUT/build-output.txt"; exit 1; }

DIST="$BUILD/dist"
mkdir -p "$DIST/OpenJazz"
cp "$BUILD/out/OpenJazz" "$DIST/OpenJazz/OpenJazz"
cp package/ReadMe "$DIST/OpenJazz/ReadMe"
cp "$SRC/COPYING" "$DIST/OpenJazz/COPYING"
cp icons/OpenJazz.info icons/ReadMe.info icons/COPYING.info "$DIST/OpenJazz/"
cp icons/OpenJazz-drawer.info "$DIST/OpenJazz.info"
cp package/Install-OpenJazz package/Install-OpenJazz.info "$DIST/"
python3 "$ROOT/tools/pack_dist.py" --dist "$DIST" --name OpenJazz --out "$OUT"
