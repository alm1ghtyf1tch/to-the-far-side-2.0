# TO THE FAR SIDE — PHASE 3: INTERACTIVE LUNAR SCIENCE PLANNER

## Stylized 3D Moon, Orbital Camera, Apollo Landing Sites & Animated Science Interface

You are continuing development of **To the Far Side**, an existing Godot 4.7 lunar mission strategy game undergoing a complete visual overhaul.

**Phases 1 and 2 are COMPLETE and have passed manual testing.**

Your task is to implement Phase 3: transform the existing Science Planner into a visually impressive, interactive, stylized 2.5D lunar exploration interface.

This is an implementation task. You are expected to create actual functional Godot scenes, shaders, scripts, materials, 3D geometry and UI components.

Do not merely describe what could be built.

**Preserve all original gameplay functionality and build directly on the systems completed in Phases 1 and 2.**

---

# 1. PROJECT CONTEXT

The game is an educational lunar mission design simulator developed in Godot 4.7 and GDScript.

The player manages a crewed lunar programme through 11 stages, making interconnected engineering, science, budget and risk decisions.

The Science Planner is the stage where the player selects a lunar landing site and scientific instruments.

Important existing files include:

- `screens/science_plan/science_plan.gd`
- `screens/science_plan/science_plan.tscn`
- `screens/science_plan/site_map.gd`
- `autoload/campaign.gd`
- `data/campaign.json`
- `ui/read_more.gd`

Relevant existing systems include:

- `Campaign.sites()`
- `Campaign.instrument_options()`
- `Campaign.plan_totals()`
- `Campaign.set_science_plan()`

Inspect these files and their current versions before modifying anything.

Also inspect the Phase 1 and Phase 2 implementations to determine the available reusable UI controls, rendering components, camera utilities, shaders and animation systems.

The original Science Planner contains six Apollo landing sites:

- Apollo 11 — Mare Tranquillitatis
- Apollo 12 — Oceanus Procellarum
- Apollo 14 — Fra Mauro
- Apollo 15 — Hadley–Apennine
- Apollo 16 — Descartes
- Apollo 17 — Taurus–Littrow

The locations and their latitude/longitude values are stored in the existing game data.

**Use the existing JSON coordinates as the authoritative data.**

Do not invent or approximate new coordinates.

---

# 2. ARTISTIC DIRECTION

Continue using the established visual language from Phases 1 and 2:

**RETRO-FUTURISTIC · LOW-POLY · 2.5D · ARCADE · CRT · SPACE-INDUSTRIAL**

Inspirations:

- Balatro: satisfying cards, animated choices, responsive interfaces, stylized UI.
- R.E.P.O.: simplified 3D forms, expressive geometry, stylized lighting.
- Lethal Company: retro-industrial science-fiction atmosphere, strong silhouettes, deliberately non-photorealistic rendering.

Do not directly copy artwork or proprietary assets.

The Science Planner should feel like an interactive lunar exploration terminal inside our fictional space agency.

The Moon should be a tangible 3D object, not merely a static illustration surrounded by text.

The screen must feel atmospheric, animated and visually interesting even when the player is not interacting with it.

However, do not overload the interface with effects.

**The Moon is the central visual attraction. The UI supports it.**

---

# 3. THE MAIN FEATURE — A REAL STYLIZED 3D MOON

Create a full 3D Moon rendered inside the Science Planner.

This must be an actual spherical 3D object with depth, lighting and a working orbital camera.

Do not implement the central Moon using a flat image, 2D circle or fake 3D shader alone.

## 3.1 Moon geometry

Use a suitable spherical mesh with an appropriate amount of geometry.

The Moon should have:

- A clearly spherical shape.
- Recognizable lunar surface structure.
- Visible crater features.
- Distinctive lighter highlands and darker maria.
- Stylized color variation.
- Carefully controlled surface roughness.
- A recognizable light/dark boundary.

Prefer a beautiful, simplified rendering over unnecessarily high geometric complexity.

Use a recognizable lunar texture or stylized map aligned correctly with the landing-site coordinate system.

If existing project assets are insufficient, create or obtain appropriately licensed assets.

Document the source and license of new third-party assets.

## 3.2 Surface details

The surface should not look like a perfectly smooth gray ball.

Use a combination of suitable techniques:

- Albedo texture.
- Normal maps where beneficial.
- Subtle height or displacement effects where feasible.
- Stylized crater shading.
- Broad color separation between terrain regions.
- Controlled roughness and highlights.

Crater details should contribute to the overall shape and readability.

Do not create extreme topography that distorts the Moon's appearance.

## 3.3 Lighting

Create attractive, deliberately stylized lighting.

Use a strong directional light representing sunlight.

Maintain a convincing day/night boundary.

Optional rim lighting can improve visibility and separation from the background, but it should remain clearly an artistic lighting effect rather than a physical lunar atmosphere.

Use subtle color accents consistent with the existing game's palette.

Avoid excessive bloom.

The Moon should look compelling from all Apollo landing-site viewpoints.

## 3.4 Background environment

Create a dark space background containing:

- A restrained star field.
- Subtle depth cues.
- Optional distant ambient particles.
- Minimal visual distractions.

The Moon should remain the obvious focal point.

Avoid a large, busy nebula that competes with the interface.

---

# 4. ORBITAL CAMERA SYSTEM — CRITICAL REQUIREMENT

This is the most important interaction of Phase 3.

The player must be able to preview lunar landing sites by hovering over their corresponding selection cards.

When a site is hovered, the camera smoothly orbits around the Moon to focus on that precise location.

**THE CAMERA MOVES AROUND THE MOON. THE MOON ITSELF SHOULD NOT BE SPUN AS A SUBSTITUTE FOR CAMERA MOVEMENT.**

The Moon should remain in a stable world coordinate system.

## 4.1 Camera behavior

Use a dedicated `Camera3D` controller.

The default view should show the Moon from an appealing angle, with relevant regions visible.

When the player previews a landing site:

1. Read the site's latitude and longitude.
2. Convert the coordinates into a direction on the sphere.
3. Calculate an appropriate camera position.
4. Smoothly orbit toward that position.
5. Orient the camera toward the chosen surface region.
6. Bring the selected landing site into the central viewing area.
7. Highlight the site.
8. Settle smoothly without abrupt motion.

The camera should feel like an automated scientific observation platform.

It must not feel like a free-roaming 3D camera controlled directly by the mouse.

## 4.2 Coordinate conversion

Implement a proper conversion from lunar latitude/longitude to sphere coordinates.

A conventional spherical direction in one possible coordinate system is:

```gdscript
var lat := deg_to_rad(latitude)
var lon := deg_to_rad(longitude)

var direction := Vector3(
    cos(lat) * cos(lon),
    sin(lat),
    cos(lat) * sin(lon)
).normalized()
```

**This is only an example coordinate convention.**

Determine the correct axes, longitude orientation, texture alignment and near-side direction for the actual scene.

Validate the transformation against recognizable lunar landmarks.

Avoid accidentally mirroring the Moon or reversing east/west longitudes.

Do not assume that world-space directions automatically match texture UV coordinates.

## 4.3 Smooth camera interpolation

The camera must move along a smooth orbital path.

Do not linearly interpolate camera positions through the Moon.

Use a stable method such as spherical interpolation of unit orbital directions, with a fixed or controlled orbital radius.

Use appropriate easing or spring damping.

Avoid Euler-angle interpolation problems, sudden angle wrapping, camera flipping and unstable roll.

When the cursor moves to another site before the previous animation finishes, smoothly retarget the camera from its current state.

Do not queue up several obsolete camera animations.

## 4.4 Camera framing

When previewing a site:

- The site should occupy the intended focal area of the Moon.
- The Moon should remain almost entirely visible in the viewport.
- The camera should not clip into the surface.
- The view should not become excessively zoomed in.
- The landing-site marker should not be hidden behind UI panels.

You may use a slight intentional framing offset if necessary to keep the site visible beside informational panels.

However, the target region must remain clearly central to the lunar visualization.

## 4.5 Hover delay

Introduce a short hover delay to avoid excessive movement when the cursor quickly passes across several cards.

Suggested initial range:

0.10–0.18 seconds.

The timing must remain responsive.

Clicking a site should immediately commit the preview and selection, without waiting for an unnecessary hover delay.

## 4.6 Default state

Before a site is selected, display an attractive overview of the Moon.

Subtle ambient movement is acceptable, but it should be very slow.

When the player begins interacting with site cards, user-driven camera targeting should take priority.

Do not allow idle animation to fight the preview camera.

---

# 5. LANDING-SITE MARKERS AND HIGHLIGHTING

Every Apollo landing site should have a corresponding marker positioned on the real 3D Moon.

## 5.1 Marker requirements

Create visible location indicators that follow the surface.

Markers may include:

- A small stylized beacon.
- A circular selection ring.
- A glowing dot.
- A site identifier.
- A subtle animated pulse.
- A projected highlight region.

The markers should be visually appealing but not so large that they obscure the lunar terrain.

## 5.2 Selection states

Use distinct states:

**Inactive**

- Small, low-intensity indicator.

**Hovered**

- Brighter marker.
- Smooth pulsation.
- Appropriate contextual details.
- Camera begins moving toward the site.

**Selected**

- Persistent highlighted state.
- Distinct visual treatment.
- Confirmation feedback.

Hovering another site should not erase the committed selection.

## 5.3 Correct visibility

Markers must not appear through the Moon.

If a marker is behind the visible sphere, it should be occluded or hidden appropriately.

If implementing 2D labels projected from 3D positions, check camera-facing visibility and actual surface occlusion.

Use Godot's appropriate camera projection methods.

Do not rely only on whether a marker is behind the camera; it may still be hidden by the Moon itself.

## 5.4 Selection visualization

When the player chooses a site, the camera should settle and the corresponding location should be clearly marked as the selected mission destination.

A subtle confirmation animation could include:

- A selection pulse.
- A locator ring closing around the marker.
- A short telemetry-style label reveal.
- A brief highlight sweep.

Avoid large explosions, dramatic flashes or unnecessary effects.

The visual language should remain scientific and arcade-like.

---

# 6. SCIENCE PLANNER SCREEN LAYOUT

The Science Planner must look like a cohesive 3D game screen rather than an online catalog.

Use the following conceptual composition:

```text
┌──────────────────────────────────────────────────┐
│ SCIENCE PLANNING      BUDGET      MISSION DATE    │
├────────────────────────────────┬─────────────────┤
│                                │                 │
│                                │ SITE DETAILS    │
│       STYLIZED 3D MOON         │                 │
│                                │ SCIENCE VALUE   │
│      CAMERA FOCUSES ON         │ LANDING RISK    │
│       HOVERED SITE             │ EXTRA Δv        │
│                                │                 │
│                                │ SELECTED SITE   │
├────────────────────────────────┴─────────────────┤
│  [A11] [A12] [A14] [A15] [A16] [A17]             │
│                                                  │
│  SELECT SITE                  CONTINUE           │
└──────────────────────────────────────────────────┘
```

This is an initial layout proposal, not a pixel-perfect requirement.

Refine proportions to create the best visual composition.

The 3D Moon should occupy the majority of the available screen space.

Keep technical information readily accessible.

Avoid excessive opaque panels over the lunar visualization.

## 6.1 Apollo site cards

Create six animated site cards.

Each card should include concise information such as:

- Apollo mission.
- Landing-site name.
- Science value.
- Risk category.
- Selection state.

Use existing project data.

Apply the shared button/card animation system developed in Phase 1.

Hovering a card triggers the camera preview.

Selecting a card confirms the active site.

## 6.2 Information inspector

The contextual information panel should update when a site is previewed.

Show:

- Mission association.
- Site name.
- Site description.
- Coordinates where useful.
- Scientific value.
- Landing risk.
- Relevant delta-v requirement.
- Additional educational information through the existing Read More system.

Do not remove the existing detailed educational explanations.

The default panel should explain the purpose of site selection rather than displaying meaningless placeholders.

## 6.3 Visual feedback

The UI should react to state changes.

Examples:

- Site name smoothly changes.
- Risk indicator changes color.
- Scientific value animates to the new display value.
- The selected card receives a confirmation animation.
- The Moon marker changes state.
- The camera settles before or during the final confirmation.

Avoid overwhelming motion.

---

# 7. SCIENTIFIC INSTRUMENT SELECTION — SECOND HALF OF THE SCREEN

The current Science Planner also lets the player select scientific instruments.

This functionality must be preserved.

The instrument selection should feel like another phase of the same lunar research interface.

**Do not abruptly replace the 3D environment with a completely unrelated catalog screen.**

## 7.1 Transition from sites to equipment

Once a landing site is selected, transition into scientific instrument selection.

The Moon should remain visible.

The camera may adjust its composition to accommodate the new controls.

The selected landing region should remain identifiable.

Possible transition:

1. The selected marker locks into position.
2. The site cards retract or transform.
3. Instrument cards slide into view.
4. A scientific payload preview appears.
5. The technical dashboard changes to payload information.

Use the shared UI motion system.

## 7.2 Scientific instrument cards

Display all existing instrument options from `Campaign.instrument_options()`.

Retain:

- Name.
- Description.
- Mass.
- Power consumption.
- Cost.
- Science value.
- Existing selection restrictions.
- Existing educational details.

Use polished cards with consistent illustrations or stylized equipment previews.

The player should be able to compare instruments efficiently.

Avoid showing fewer options than the original game.

## 7.3 Instrument visualizations

Where feasible, provide simple stylized 3D or illustrated representations of instruments.

Potential examples:

- Seismometer.
- Magnetometer.
- Solar-wind experiment.
- Heat-flow experiment.
- Reflector.
- Sample collection equipment.
- Rover.

Use the actual instrument list in the project as the source of truth.

Do not invent new gameplay equipment.

Instruments may appear in a dedicated preview area or staging platform.

They do not need to be physically placed across the Moon's surface unless that behavior can be implemented coherently.

## 7.4 Selected payload preview

When the player selects an instrument, provide satisfying visual feedback.

For example:

- The equipment preview activates.
- A small object or card moves into the payload tray.
- The instrument is marked as installed.
- The numerical totals update with smooth animations.

When an instrument is deselected, reverse the visual state.

Keep all animations synchronized with the real selection state.

## 7.5 Payload calculations

Retain the existing calculations and constraints.

Values include:

- Total payload mass.
- Total power consumption.
- Total cost.
- Total science value.
- Available budget.
- Any existing restrictions.

Use `Campaign.plan_totals()` or the existing appropriate calculation methods.

Do not duplicate their formulas in UI scripts.

Animated numbers are only presentation.

The underlying game state remains authoritative.

## 7.6 Confirmation

Preserve the existing confirmation process.

Do not prematurely call `Campaign.set_science_plan()` during site hovering, card preview or temporary instrument selection.

Only commit the campaign decision at the appropriate confirmation point.

Ensure returning between the site and instrument steps does not corrupt state or incorrectly charge the player's budget.

---

# 8. CRT AND UI INTEGRATION

Phases 1 and 2 already introduced:

- CRT curvature.
- Scanlines.
- Glow.
- Chromatic aberration.
- Configurable CRT settings.
- Mouse-responsive screen movement.
- Improved display modes.
- Animated interface components.

These must all continue working.

The new 3D scene should render underneath the established UI and CRT presentation.

## 8.1 Rendering architecture

Inspect the existing Phase 2 headquarters implementation.

Reuse compatible rendering techniques and components where possible.

A suitable implementation could use a `SubViewport` containing a 3D Moon scene, with 2D interface controls layered above it.

However, adapt this to the actual project architecture.

Avoid redundant global viewports or duplicate CRT effects.

## 8.2 Mouse interaction

The Phase 2 dynamic CRT movement introduces a transformed display.

Ensure hovering, clicking, card selection and any 3D marker interaction remain accurate.

Do not introduce competing mouse-coordinate systems.

If 3D picking is implemented, correctly account for the scene viewport and any outer display transformation.

The player must not experience inaccurate hover targets or delayed clicks.

## 8.3 Motion compatibility

The Science Planner camera animation must remain separate from the global CRT mouse-parallax effect.

The camera should orbit because the user previews a landing site.

The CRT image should drift subtly because the user moves the pointer.

These are two distinct systems.

Do not inadvertently make the Moon spin or the 3D camera move continuously with every cursor movement.

---

# 9. GODOT IMPLEMENTATION ARCHITECTURE

Implement the new Science Planner with a maintainable structure.

A possible scene organization:

```text
SciencePlanner
├── LunarViewportContainer
│   └── LunarSubViewport
│       └── LunarScene3D
│           ├── WorldEnvironment
│           ├── SunLight
│           ├── MoonRoot
│           │   ├── MoonMesh
│           │   └── LandingSiteMarkers
│           ├── OrbitCameraRig
│           │   └── Camera3D
│           └── SpaceBackground
│
├── SciencePlannerUI
│   ├── Header
│   ├── MissionStatus
│   ├── SiteSelectionCards
│   ├── SiteInformationPanel
│   ├── InstrumentSelectionCards
│   ├── PayloadTotals
│   └── NavigationControls
│
└── SciencePlannerController
```

This is conceptual. Adapt it to the actual scene structure.

Preferred responsibilities:

**LunarScene3D**

- Moon rendering.
- Lighting.
- Markers.
- Visual environmental effects.

**OrbitCameraController**

- Camera targeting.
- Coordinate conversion.
- Smooth interpolation.
- Camera framing.
- Transition cancellation.

**SciencePlannerController**

- Site hover state.
- Site selection state.
- Instrument selection state.
- Existing campaign integration.
- UI/view synchronization.

**SciencePlannerUI**

- Cards.
- Buttons.
- Information display.
- Read More.
- Totals and feedback.

Do not create unnecessary duplicate state.

Keep the existing campaign model authoritative.

---

# 10. PERFORMANCE REQUIREMENTS

The Science Planner must remain smooth and responsive.

Target 60 FPS on reasonably capable Windows hardware at 1920×1080, with a usable experience on lower-end systems.

Avoid:

- Excessively dense Moon meshes.
- Huge uncompressed textures.
- Dozens of unnecessary real-time lights.
- Expensive continuous mesh rebuilding.
- Excessive particle counts.
- Repeated resource loading during card hover.
- Unnecessary shader passes.
- Multiple rendering loops doing the same work.

Cache resources where appropriate.

Use efficient marker representations.

Do not continuously recalculate expensive static location data.

Test rapid switching between sites.

If necessary, introduce quality settings, but prioritize a well-optimized baseline.

---

# 11. VISUAL QUALITY REQUIREMENTS

This phase must produce a meaningful visual improvement, not just a technically working rotating sphere.

The following are important:

**The Moon must look attractive.**

Use coherent surface materials, recognizable terrain, appealing illumination and strong scene composition.

**Camera animation must feel satisfying.**

It should accelerate, travel and settle smoothly.

**The interface must feel physical.**

Use existing bouncy cards and panels with deliberate motion.

**Every site must feel discoverable.**

Camera movement and markers should clearly show where a mission is being planned.

**Instrument selection must feel connected to the destination.**

Do not abruptly switch to an unrelated flat interface.

**The screen must fit our existing aesthetic.**

Do not introduce photorealistic materials or unrelated UI styles.

If initial geometry is only a rough prototype, continue refining it before calling the phase complete.

Do not pass off primitive placeholders as final visuals.

---

# 12. IMPLEMENTATION ORDER

Implement the phase incrementally.

## Step A — Audit and preparation

Inspect:

- Updated Science Planner files.
- Existing campaign and data structures.
- Phase 2 viewport architecture.
- Shared UI animations.
- Current CRT compositing.
- Existing Read More system.

Identify which original gameplay behaviors must be preserved.

Verify that the game still runs before modifying the screen.

## Step B — 3D Moon prototype

Create:

- Moon mesh.
- Material.
- Lighting.
- Space background.
- Camera.
- Initial composition.

Make the Moon visually appealing.

Verify the scene renders correctly inside the existing game.

## Step C — Coordinate system and markers

Implement:

- Geographic coordinate conversion.
- All six Apollo landing-site markers.
- Correct texture alignment.
- Marker visibility/occlusion.
- Hover/selected visual states.

Verify the locations are correct.

## Step D — Orbital camera controller

Implement:

- Site-based camera targets.
- Smooth spherical interpolation.
- Hover delay.
- Cancellation/re-targeting.
- Appropriate framing.
- Default camera position.

Test every Apollo landing site.

## Step E — Landing-site interface

Implement:

- Site selection cards.
- Information panel.
- Hover animation.
- Camera synchronization.
- Selection feedback.
- Existing educational explanations.

Preserve the original site selection behavior.

## Step F — Instrument selection

Implement:

- Smooth transition between planning steps.
- Instrument cards.
- Equipment visualizations.
- Selected payload preview.
- Animated numerical totals.
- Existing selection and confirmation logic.

## Step G — Integration and polish

Verify:

- Correct campaign state.
- CRT compatibility.
- UI input alignment.
- Display scaling.
- Navigation.
- Scene transitions.
- Performance.
- No Godot errors.

Refine materials, lighting and motion.

---

# 13. TESTING CHECKLIST

Do not declare Phase 3 complete until the following checks have been performed or explicitly identified as requiring manual validation.

### 3D environment

- [ ] Moon is a genuine 3D sphere.
- [ ] Surface is visually detailed and stylized.
- [ ] Lighting looks consistent.
- [ ] Background renders correctly.
- [ ] Moon remains visible at different display resolutions.

### Camera

- [ ] Camera orbits around the Moon.
- [ ] Hovering Apollo 11 focuses its site.
- [ ] Hovering Apollo 12 focuses its site.
- [ ] Hovering Apollo 14 focuses its site.
- [ ] Hovering Apollo 15 focuses its site.
- [ ] Hovering Apollo 16 focuses its site.
- [ ] Hovering Apollo 17 focuses its site.
- [ ] Camera transitions are smooth.
- [ ] Rapid hover changes do not cause glitches.
- [ ] Camera never clips through the Moon.
- [ ] The geographic orientation is correct.

### Site selection

- [ ] All six locations have markers.
- [ ] Markers align with their real lunar coordinates.
- [ ] Hidden markers do not show through the Moon.
- [ ] Hover states work.
- [ ] Selected states persist.
- [ ] Site information is accurate.
- [ ] Read More content remains available.

### Instruments

- [ ] Every original instrument option is accessible.
- [ ] Cards animate appropriately.
- [ ] Instrument preview works.
- [ ] Selection/deselection works.
- [ ] Mass totals remain correct.
- [ ] Power totals remain correct.
- [ ] Costs remain correct.
- [ ] Science value remains correct.
- [ ] Existing constraints are preserved.

### Integration

- [ ] CRT effects still work.
- [ ] Dynamic screen movement still works.
- [ ] Mouse clicks remain accurate.
- [ ] Fullscreen modes work.
- [ ] Existing navigation remains functional.
- [ ] Stage progression is unchanged.
- [ ] No critical errors appear.
- [ ] No significant performance regression occurs.

---

# 14. IMPORTANT DEVELOPMENT RESTRICTIONS

Do not:

- Rewrite campaign calculations.
- Modify scientific data unnecessarily.
- Remove existing gameplay options.
- Change mission outcomes.
- Replace actual Moon coordinate mapping with arbitrary points.
- Use a flat 2D Moon as the final implementation.
- Introduce a free-roaming player camera.
- Spin the Moon instead of orbiting the camera.
- Remove detailed scientific explanations.
- Break Phase 1 or Phase 2 systems.
- Copy proprietary assets from other games.
- Silently introduce unrelated gameplay features.
- Push changes to GitHub without authorization.
- Start Phase 4 before Phase 3 has been manually reviewed.

Make focused, testable changes.

Prefer modular scripts.

Maintain compatibility with the installed Godot 4.7 editor.

---

# 15. FINAL DELIVERABLES

After completing Phase 3, provide:

1. A summary of implemented features.
2. A list of created and modified files.
3. Explanation of the Moon rendering architecture.
4. Explanation of the geographic coordinate mapping.
5. Explanation of camera interpolation and targeting.
6. Description of the updated landing-site interface.
7. Description of instrument selection visualization.
8. Confirmation of preserved gameplay behavior.
9. Test results.
10. Any visual limitations, remaining placeholders or known issues.
11. Instructions for manually testing the Science Planner in Godot.

Provide clear distinctions between completed, tested and unverified features.

If useful, include screenshots of the actual rendered game.

Do not claim visual quality has been verified unless you have actually rendered and inspected the results.

---

# 16. FINAL DIRECTIVE

Our objective is to make lunar science planning feel like an interactive exploration experience.

The player should feel as though they are operating a stylized lunar observation system, selecting real Apollo landing sites and assembling the scientific mission payload.

Hovering over Apollo 15 should make the camera gracefully orbit toward Hadley–Apennine.

Hovering over Apollo 17 should shift the observation toward Taurus–Littrow.

Selecting a site should make that destination feel physically real.

Selecting an instrument should feel like adding something tangible to the mission.

All interactions should retain the satisfying arcade-style animations established in previous phases.

The Moon must feel like a beautiful, interactive 3D game environment rather than a decorative background.

**Preserve the original scientific gameplay. Transform its visual experience.**

BEGIN PHASE 3 IMPLEMENTATION NOW.

DO NOT PROCEED TO PHASE 4 UNTIL PHASE 3 IS REVIEWED.
