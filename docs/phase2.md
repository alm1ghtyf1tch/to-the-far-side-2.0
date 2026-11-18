# Phase 2: display movement, modes, menu, headquarters

Implemented on the existing visual-overhaul branch. Phase 1's CRT treatment and
button motion are retained. Phase 2 was manually approved; the subsequent lunar
planner implementation is documented in [phase3.md](phase3.md).

## Main changes

| Area | Important files |
| --- | --- |
| Single-pass movement and matching input | `systems/rendering/presentation_shell.gd`, `crt_geometry.gd`, `shaders/crt/crt.gdshader` |
| Settings, native modes and migration | `autoload/game_settings.gd`, `ui/components/display_settings.gd` |
| Main menu and settings layout | `screens/main_menu/main_menu.tscn`, `main_menu.gd`, `menu_shade.gdshader` |
| 3D environment, camera, hover and ambient motion | `environments/headquarters/headquarters_diorama.tscn`, `headquarters_diorama.gd` |
| Reusable authored furnishings/materials | `environments/headquarters/hq_props.gd` |
| Existing stage logic with new presentation | `screens/hq/hq.tscn`, `hq.gd`, `floor_hotspot.gd` |
| Integration checks | `tests/phase2_smoke.gd` |

## Image and input mapping

The existing composed content viewport and final CRT shader remain in place.
There is no additional fullscreen post-processing pass. First the existing glass
curvature determines the sampling position, then overscan/translation determines
which content pixel is sampled:

```text
content_uv = (glass_uv - 0.5 - image_offset) * visible_fraction + 0.5
```

The normal movement setting uses `visible_fraction = 0.95`, or approximately
1.0526× enlargement. Offset is derived from the **untransformed** pointer position
within Screen. Subtracting that offset from sampling coordinates moves the image
in the same direction as the pointer. Scanlines, vignette, chromatic response and
the original rounded CRT boundary remain fixed relative to the glass.

Movement uses a frame-rate-independent exponential response with a 0.16-second
time constant. It cannot overshoot. The strength slider scales a maximum offset
of 0.018 viewport units per axis; the default is 65%, approximately 1.17% at an
edge. This fits inside the overscan allowance. The original curved black corners
are glass masking, not newly exposed image borders.

CPU pointer forwarding uses the same sampling map with the **currently eased**
offset. Hover and drag coordinates refresh while the image settles beneath a
stationary cursor; physical movement is never inferred from these mapped events.
Disabling movement or enabling reduced motion immediately restores the Phase 1
framing. The saved movement preference is retained while reduced motion suspends
it. Movement can also be used without the CRT color treatment.

The content render target includes approximately 5% extra resolution on each axis
when overscan is active to retain native text density. This increases content
pixel count by approximately 11%; it does not add another filtering pass. Native
OptionButton popups are embedded in Content and receive the same compositing and
mapped input as other controls.

## Display settings

The native modes are Windowed, Borderless Fullscreen, and Exclusive Fullscreen
where the platform supports it. They use Godot DisplayServer's window modes.
Fullscreen uses the desktop resolution; the UI's logical canvas and the content
buffer remain distinct from output resolution. Exclusive mode follows Godot's
single-window behavior; it does not request a different desktop video mode.

The last chosen positive window size is stored separately. Returning to windowed
mode restores decorations, permits resizing, and clamps the window to the usable
screen area including a decoration allowance. Window presets are filtered for the
available display and desktop scale. Window-size controls are disabled while a
fullscreen mode is selected, with actual output/interface sizes displayed below.

New profiles default to borderless fullscreen for readable desktop-size output.
Existing profiles retain their mode: old positive resolutions migrate to
Windowed; the old zero-vector fullscreen sentinel migrates to Borderless. Existing
audio and CRT values are preserved. The new persisted keys are:

- `video/display_mode`: `windowed`, `borderless`, or `exclusive`.
- `video/windowed_resolution`: last positive window size.
- `presentation/dynamic_movement`: default `true`.
- `presentation/movement_strength`: default `0.65`.

`video/resolution` remains backward-compatible with the Phase 1 sentinel. Display
and audio changes still apply on Save. Visual controls preview live and revert on
Back/Escape. No test changes the player's settings file.

## Headquarters architecture

The headquarters owns an isolated 3D SubViewport, an orthographic camera, a
WorldEnvironment, two directional lights and three room accent lights. Shared
primitive meshes and a small material palette create a deliberate miniature:

- Board: conference furniture, programme display and stage indicators.
- Engineering: workbenches, monitors, tanks, a rotating rocket model and hoist.
- Science: instruments, telescope, rotating lunar globe and research consoles.
- Exterior: cutaway structural framing, plinth, roof equipment, dish and beacon.

The environment builds its geometry once on scene entry. There are no downloaded
models, external dependencies, large new textures, GI systems or particle clouds.
The main image remains the focal point, with a narrower scrollable programme brief
and safe margins for the movement effect.

The 3D controller has no campaign writes and performs no calculations of mission
outcomes. The original HQ controller still owns stage text, department permissions,
hints, ticking and routing. It passes existing programme/site/design information
to the display. Original narrative text and the eleven-stage routing table are
preserved. The model rocket is a schematic desk model; component-accurate vehicle
visualization belongs to later work, not this miniature.

Native FloorHotspot controls remain responsible for mouse/keyboard interactions.
Their polygons are projected from the camera's room openings and updated when the
camera or render target changes. Hover changes room lighting, outlines and labels,
without moving the camera. Valid selection starts an authored camera move during
the **existing 0.8-second router fade**, without adding a wait or advancing state.
Locked selections retain the original hints. Reduced motion stops model rotation,
dish movement and camera travel, while retaining static hover feedback.

## Validation and preview

Run these from the repository root with Godot 4.7:

```powershell
godot --headless --editor --path . --import
godot --headless --path . --script tests/simulation_regression.gd
godot --headless --path . --script tests/settings_regression.gd
godot --headless --path . --script tests/presentation_smoke.gd
godot --headless --path . --script tests/phase2_smoke.gd
godot --path . --script tests/phase2_smoke.gd
```

The rendered integration run exercises native mode switching twice through all
three Windows modes; desktop-size fullscreen; restored window decorations and
resizing; mode popup interaction; movement in both directions; corner alignment
and rapid adjacent clicks; reduced motion; settings migration/round-trip; all
eleven HQ stage gates; department hover; authored camera entry; and the existing
meeting return flow. The original simulation fixture still matches successful
and failed missions, replay and manual overrides. The Phase 1 smoke suite remains
available for all 12 routes and staging/landing control compatibility.

Rendering was tested with Godot 4.7.2, Forward+/D3D12 and an RTX 3060. Actual 1080p
menu, settings and headquarters captures were inspected. Headless tests skip
native mode changes and image capture. Generated previews are ignored files at
`.godot/phase2-menu-1080.png`, `phase2-settings-1080.png`, `phase2-hq-1080.png`,
`phase2-hq-science-hover.png` and `phase2-board-entry.png`.

For an interactive preview, open `project.godot` in Godot 4.7 and use **F5** in a
standalone game window. Open Settings to tune Dynamic screen movement and its
strength, choose a display mode, and Save. Play opens the headquarters. Hover its
three rooms; at stage 1, selecting Board enters the original meeting. Approving
that meeting returns to HQ and makes Engineering the next destination. Escape or
Main menu retains the original return behavior. F6 on HQ alone previews the room
without the global compositor; use F5 to assess the full CRT/parallax behavior.

## Limits and review

The environment uses authored procedural low-poly art, not temporary external
placeholder assets. Aesthetic preference, precise movement comfort, alternate
desktop scaling/multiple-monitor setups, other operating systems and lower-end
hardware performance still need manual review/profiling. No broad hardware FPS
guarantee or new scientific validation is claimed. The complete campaign has
regression coverage and targeted navigation checks, not a new full manual
playthrough. Phase 3 Moon selection and later flight/assembly redesigns are
untouched and must wait for Phase 2 review.
