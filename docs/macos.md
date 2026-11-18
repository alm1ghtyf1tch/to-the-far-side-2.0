# macOS development build

The development ZIP contains a Universal 2 `.app` (Apple Silicon ARM64 and Intel),
Godot 4.7.2, game resources, and built-in ad-hoc signatures. It is **not notarized**.
The macOS renderer uses Godot's Mobile rendering path to limit overhead. The
interface keeps the shared CRT and logical coordinates. This does not constitute
testing on an A18 Pro / 8 GB MacBook Neo; actual launch/performance need that Mac.

## Download and open

1. Open [the development build workflow](https://github.com/alm1ghtyf1tch/to-the-far-side-2.0/actions/workflows/macos-dev.yml), choose the latest successful `visual-overhaul` run, and download `ToTheFarSide-macOS-Dev` from Artifacts (GitHub login may be required).
2. Unzip the artifact download, then unzip `ToTheFarSide-macOS-Dev.zip` using macOS Archive Utility. Move the extracted `.app` to Applications or your preferred folder.
3. Open the app. If macOS blocks this unnotarized development build, use **System Settings → Privacy & Security → Open Anyway** after attempting to open it, then confirm Open. Follow Apple's prompt for this specific trusted build; do not disable Gatekeeper globally.
4. Start at 1280×720 windowed. Check the menu, CRT pointer alignment, HQ, Moon, assembly and Mission Control. Then try windowed/fullscreen on the approximately 16:10 display; verify all edge tabs, scrolling and critical actions remain accessible.

Local exports are written to `build/macos/ToTheFarSide-macOS-Dev.zip`, which is
ignored by Git. A manually triggered workflow and development-branch push trigger
produce the same ZIP as a 30-day Actions artifact. No public release is created.
GitHub enables manual dispatch once the workflow is present on the default branch;
the development-branch push trigger also builds it before that merge.

## Rebuild

Install official **4.7.2 stable** and its matching standard export templates. Open
the project once to import resources, or run:

```text
godot --headless --editor --path . --quit
godot --headless --path . --export-release "macOS Dev" build/macos/ToTheFarSide-macOS-Dev.zip
python tools/validate_macos.py build/macos/ToTheFarSide-macOS-Dev.zip
```

The validator checks bundle metadata, both CPU slices, executable permissions,
embedded signatures and the packaged game pack. It cannot validate launch,
Gatekeeper approval, frame rate or device memory behavior from Windows/Linux.
No certificate, Apple account password or signing key is stored in the preset.

References: [Godot macOS export/signing documentation](https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_macos.html),
[Apple instructions for opening an app from an unidentified developer](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac).
