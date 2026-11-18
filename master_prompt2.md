# TO THE FAR SIDE — PHASE 2 IMPLEMENTATION

## Dynamic CRT Parallax, Display Settings, Main Menu & Interactive 2.5D Headquarters

You are continuing development of **To the Far Side**, an existing Godot 4.7 lunar mission strategy game.

Phase 1 of the visual overhaul has been completed and manually tested.

Your task is to implement **Phase 2**, with two additional improvements requested after Phase 1 testing.

This is a real implementation task. Modify the actual project, create scenes, scripts, materials and shaders where necessary, and test the results.

Do not restart or rewrite Phase 1.

---

## 1. Phase 1 status — preserve everything that works

The following features have already been manually verified:

- Global CRT curvature works well.
- Scanlines, glow and chromatic aberration are functioning.
- CRT configuration settings work correctly.
- Settings persist successfully.
- Main menu button hover, press and rebound animations feel satisfying.
- Pointer interactions align correctly with displayed buttons.
- Main menu navigation works.
- Game scene navigation works.
- No Godot errors have been observed.
- Original gameplay and calculations remain unaffected.

The current CRT system is approved.

**Do not replace or substantially rewrite it unless required to add the new effect safely.**

The existing UI animation system is also approved.

Other gameplay screens do not yet use all shared animated components. This is acceptable because those screens will be redesigned in later phases.

Our current priorities are:

1. Dynamic mouse-responsive CRT image movement.
2. Proper fullscreen and windowed display options.
3. Improved main menu presentation.
4. Interactive stylized 2.5D headquarters.

---

# 2. NEW FEATURE — DYNAMIC CRT SCREEN PARALLAX

This feature has been specifically requested.

We want the entire game image to respond subtly to mouse movement, creating the sensation of a living, floating, slightly oversized CRT image.

## 2.1 Visual behavior

Imagine the game is being displayed on a curved CRT monitor.

The image is slightly enlarged so that a small portion extends beyond the visible screen boundaries.

When the player moves the mouse toward the right, the displayed game image shifts slightly toward the right.

When the mouse moves toward the left, the image shifts toward the left.

The same behavior applies vertically.

The movement must be:

- Smooth.
- Subtle.
- Continuous.
- Responsive.
- Slightly inertial.
- Non-distracting.

It should feel like the screen gently follows the player's pointer.

This must be **positive-direction movement**: the visible content moves in the SAME direction as the cursor, not opposite.

## 2.2 Zoom / overscan

The user described the effect as having approximately 95% of the image visible.

Interpret this as a small amount of intentional overscan.

A suitable initial implementation would enlarge the composed image by approximately:

`1.0 / 0.95 ≈ 1.0526`

This provides roughly 5% enlargement, leaving additional visual content beyond the visible screen boundaries.

The image should fill the viewport completely, including during maximum movement.

Never expose empty screen borders.

Do not implement a literal 0.95 display scale that creates unused margins around the screen.

## 2.3 Mouse-driven movement

Use the cursor's normalized position relative to the game viewport.

Suggested behavior:

- At the centre: neutral image position.
- Toward the right: image shifts right.
- Toward the left: image shifts left.
- Toward the top: image shifts upward.
- Toward the bottom: image shifts downward.

Movement strength should increase smoothly with distance from the centre.

Apply interpolation or spring-damped movement rather than instantly assigning the target offset.

Avoid overshooting beyond the safe overscan region.

Avoid feedback loops caused by recalculating movement using already-transformed cursor coordinates.

A reasonable starting strength is approximately 1–2% of the viewport dimensions at the edges, subject to safe cropping.

Expose the movement strength for tuning.

## 2.4 Important interaction requirement

**Mouse input must remain accurate.**

This is critical.

Because the displayed image will be enlarged and shifted, interactive objects may no longer visually align with their original input regions.

Investigate the current Phase 1 rendering and input architecture.

Choose an implementation that correctly maps physical mouse coordinates to the visible interactive content.

Possible approaches include:

- Correctly transforming input coordinates through the inverse visual transformation.
- Using an input-aware viewport or container architecture.
- Performing equivalent compositing in a system that preserves correct Control hit testing.

Use the safest approach supported by Godot 4.7.

Do not introduce a visual movement effect that causes missed clicks or inconsistent hovering.

Test buttons while the screen is shifted toward every corner.

Test rapid pointer movement and transitions between adjacent buttons.

## 2.5 Relationship to the CRT shader

The dynamic movement must work alongside:

- Existing barrel distortion.
- Scanlines.
- Glow.
- Chromatic aberration.
- Vignette.

Ideally, the movement should appear as the displayed image responding underneath a stable CRT glass treatment.

If an alternative ordering is technically preferable, explain the decision.

Avoid double curvature, unnecessary resampling, excessive blur or multiple expensive fullscreen passes.

## 2.6 Settings

Extend the existing settings interface with:

**Dynamic Screen Movement**

- Enabled / Disabled.

**Movement Strength**

- Adjustable slider.

Optional:

- Movement smoothing.

These settings must persist between sessions.

The default should provide a pleasant but subtle effect.

When reduced motion is enabled, this effect should automatically be disabled or reduced substantially.

Ensure that the mouse remains usable when the movement effect is switched off.

---

# 3. IMPROVED DISPLAY MODES AND RESOLUTION

Phase 1 testing revealed that playing in a 1280×720 window on a 1920×1080 monitor makes some UI text difficult to read.

Improve the existing display settings.

## 3.1 Required display modes

Support:

**Windowed**

- Ordinary resizable window.
- Selectable window resolution.

**Borderless Fullscreen**

- Display fills the monitor without window decorations.
- Prefer the desktop resolution.

**Exclusive Fullscreen**

- Where supported by Godot and the operating system.

Use Godot 4.7's appropriate DisplayServer window modes.

Do not implement fake fullscreen through manually scaling a small window.

## 3.2 Resolution settings

In windowed mode, allow appropriate resolution options including:

- 1280×720
- 1600×900
- 1920×1080

Only offer resolutions that are sensible for the available display, while accounting for desktop scaling and usable screen dimensions.

Allow normal resizing where practical.

In fullscreen modes, distinguish the actual display resolution from the game's internal viewport/rendering resolution.

## 3.3 UI scaling

The game should remain legible at 1920×1080.

Review the existing canvas stretch and viewport settings.

Ensure:

- Buttons remain an appropriate size.
- Text remains readable.
- Panels do not become disproportionately small.
- UI anchors behave correctly.
- No interface elements are clipped.
- CRT distortion does not make small text unreadable.
- Dynamic screen movement does not hide important controls.

If necessary, implement an adjustable UI scale.

Prefer adaptable layouts and consistent scaling rather than blindly increasing font sizes.

## 3.4 Settings integration

Preserve existing user settings.

Add display modes without breaking previous configuration files.

Persist the selected mode and relevant resolution.

Test switching between modes multiple times.

Ensure returning from fullscreen to windowed mode restores a usable window.

---

# 4. MAIN MENU — VISUAL REFINEMENT

The main menu already benefits from Phase 1's CRT and animation systems.

Keep those systems.

The goal is to establish a cohesive visual identity that leads naturally into the new headquarters.

## 4.1 Artistic direction

Use the project's agreed visual style:

**Retro-futuristic, stylized, low-poly, 2.5D, arcade, CRT-filtered.**

Inspirations:

- Balatro for animated UI and tactile controls.
- R.E.P.O. for stylized forms and playful 3D physicality.
- Lethal Company for retro-industrial sci-fi atmosphere.

Do not copy assets or exact interface designs from those games.

## 4.2 Menu composition

Preserve the title:

**TO THE FAR SIDE**

Retain recognizable branding and existing menu functionality.

Improve the presentation using:

- Stronger visual composition.
- Attractive space background.
- Subtle ambient animation.
- Deliberate typography.
- Controlled lighting and color.
- Clean animated buttons.
- Existing CRT presentation.

The current main menu's space background may be reused or enhanced rather than replaced unnecessarily.

The menu should feel atmospheric and polished without becoming visually busy.

## 4.3 Navigation

Preserve:

- Play.
- Settings.
- Quit.
- Existing navigation behavior.

Transitions between the main menu and headquarters should feel coherent.

Consider a brief stylized camera or screen transition, but do not create excessively long unskippable animations.

---

# 5. HEADQUARTERS — MAIN PHASE 2 FEATURE

The headquarters is the primary environmental task for this phase.

The existing headquarters is a 2D cutaway of a three-floor space agency building.

We want to transform it into a **stylized interactive 2.5D diorama**.

Not a photorealistic building.

Not a first-person environment.

Not a static 2D illustration.

We want an attractive miniature world with visible depth, interactive spaces and environmental animation.

## 5.1 Overall artistic direction

Create a fictional space-agency headquarters inspired by stylized low-poly games.

The building should feel:

- Miniature and toy-like.
- Detailed enough to be interesting.
- Recognizable as a space research institution.
- Slightly exaggerated in its proportions.
- Physically dimensional.
- Colorful but atmospheric.
- Easy to navigate.

Use simplified geometry and strong silhouettes.

Prefer good lighting, composition, materials and animation over high polygon counts.

## 5.2 Building structure

Keep the recognizable three departments:

1. Board of Directors.
2. Engineering.
3. Science.

Represent them as distinct visible sections of one building.

The player should understand the building's structure at a glance.

The environment may use:

- An isometric camera.
- An orthographic 3D camera.
- A carefully composed perspective camera.

Choose the option that best preserves a readable cutaway presentation.

A true 3D environment rendered through a fixed 2.5D camera is preferred.

Do not implement unnecessary player movement controls.

## 5.3 Board of Directors

Create a stylized room with:

- Conference table.
- Chairs.
- Main mission display.
- Wall-mounted technical screens.
- Agency decorations.
- Distinctive lighting.

Ambient animations may include:

- Changing display content.
- Slowly updating indicators.
- Subtle monitor glow.

The room should visually convey programme management and major mission decisions.

## 5.4 Engineering department

Create a stylized engineering workspace.

Possible assets:

- Small rocket prototype.
- Mechanical assembly equipment.
- Technical monitors.
- Workbenches.
- Tools.
- Support structures.
- Industrial lights.

Ambient animations may include:

- Rotating rocket model.
- Blinking equipment lights.
- Moving mechanical objects.
- Animated technical displays.

Avoid excessive moving machinery that distracts the player.

## 5.5 Science department

Create a recognizable lunar science workspace.

Possible assets:

- Lunar globe or moon projection.
- Scientific instruments.
- Computer displays.
- Research equipment.
- Laboratory furniture.
- Lunar surface imagery.

Ambient animations may include:

- Slowly rotating lunar model.
- Scientific visualizations.
- Blinking equipment.
- Gentle monitor lighting.

The science department should foreshadow the 3D Moon visualization planned for Phase 3.

## 5.6 Floor hover interactions

When the user hovers over a department:

- Highlight that department.
- Slightly emphasize its lighting.
- Show the department name.
- Display the relevant current mission task where appropriate.
- Apply a satisfying, subtle animation.
- Preserve clear interactive hit regions.

Possible effects include a gentle brightness increase, outlined room boundary, or slight scale emphasis.

Do not move the entire building dramatically when hovering.

## 5.7 Floor selection

When a player selects a department:

1. Confirm the selection visually.
2. Start a smooth authored camera transition toward the selected room.
3. Complete a coherent screen transition.
4. Open the existing relevant stage using the current routing system.

Use existing stage progression rules.

Do not allow players to bypass campaign restrictions.

The transition should feel like entering an actual room in the fictional building.

## 5.8 Camera behavior

The default headquarters camera should have a fixed, carefully designed viewpoint.

On department selection, the camera may:

- Move toward the selected floor.
- Change its framing.
- Slightly zoom.
- Smoothly settle before the scene transition.

The camera should not become freely controlled by the mouse.

The mouse-responsive CRT movement from Section 2 is a separate visual system and must not fight with the headquarters camera.

Keep camera animation and screen parallax independent.

## 5.9 Campaign-dependent environmental details

Where feasible, use existing campaign state to update the headquarters visually.

Examples:

- Engineering displays become more advanced later in development.
- Science displays reflect completed planning stages.
- Board screens show the current programme stage.
- Relevant information updates as the campaign progresses.

These should be visual reflections of existing state.

Do not create new gameplay systems or alter campaign progression.

## 5.10 Existing headquarters UI

Retain important information including:

- Current campaign stage.
- Date.
- Launch deadline.
- Remaining budget.
- Department objectives.
- Stage descriptions.
- Relevant programme information.

Redesign the way this information appears using shared animated panels and a cleaner hierarchy.

The building itself should remain the main visual focus.

Do not cover most of the environment with large opaque UI panels.

Keep information accessible without overwhelming the scene.

---

# 6. TECHNICAL ARCHITECTURE

Before implementing the headquarters, inspect:

- Existing headquarters scene and scripts.
- SceneRouter.
- Campaign state.
- Phase 1 CRT implementation.
- Phase 1 UI animation utilities.
- Existing settings implementation.

Build on the existing architecture.

Prefer creating an independent headquarters 3D environment with a presentation controller connected to existing state.

Possible architecture:

```text
HeadquartersScreen
├── HeadquartersViewport
│   └── Headquarters3D
│       ├── Camera3D
│       ├── Building
│       ├── BoardRoom
│       ├── EngineeringRoom
│       ├── ScienceRoom
│       ├── Lighting
│       └── EnvironmentAnimations
├── HeadquartersUI
│   ├── ProgrammeStatus
│   ├── DepartmentLabels
│   ├── MissionBrief
│   └── NavigationControls
└── VisualController
```

This is a conceptual structure. Adapt it to the actual Phase 1 project.

Use shared rendering and animation systems where possible.

Do not create redundant input handlers or conflicting global render layers.

The new headquarters should integrate naturally with the existing CRT composition.

---

# 7. PERFORMANCE AND QUALITY

Target smooth performance on normal Windows computers.

Avoid unnecessary high-poly models, expensive global illumination configurations, huge textures or excessive post-processing.

Prioritize:

- Lightweight low-poly assets.
- Reusable materials.
- Efficient viewport rendering.
- Controlled particle counts.
- Minimal unnecessary per-frame work.
- Reasonable texture sizes.
- Predictable memory usage.

Ensure the project remains stable at common 16:9 resolutions, particularly 1920×1080.

Visual polish must not compromise responsiveness.

---

# 8. IMPLEMENTATION ORDER

Work through Phase 2 in the following order.

### Step A — Dynamic CRT movement

Implement and test the mouse-responsive overscan effect.

Confirm that interactions remain aligned.

Add persistent movement settings.

### Step B — Display modes

Add windowed, borderless fullscreen and supported fullscreen behavior.

Test resolution changes, UI scaling and CRT compatibility.

### Step C — Main menu

Refine the existing main menu while preserving all functionality.

Integrate the dynamic CRT movement and display settings.

### Step D — Headquarters prototype

Create a genuine stylized 2.5D headquarters environment with a working camera and basic three-floor layout.

Use simple geometry initially to verify composition and interaction.

### Step E — Headquarters detailing

Add appropriate room furnishings, equipment, materials, lighting and ambient animation.

Make the scene look intentional and visually cohesive.

### Step F — Interactive integration

Implement floor hover effects, camera transitions, department navigation and campaign-state presentation.

### Step G — Validation and polish

Test the full flow:

Main Menu → Headquarters → Available Department → Headquarters.

Verify that the updated headquarters does not change gameplay behavior.

---

# 9. ACCEPTANCE CRITERIA

Phase 2 can be considered complete only when:

- [ ] Existing CRT visual effects still work.
- [ ] The new screen image moves subtly in the same direction as the mouse.
- [ ] The movement is smooth and never exposes empty borders.
- [ ] Pointer and button hit targets remain accurate.
- [ ] Dynamic movement settings persist.
- [ ] Fullscreen and windowed options function correctly.
- [ ] The main menu remains fully functional.
- [ ] Headquarters uses a coherent stylized 2.5D environment.
- [ ] All three departments are visually recognizable.
- [ ] Departments respond to hovering.
- [ ] Selecting a department initiates an attractive camera transition.
- [ ] Existing campaign restrictions and navigation are preserved.
- [ ] Existing game calculations remain unchanged.
- [ ] UI remains readable at 1920×1080.
- [ ] No critical Godot errors occur.
- [ ] The implementation remains compatible with later 3D Moon and Mission Control work.

Do not report a feature as complete if it is only a placeholder.

If a visual feature cannot be fully validated automatically, clearly mark it for manual inspection.

---

# 10. DEVELOPMENT RULES

Do not rewrite the original game.

Do not overwrite working Phase 1 systems unnecessarily.

Do not change campaign logic, scientific data or outcomes.

Do not introduce photorealistic assets.

Do not use proprietary artwork from the inspiration games.

Keep new architecture modular.

Use reusable animations and components.

Check Godot 4.7 compatibility.

Do not push changes to the remote repository without authorization.

Document any limitations honestly.

After implementation, provide:

1. A concise summary of what was implemented.
2. The important files created or changed.
3. The rendering and input architecture used.
4. Test results.
5. Remaining limitations or placeholder assets.
6. Instructions for manually previewing the new headquarters and CRT movement.

Do not proceed into Phase 3 until Phase 2 has been reviewed.

---

# FINAL DIRECTIVE

Our target is a stylized, arcade-like space programme management game with a unified CRT aesthetic.

The main menu should feel alive.

The entire screen should respond subtly to the mouse.

The headquarters should feel like an interactive miniature space agency, built with simplified 3D geometry and playful animation.

Every department should have its own personality while remaining part of one consistent visual world.

Preserve all original gameplay, scientific calculations and mission progression.

**Implement Phase 2 now. Start with the dynamic CRT screen movement, then display settings, followed by the main menu and interactive 2.5D headquarters.**
