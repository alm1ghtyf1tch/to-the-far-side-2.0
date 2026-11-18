# Visual overhaul development notes

Phase 1 implements the presentation foundation on `visual-overhaul`. Phase 2 now
extends it with image movement, display modes and the headquarters; see
[Phase 2 notes](phase2.md) for the current architecture, settings and preview steps.
The gameplay
classes, campaign data, scientific calculations, narrative, and flight/minigame
mechanics are unchanged. The following sections describe the original Phase 1
foundation; Phase 2 notes supersede the original menu/HQ status and display schema.

## Rendering and routing

Run the project normally (F6 on `presentation_shell.tscn`, or F5). The shell owns:

- `Content`: a SubViewport containing the current original screen and its local
  CanvasLayers, including the Moon map and ReadMore panels.
- `Screen`: a full-window TextureRect drawing Content through `crt.gdshader`.

`SceneRouter.go_to(path, fade_time)` keeps its original routes, busy guard, fade
durations, and frame waits. It delegates scene loading to the shell when present.
Screens detach immediately and the next screen attaches deferred. The shell
remains `SceneTree.current_scene`; its `active_screen` is the routed game screen.
The router's existing layer-100 fade stays above the final display.

Direct F6 runs of individual original scenes retain legacy routing and omit the
compositor. Use the shell/project entry point to assess CRT and input behavior.

The render target follows native window resolution for readable fonts. Its 2D
override follows the root's existing canvas_items/expand logical canvas. Future
3D environments should use their own SubViewports/World3D resources and present
their textures inside the routed screen. The outer composition is 2D-only.

## CRT and input

The shader provides curvature, scanlines, restrained edge color separation,
neighbor-sample glow, a vignette, and static fine grain. Disabling CRT gives an
unaltered texture sample. No simulated time or RNG is used by the filter.

`CRTGeometry.source_uv()` must match the shader's `source_uv()` exactly. Both use
a maximum curvature coefficient of 0.08, multiplied by the saved 0–1 control.
Pointer coordinates go from Screen-local UV through that same sampling mapping
into Content's **logical** 2D override coordinates. `push_input(..., true)` expects
these logical coordinates, rather than render-target pixels.

Keyboard/controller events are forwarded once. Pointer motion, click, wheel,
touch, and drag use the mapped surface. Mouse enter/exit notifications and cursor
shape follow the hovered content control. Releases outside the curved image are
forwarded so slider drags and landing-engine holds cannot remain pressed. Input
is blocked during the router's transitions; campaign ticking stays in its
original controllers and is never driven by visual animation completion.

## Settings

`GameSettings` retains the original resolution/music API. `save()` accepts an
optional third dictionary and preserves unknown settings keys. The new
`[presentation]` section in `user://settings.cfg` stores:

| Key | Default |
| --- | --- |
| crt_enabled | true |
| curvature | 0.35 |
| scanlines | 0.18 |
| chromatic_aberration | 0.15 |
| glow | 0.12 |
| reduced_motion | false |

Older files receive these defaults. Visual strengths are sanitized to finite
0–1 values. `GameSettings.events.visuals_changed` updates the compositor and
shared motion components without polling settings every frame.

The existing menu demonstrates the controls. Display changes preview live; Save
persists all settings, while Back/Escape restores the saved display preference.
Resolution and music retain their original Save behavior. Reduced motion settles
shared button/panel animations and freezes the menu's decorative sky motion.
Legacy per-screen animations are migrated with their respective later phases;
essential flight animation and minigame timing are not suppressed.

## Shared interface components

- `VisualTheme.shared()`: cached IBM Plex/Saira typography, semantic colors,
  surfaces, focus outlines, and slider/button styles. Apply it to new presentation
  subtrees; existing document styles are deliberately preserved for later work.
- `TactileButton`: a native Button with a non-interactive visual face. The native
  hit rectangle, minimum size, signals, disabled state, and focus remain stable.
  Native text/theme overrides are reflected on the face.
- `TactileCard`: the same behavior with native toggle selection and a shared card
  style. Hover/focus and committed selection remain separate states.
- `UiMotion.bind(button, face)`: reusable, cancellable hover/compression/rebound
  behavior. Only the face transforms. Timings are centralized in UiMotion.
- `UiMotion.reveal(control)` / `AnimatedPanel.reveal()`: an interruptible panel
  entrance. AnimatedPanel also settles an entrance when reduced motion changes.
- `DisplaySettings`: an existing-menu demonstration of the card, panel, typography,
  sliders, live preview, and reduced-motion preference.

New controls should call existing gameplay handlers immediately. Never await a
visual tween before calculating a value, committing a decision, or emitting a
minigame result. Reuse these components instead of creating per-screen spring
implementations. Build future environment controllers separately from simulation
classes; bind them to existing phase/line events and state.

## Validation

Use a Godot 4.7 executable from the repository root:

```powershell
godot --headless --editor --path . --import
godot --headless --path . --script tests/simulation_regression.gd
godot --headless --path . --script tests/settings_regression.gd
godot --headless --path . --script tests/presentation_smoke.gd
godot --path . --script tests/presentation_smoke.gd
```

`simulation_baseline.json` was captured before presentation integration from the
unchanged simulation, then verified with Godot 4.7.2. It contains a successful
mission, a no-launch configuration, deterministic replay, manual-result overrides,
all six sites' payload totals, and staging gains. Do not re-record it to make a
regression pass. Numeric comparisons allow only JSON round-trip tolerance.

The settings test exercises the actual configuration codec through an ignored
test file; it does not overwrite the player's saved settings. Presentation smoke
tests exercise all 12 routes, preview cancellation, keyboard delivery, maximum/
default/zero curvature across 720p/900p/1080p/1440p and a taller aspect ratio,
cursor forwarding, drag release outside the display, dialog layering, interrupted
springs, reduced motion, existing staging input, landing engine holds, and flight
skip-to-report behavior. The rendered run additionally checks an embedded 3D
viewport's pixels in the final CRT output.

Real rendered screenshots are saved under ignored `.godot/phase1-*.png`: menu,
settings, HQ, CRT-off, and the 3D composition probe. Headless runs skip all image
capture/3D pixel checks and must not be described as visual verification.

Verified during this milestone with Godot 4.7.2, Windows Forward+/D3D12, on an
RTX 3060. Menu and display settings were rendered and inspected. This is a smoke
and regression suite, not a complete manual campaign playthrough or a performance
guarantee for lower-end laptops. No new scientific validation claims are made.

## Performance and remaining work

There is one full-resolution content buffer and one final CRT pass. The shader
uses at most seven texture samples, with glow/color samples skipped when their
strengths are zero. Theme/material resources are reused; no effect objects are
spawned per frame. TactileButton checks native text/icon/disabled changes each
frame but only updates resources when those values or interaction states change.

Completed since this foundation: main-menu/HQ art and the Phase 2 display extension.
Remaining phases: 3D Moon and coordinate/camera controllers,
fixed-camera mission rendering and event dashboard, assembly proposals before its
redesign, reports/reviews, legacy animation migration, profiling on modest Windows
hardware, accessibility/input coverage beyond these desktop smoke tests, and final
export validation. No production 3D art or placeholder models were added in Phase 1;
the cube in the smoke test is only a rendering-composition probe.
