# io.github.HarbourMasters.Ghostship

Unofficial Flatpak that builds [Ghostship](https://github.com/HarbourMasters/Ghostship)
(Super Mario 64 PC port) from source. Modeled on the Starship Flatpak.

## Build locally
```bash
bash prepare.sh     # pins Ghostship, Torch, libultraship, deps into the manifest (run once on a fresh checkout)
flatpak-builder --user --install --force-clean build-dir io.github.HarbourMasters.Ghostship.yml
flatpak run io.github.HarbourMasters.Ghostship
```
`prepare.sh` replaces the `@PLACEHOLDERS@` in the manifest, so re-run it from a clean
copy of the template to update. `GHOSTSHIP_REF=<branch|tag> bash prepare.sh` builds something other than `develop`.

## ROM
Provide your own US or JP Super Mario 64 `.z64` (SHA-1 in Ghostship's README).
Easiest: copy it to `~/.var/app/io.github.HarbourMasters.Ghostship/data/ghostship/`
and launch; Ghostship offers to generate `sm64.o2r` from it.

## Notes
- No GLEW / SDL2_net modules (Starship needs them; Ghostship doesn't on Linux).
- mbedtls is pinned to 3.6.x because Ghostship's networking code doesn't build against 4.x.
- If the build fails on Vulkan/shaderc, add `-DCMAKE_DISABLE_FIND_PACKAGE_Vulkan=ON` to the cmake line.
- The CI file belongs at `.github/workflows/ci.yml` (your Starship zip had it flattened at the root).
