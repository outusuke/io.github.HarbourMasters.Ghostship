#!/usr/bin/env bash
set -euo pipefail
flatpak install -y --user flathub org.freedesktop.Platform//25.08 org.freedesktop.Sdk//25.08
flatpak-builder --force-clean --user --install-deps-from=flathub --repo=repo build-dir io.github.HarbourMasters.Ghostship.yml
flatpak build-bundle repo ghostship.flatpak io.github.HarbourMasters.Ghostship
echo "Done: ghostship.flatpak  (install: flatpak install --user ghostship.flatpak)"
