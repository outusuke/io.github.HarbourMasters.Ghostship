#!/usr/bin/env bash
# Resolves Ghostship's current develop + submodule pins into the manifest.
# Needed because the submodule pins can't be fetched with `git submodule`
# in flatpak-builder, so we pin Torch by commit and libultraship by archive.
#
# Usage: bash prepare.sh [manifest]        (GHOSTSHIP_REF=<branch|tag> to override "develop")
set -euo pipefail
MANIFEST="${1:-io.github.HarbourMasters.Ghostship.yml}"
REF="${GHOSTSHIP_REF:-develop}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export GIT_LFS_SKIP_SMUDGE=1

git clone --quiet --no-recurse-submodules --filter=blob:none --branch "$REF" \
  https://github.com/HarbourMasters/Ghostship.git "$WORK/src"
GHOSTSHIP=$(git -C "$WORK/src" rev-parse HEAD)
LUS=$(git -C "$WORK/src" rev-parse HEAD:libultraship)
TORCH=$(git -C "$WORK/src" rev-parse HEAD:Torch)
echo "Ghostship $GHOSTSHIP ($REF) | libultraship $LUS | Torch $TORCH"

# GitHub serves archives for commits in a repo's fork network, even when
# `git fetch` refuses them. Try the likely repos in turn.
LUS_URL=""
for repo in Kenix3 HarbourMasters KiritoDv; do
  url="https://github.com/$repo/libultraship/archive/$LUS.tar.gz"
  if curl -fsSL "$url" -o "$WORK/lus.tar.gz"; then LUS_URL="$url"; break; fi
done
[ -n "$LUS_URL" ] || { echo "Could not download libultraship $LUS from any known repo" >&2; exit 1; }
LUS_SHA=$(sha256sum "$WORK/lus.tar.gz" | cut -d' ' -f1)

# libultraship expects this beside the executable; upstream downloads it at configure time.
# Pinned here so the build is reproducible.
GCDB_URL="https://raw.githubusercontent.com/mdqinc/SDL_GameControllerDB/5a12daa568d19344f9b6e9286ef5929833b25c7c/gamecontrollerdb.txt"
curl -fsSL "$GCDB_URL" -o "$WORK/gcdb.txt"
GCDB_SHA=$(sha256sum "$WORK/gcdb.txt" | cut -d' ' -f1)

# Build dependencies not shipped in the Freedesktop SDK (URL + checksum filled in below).
# mbedtls must stay on the 3.x line: Ghostship uses APIs that were removed in 4.x.
declare -A DEPS=(
  [LIBZIP]="https://github.com/nih-at/libzip/releases/download/v1.11.3/libzip-1.11.3.tar.xz"
  [TINYXML2]="https://github.com/leethomason/tinyxml2/archive/refs/tags/10.0.0.tar.gz"
  [SPDLOG]="https://github.com/gabime/spdlog/archive/refs/tags/v1.15.3.tar.gz"
  [JSON]="https://github.com/nlohmann/json/archive/refs/tags/v3.11.3.tar.gz"
  [MBEDTLS]="https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-3.6.3/mbedtls-3.6.3.tar.bz2"
)
for k in "${!DEPS[@]}"; do
  curl -fsSL "${DEPS[$k]}" -o "$WORK/$k.dl" || { echo "Download failed for $k: ${DEPS[$k]}" >&2; exit 1; }
  sha=$(sha256sum "$WORK/$k.dl" | cut -d' ' -f1)
  sed -i -e "s|@${k}_URL@|${DEPS[$k]}|" -e "s|@${k}_SHA@|$sha|" "$MANIFEST"
done

sed -i \
  -e "s|@GHOSTSHIP_COMMIT@|$GHOSTSHIP|" \
  -e "s|@TORCH_COMMIT@|$TORCH|" \
  -e "s|@LUS_URL@|$LUS_URL|" \
  -e "s|@LUS_SHA@|$LUS_SHA|" \
  -e "s|@GCDB_URL@|$GCDB_URL|" \
  -e "s|@GCDB_SHA@|$GCDB_SHA|" \
  "$MANIFEST"

if grep -n -E "'@[A-Z0-9_]+@'" "$MANIFEST"; then
  echo "Unresolved placeholders remain in $MANIFEST (is this already a resolved copy?)" >&2
  exit 1
fi
echo "Manifest updated: $MANIFEST"
