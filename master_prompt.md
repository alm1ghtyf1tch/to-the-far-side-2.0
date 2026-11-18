# MASTER DEVELOPMENT PROMPT — TO THE FAR SIDE: NEO VISUAL OVERHAUL

## 0. YOUR ROLE AND OVERALL MISSION

You are the lead game developer, technical artist, UI/UX engineer, and visual systems architect for **To the Far Side**, an existing lunar mission design and strategy game developed in Godot 4.7 with GDScript.

Your task is to transform the existing game into a visually impressive, cohesive, highly polished, stylized **2.5D arcade space-management experience**, while preserving the original gameplay concept, simulation logic, educational content, campaign progression, and player decisions.

The current game was originally created for the NASA Space Apps Challenge 2026 by Team Pharsyde.

You have already completed an initial inspection of the repository. Use that knowledge, but verify relevant files before modifying them.

**THIS IS A VISUAL AND PRESENTATIONAL OVERHAUL, NOT A GAMEPLAY REWRITE.**

The target quality is that of a polished indie game rather than a hackathon prototype.

Our main inspirations are:

- **Balatro:** Tactile, springy interfaces, satisfying buttons, animated cards, CRT rendering, playful transitions, and excellent visual feedback.
- **R.E.P.O.:** Stylized, simplified 3D geometry, expressive environments, low-poly visual identity, lighting, and physical-feeling objects.
- **Lethal Company:** Retro-industrial science-fiction atmosphere, low-poly environments, utilitarian spacecraft design, and distinctive camera/rendering aesthetics.

These games are references for particular design principles. Do not copy their proprietary assets, logos, interface layouts, or distinctive artwork.

The result must feel like an original game with a recognizable visual identity.

---

# 1. FIRST PRINCIPLE — PRESERVE THE EXISTING GAME

Before changing any system, understand its current responsibilities and dependencies.

The repository already contains substantial functional game code.

Important existing systems include:

- `project.godot`
- `autoload/campaign.gd`
- `autoload/flight.gd`
- `autoload/vehicle.gd`
- `autoload/operations.gd`
- `autoload/scene_router.gd`
- `autoload/game_settings.gd`
- `screens/main_menu/`
- `screens/hq/`
- `screens/engineering/`
- `screens/science/`
- `screens/science_plan/`
- `screens/operations/`
- `screens/board/`
- `screens/meeting/`
- `screens/flight/`
- `ui/`
- `data/`

The campaign contains 11 principal stages:

1. Government request
2. Trajectory and uncertainty analysis
3. Concept review
4. Science planning
5. Requirements review
6. Vehicle design
7. Design review
8. Operations planning
9. Flight readiness review
10. Mission flight
11. Final mission report

The existing game includes resource management, scientific calculations, rocket engineering, mission planning, formal reviews, risk analysis, interactive flight sequences, and mission outcomes.

The original campaign features a USD 60 billion programme budget, a July 20, 2033 deadline, and several possible endings.

### Non-negotiable preservation requirements

Do not alter:

- Campaign progression or stage ordering.
- Scientific calculations and numerical models.
- Rocket performance and delta-v calculations.
- Budget, schedule, power, mass, and risk calculations.
- Existing player choices or their consequences.
- Mission outcome determination.
- Mission objectives and success/failure rules.
- Existing educational information and scientific references.
- Existing state-management behavior.
- Landing and staging minigame mechanics unless compatibility changes are necessary.
- Existing narrative content without explicit approval.

Do not quietly replace simulation logic with simplified visual approximations.

Visual animations may illustrate the state of the simulation, but the simulation must remain authoritative.

Refactoring is permitted where necessary to integrate the new presentation system, provided functionality is preserved and verified.

Prefer using existing public state, methods, and signals rather than duplicating gameplay calculations.

**The new visuals must respond to the existing game, not redefine how the game works.**

---

# 2. GLOBAL ARTISTIC DIRECTION

## 2.1 Primary visual identity

The target art direction is:

**RETRO-FUTURISTIC / STYLIZED LOW-POLY / 2.5D / ARCADE / CRT / SPACE-INDUSTRIAL**

The game should look intentionally stylized rather than photorealistic.

Avoid the following:

- Photorealistic NASA simulator aesthetics.
- Generic Unreal Engine-style realism.
- Excessively detailed mechanical models.
- Overly glossy futuristic holographic interfaces.
- Flat corporate dashboards.
- Generic web application layouts.
- Inconsistent art styles between scenes.
- Unnecessary visual clutter.
- Excessive bloom that compromises readability.

Instead, favor:

- Bold recognizable silhouettes.
- Low-poly and moderately simplified geometry.
- Stylized aerospace machinery.
- Strong but controlled lighting.
- Distinctive shadows and color contrast.
- Physical-looking interface elements.
- Arcade-inspired animation.
- Simplified, attractive materials.
- Carefully authored camera compositions.
- Dynamic environments with subtle ambient movement.

The game should feel tactile, playful, mysterious, technically sophisticated, and atmospheric.

Think of a fictional space agency operating through an eccentric retro-futuristic computer system.

## 2.2 Color palette

Use the existing NASA-inspired visual identity as the starting point.

Suggested foundational colors:

- Deep space background: `#071629`
- Navy blue: `#0B3D91`
- Cyan telemetry accent: `#42B9E8`
- Warm amber / attention: `#F2B632`
- Off-white interface surface: `#F0F4F8`
- Warning red: `#DD361C`

These are reference colors, not a requirement to make every screen uniformly blue.

Additional colors may be introduced for environmental lighting, important states, and illustration.

Maintain contrast and consistency.

Use red primarily for danger, errors, and critical events. Use amber for warnings, selections, or notable technical information.

## 2.3 Typography

The existing repository includes IBM Plex and Saira fonts.

Prefer reusing these, unless a demonstrably better typography system is justified.

Use a clear hierarchy between:

- Large display headlines.
- Section headings.
- Technical labels.
- Numerical telemetry.
- Body text.
- Buttons.
- Tooltips.
- Mission notifications.

The interface may be stylized, but educational content and numerical information must remain easy to read.

## 2.4 Unified visual language

All screens must share recognizable design patterns.

Implement a reusable component system for:

- Buttons.
- Cards.
- Tabs.
- Progress bars.
- Status panels.
- Technical gauges.
- Tooltips.
- Modal windows.
- Confirmation dialogs.
- Alerts.
- Notifications.
- Mission event panels.
- Scene transitions.
- Hover states.
- Selection states.
- Focus states.

These should behave consistently across the entire game.

Do not create a different button style and animation implementation for each screen.

---

# 3. GLOBAL CRT RENDERING SYSTEM

This is one of the highest-priority features.

We want the entire game to feel as if it is displayed on an old convex CRT television or advanced retro computer monitor.

The CRT effect should be integrated into the overall rendering architecture.

## 3.1 Required visual effects

Implement a configurable fullscreen CRT shader with:

1. **Barrel distortion / convex screen curvature**

   The rendered image should appear subtly curved, like an old CRT display.

2. **Scanlines**

   Fine horizontal lines that contribute to the retro aesthetic.

3. **Subtle chromatic aberration**

   Slight RGB color separation, particularly toward the edges.

4. **Vignette**

   Darkening toward the screen edges to emphasize the curved-screen appearance.

5. **Subtle glow and color response**

   A soft display-like appearance, without excessive blur.

6. **Optional fine-grained noise or phosphor-style texture**

   Keep it subtle and avoid distracting animated noise.

7. **Optional extremely subtle display instability**

   This may be used during special events or emergencies, but should not constantly distort the screen.

## 3.2 Shader technical requirements

Use Godot's supported shader language and rendering systems.

Investigate the most appropriate architecture for applying CRT effects consistently across 2D UI and embedded 3D viewports.

A possible approach is a composed SubViewport rendered through a final fullscreen shader, but choose the solution that integrates most reliably with the existing project.

Important requirements:

- The effect must work consistently across scenes.
- It must preserve UI legibility.
- Buttons must remain aligned with pointer interactions despite distortion.
- Focus and hover states must remain accurate.
- UI text must not become excessively blurred.
- Avoid large performance overhead.
- Avoid unsupported shader functions or engine-version assumptions.

If distortion affects input coordinates, implement a proper correction or choose an input-safe rendering architecture. Do not leave a visually distorted interface with inaccurate hit targets.

## 3.3 CRT settings

Extend the existing settings system to include, where practical:

- CRT enabled/disabled.
- Screen curvature intensity.
- Scanline intensity.
- Chromatic aberration intensity.
- Glow intensity.
- Reduced-motion setting.

Settings should persist between launches.

Define sensible defaults that look appealing while remaining readable.

The final visual treatment should resemble a coherent display technology rather than a stack of unrelated filters.

---

# 4. GLOBAL UI ANIMATION AND INTERACTION SYSTEM

The second foundational feature is a system of highly satisfying, Balatro-inspired interactions.

The user must feel that menus, cards, buttons, and interface objects have weight and personality.

## 4.1 Buttons

Implement reusable animated buttons.

Desired behavior:

**Hover:**

- Slight scaling or elevation.
- Smooth visual transition.
- Optional subtle tilt.
- Color or brightness response.

**Press:**

- Quick compression.
- Satisfying rebound.
- Immediate visual acknowledgment.

**Release:**

- Controlled spring-like return to rest.

Use Godot tweens or another lightweight, maintainable approach.

Animations should not feel floaty or excessively slow.

## 4.2 Cards and selection elements

Cards should respond to interaction with:

- Slight positional movement.
- Controlled scale changes.
- Optional small rotation.
- Smooth selection animations.
- Clear active/inactive states.
- Strong visual confirmation when a choice is made.

Cards must remain easy to compare and read.

Animation should improve usability instead of obstructing it.

## 4.3 Panels and dashboards

Panels should have polished appearance and dismissal animations.

Possible behaviors:

- Slide into view.
- Subtle overshoot and settle.
- Fade with slight scale movement.
- Smooth resizing between states.
- Highlight newly updated content.

Avoid dramatic transitions for every small action.

## 4.4 Numerical feedback

When values change, animate them where beneficial.

Examples:

- Budget decreases.
- Remaining development time changes.
- Delta-v margin changes.
- Payload mass changes.
- Reliability indicators change.
- Science score updates.
- Mission objectives complete.

The displayed value must always converge exactly to the true underlying value.

Never change the actual numerical calculation to accommodate the animation.

## 4.5 Animation architecture

Create a centralized library or reusable helpers for common motion behaviors.

Use a consistent timing system.

Suggested initial ranges:

- Hover feedback: approximately 0.10–0.18 seconds.
- Button press: approximately 0.06–0.12 seconds.
- Card selection: approximately 0.18–0.32 seconds.
- Panel transitions: approximately 0.25–0.45 seconds.
- Major scene transitions: approximately 0.45–0.90 seconds.

These are starting points, not rigid rules.

Animations must be interruptible where appropriate and should not leave elements in invalid intermediate states.

Honor reduced-motion settings.

---

# 5. HEADQUARTERS — INTERACTIVE 2.5D DIORAMA

The headquarters should evolve from the existing illustrated multi-floor building into a detailed interactive 2.5D scene.

This is one of the game's defining visual features and must retain its recognizable departmental structure.

## 5.1 Artistic direction

Create a stylized low-poly space agency headquarters.

The building should resemble an attractive miniature diorama or interactive cutaway.

It should contain recognizable departments:

- Board of Directors.
- Engineering.
- Science.

Use simplified geometry, strong silhouettes, distinct room colors, stylized equipment, and attractive ambient lighting.

Do not create a realistic office complex.

## 5.2 Environmental details

Each department should have its own visual identity.

**Board of Directors:**

- Conference table.
- Large mission display.
- Project status screens.
- Formal but stylized furniture.
- Subtle ambient display animations.

**Engineering:**

- Rocket models and components.
- Mechanical equipment.
- Tools and workbenches.
- Animated monitors.
- Industrial lighting.

**Science:**

- Lunar maps.
- Scientific displays.
- Telescope or laboratory equipment.
- Instruments.
- Research screens.

Use simple geometry and restrained detail rather than high-poly assets.

## 5.3 Interaction

When a player hovers over a floor:

- The department becomes visually highlighted.
- Its lights or monitors may respond.
- A short label or preview appears.
- The scene reacts with a subtle animation.

When selected:

- Smoothly transition toward the chosen department.
- Open the existing corresponding stage interface.
- Preserve the existing stage access rules.

The environment should feel responsive.

## 5.4 Camera

Use a fixed, authored 2.5D camera for the main headquarters view.

Allow controlled camera transitions into selected areas.

Do not introduce unrestricted first-person movement or a free camera.

The game is a strategy/management experience, not a walking simulator.

## 5.5 Campaign progression

Where appropriate, add subtle visual changes reflecting programme progress.

For example:

- A growing rocket model in Engineering.
- Updated research displays in Science.
- Changing mission statuses in the Board room.

These should be derived from existing campaign state.

Avoid adding new progression mechanics.

---

# 6. SCIENCE PLANNER — INTERACTIVE ORBITING 3D MOON

This is a major visual feature.

Replace the primarily static selection presentation with a stylized 3D lunar visualization.

The goal is to allow players to explore landing sites through smooth camera movement around the Moon while retaining the existing scientific planning decisions.

## 6.1 Moon appearance

Create a visually attractive stylized 3D Moon.

Desired features:

- Clearly spherical geometry.
- Recognizable lunar terrain.
- Simplified craters and surface features.
- Distinct light and dark regions.
- Controlled shadows.
- Strong depth cues.
- Stylized lighting.
- Clear separation from the surrounding space background.

A moderately low-poly sphere or optimized spherical mesh is acceptable.

Use materials, textures and geometry intentionally.

Avoid a flat Moon image or excessively photorealistic surface.

The camera should make it feel like a tangible celestial body.

## 6.2 Camera movement

The camera should orbit around the Moon.

When the player hovers over a landing-site option, the camera smoothly rotates toward that location.

The selected or hovered landing site should become the focal point of the viewport.

Use the landing-site coordinates already stored in the project data.

Do not hardcode inaccurate coordinates or arbitrarily place markers.

The current project includes six Apollo landing locations.

Implement a proper conversion between latitude/longitude and positions on the lunar sphere.

Ensure the coordinate transformation agrees with the orientation of the Moon's texture or visual mapping.

## 6.3 Hover behavior

When hovering over a site:

1. Detect the newly previewed location.
2. Calculate the appropriate orbital camera target.
3. Smoothly interpolate toward that position.
4. Orient the camera toward the target area.
5. Highlight the corresponding surface marker.
6. Update the contextual information panel.

Avoid instantaneous jumps.

The camera should follow a clean, controlled orbit rather than pass through the Moon.

Use stable interpolation and handle angle wrapping correctly.

A short hover delay may be introduced to prevent rapid accidental transitions while moving across cards.

## 6.4 Landing-site visualization

Display a marker or region indicator on the Moon for the active site.

Possible elements:

- A small glowing marker.
- A projected selection circle.
- A location label.
- A subtle connection line to a UI panel.
- A stylized landing-site identifier.

A marker must disappear or become occluded correctly when positioned on the far side of the visible sphere.

Markers should not show through the Moon.

## 6.5 Science choices

Retain all existing landing-site and instrument options.

The interface should include Balatro-inspired cards or a compact interactive selection tray.

Each site card should clearly show:

- Site name.
- Apollo mission association.
- Scientific value.
- Landing risk.
- Relevant mission data.

When an option is hovered, update the Moon visualization.

When clicked, preserve the current selection.

The user's active selection should remain visually distinct from temporary hover previews.

## 6.6 Instrument selection

During scientific payload selection, retain the 3D environment.

Possible visual improvements:

- Stylized instrument models or illustrated previews.
- Payload cards.
- Small animated instrument demonstrations.
- Equipment arranged as physical objects.
- A contextual panel showing mass, power and cost.

Only introduce 3D equipment models when they add meaningful visual value.

Do not invent equipment specifications or modify payload calculations.

The screen should feel like a lunar mission laboratory, not an online shopping catalog.

## 6.7 Performance

Keep sphere complexity, shaders, markers and effects efficient.

Avoid unnecessarily high-resolution textures or expensive dynamic geometry.

The Moon scene should remain responsive while cards are hovered rapidly.

---

# 7. MISSION CONTROL — FIXED-CAMERA CINEMATIC SPACE SCENE

This is one of the most important features of the visual overhaul.

Read this section carefully.

**We do NOT want a freely moving cinematic camera or a full flight simulator.**

We want a stylized 2.5D open-space environment presented from ONE STATIC CAMERA PERSPECTIVE.

The scene must resemble a theatrical view of a rocket or spacecraft in space.

## 7.1 Scene composition

The screen has two principal areas:

**LEFT / CENTER:**
A large animated space scene.

**RIGHT:**
An interactive mission control dashboard.

The animated environment should occupy most of the screen.

It should feel like watching a stylized spacecraft perform mission operations in open space.

The right dashboard should present updates, choices, telemetry and emergency responses.

## 7.2 Main space environment

Create a 3D or 2.5D environment containing:

- A stylized rocket or spacecraft.
- The Earth visible in the background.
- Open space.
- A subtle star field.
- Appropriate lighting.
- Engine and thruster effects.
- Optional small particles.
- Spacecraft components that can animate.

Keep the overall visual language consistent with the headquarters and Science Planner.

Use low-poly/stylized models.

Do not aim for photorealistic spacecraft rendering.

## 7.3 Camera behavior — critical

The camera must be fixed.

It should NOT:

- Chase the rocket.
- Orbit around the rocket.
- Continuously zoom.
- Move around the solar system.
- Simulate a free-roaming camera.
- Frequently switch cinematic angles.

The rocket should animate within the composition while the camera stays stationary.

The background should remain compositionally stable.

Create the illusion of action using:

- Engine ignition.
- Exhaust particles.
- Mechanical movement.
- Stage separation.
- Thruster activation.
- Controlled spacecraft translation/rotation where necessary.
- Animated lighting.
- Particle effects.
- Subtle environmental changes.

The player is watching mission events from a consistent camera view.

## 7.4 Mission phases

The existing game includes multiple mission phases, from countdown through launch, lunar transfer, landing, return and re-entry.

Preserve the entire sequence.

The visual system should respond to each phase.

Possible animated events include:

**Launch preparation**

- Engine startup.
- Vehicle readiness indicators.
- Subtle vibration.
- Ignition lighting.

**Launch and ascent**

- Strong engine exhaust.
- Vehicle vibration.
- Booster or stage separation.
- Exhaust and particle changes.

**Earth orbit**

- Spacecraft shown against Earth.
- Small attitude adjustments.
- Stable orbital-operation animations.

**Trans-lunar injection**

- Engine burn.
- A clear change in engine effects.
- Telemetry updates.

**Lunar transfer**

- Spacecraft coasting.
- Occasional thruster activity.
- Mission updates in the dashboard.

**Lunar operations**

- Appropriate spacecraft configuration.
- Landing-related interactions.
- Visual state changes.

**Return and re-entry**

- Spacecraft or capsule state changes.
- Thermal effects where applicable.
- Parachute or recovery animations where relevant.

Some phases may require transitioning between different spacecraft visual configurations or carefully authored backgrounds.

However, preserve the single-camera composition principle rather than introducing a dynamic flight camera.

## 7.5 Right-side mission dashboard

The right dashboard is a core interactive component.

It must not look like an ordinary static web sidebar.

Use the shared animated UI system.

Display:

- Current mission phase.
- Latest events.
- Relevant telemetry.
- Status indicators.
- Warnings.
- Action choices.
- Confirmation controls.
- Mission progress where useful.

Normal updates should appear in a clean event feed.

When an important event occurs, the relevant decision panel should become prominent.

## 7.6 Emergency and decision interactions

When the existing game produces an event requiring a choice:

1. Visually emphasize the dashboard.
2. Display an event notification.
3. Animate the relevant decision card or control into view.
4. Present the exact existing gameplay options.
5. Allow the player to make the decision.
6. Confirm the action visually.
7. Communicate the result through the scene and event log.

For example, an engine-related event could cause the relevant engine visual and telemetry indicator to react.

The animation should reflect the actual outcome generated by the existing game.

Do not create artificial emergencies or new decision rules.

## 7.7 Connecting simulation state to animations

Investigate the existing `Flight` system, mission phase handling, event logs, decisions, and mission control scripts.

Create a clean presentation interface between simulation and rendering.

Prefer a dedicated visual controller responding to existing events/state.

Avoid inserting large amounts of rendering-specific logic into scientific calculations.

Where necessary, use signals or an adapter layer to communicate state changes.

**The mission simulation determines what happens. The visual controller determines how it is shown.**

## 7.8 Existing minigames

Preserve existing staging and landing gameplay.

Where possible, integrate their presentation into the new visual style.

Do not remove manual player interactions.

If a minigame needs its own focused view, make it feel like a deliberate mode of the same Mission Control interface rather than an unrelated game.

---

# 8. VEHICLE ASSEMBLY — STYLIZED ARCADE WORKSHOP

The exact visual direction of Vehicle Assembly has not yet been finalized.

Do not commit prematurely to an expensive or overly realistic reconstruction.

Explore a hybrid concept combining:

- Stylized rocket assembly.
- Low-poly rocket components.
- An arcade-inspired aerospace hangar.
- Balatro-like component selection cards.
- Animated installation and removal.
- Contextual technical information.
- Clear engineering performance indicators.

## 8.1 Main visual objective

The rocket must feel like an important physical game object.

Currently, the interface is information-dense.

The redesign should make the rocket visually central.

The player should experience the satisfaction of constructing a mission vehicle.

## 8.2 Potential interactions

Possible improvements include:

- Selecting a component highlights its corresponding rocket section.
- Installing a part animates it into position.
- Selecting engines changes the displayed rocket configuration.
- Changing upper stages visibly affects the vehicle.
- Selected equipment has a clear visual state.
- Technical metrics respond smoothly to changes.

Use the actual existing vehicle configuration and calculation results.

Do not change the engineering model.

## 8.3 Engineering UI

Maintain full access to important engineering values, including:

- Delta-v.
- Mass.
- Thrust-to-weight ratio.
- Power.
- Reliability or risk.
- Budget.
- Build schedule.
- Capacity constraints.

The new UI should reduce unnecessary visual competition between panels.

Information may be reorganized into contextual inspectors, expandable cards and compact gauges.

Do not hide essential data behind excessive interactions.

## 8.4 Implementation restriction

Before a major redesign of Vehicle Assembly, prepare two or three distinct visual/layout proposals.

Recommend one based on feasibility and consistency with the other scenes.

Treat the detailed layout as a design decision requiring review, because the final artistic direction for this screen is still open.

Continue implementing shared components independently of this decision.

---

# 9. REVIEWS, REPORTS, AND DOCUMENT SCREENS

These screens need to feel like part of the same retro-futuristic world.

The existing game includes formal engineering reviews, mission documentation and final mission analysis.

Do not remove their technical detail.

## 9.1 Formal reviews

Present review screens as stylized mission documents, technical briefings or agency computer interfaces.

Possible improvements:

- Animated document entrance.
- Strong visual hierarchy.
- Clear decision outcomes.
- Better metric visualization.
- Improved typography.
- Subtle stamps or authorization effects.
- Consistent navigation.

Avoid reducing these to generic popup dialogs.

## 9.2 Final mission report

The final report should feel like the conclusion of a significant mission.

Before the full technical report, introduce a visually compelling mission summary.

Potential elements:

- Mission outcome.
- Spacecraft or mission illustration.
- Completed objectives.
- Mission status.
- Budget usage.
- Timeline.
- Key events.
- Major decisions and their consequences.

The full report should remain accessible.

## 9.3 Success and failure presentation

Both success and failure need meaningful visual treatment.

For successful missions:

- Strong accomplishment feedback.
- Mission objective completion animations.
- Clear but restrained celebration.

For unsuccessful missions:

- Clear critical-event presentation.
- Relevant visual consequences.
- An informative explanation of the engineering failure.
- Respectful, technically grounded presentation.

Avoid superficial success/failure effects that obscure the actual learning outcome.

The original game's delayed consequences are central to its identity. Preserve and strengthen how they are communicated.

---

# 10. MAIN MENU AND GLOBAL NAVIGATION

The main menu should immediately communicate the game's new visual identity.

It should establish:

- Retro-futuristic atmosphere.
- CRT presentation.
- Tactile interactive elements.
- Stylized space visuals.
- Strong typography.
- Cohesive motion.

Retain the game's identity as **To the Far Side**.

Consider a stylized Earth–Moon scene, lunar backdrop, or subtle spacecraft animation.

Avoid overwhelming the menu with effects.

Ensure that:

- Play works as before.
- Settings work as before.
- Quit works as before.
- Existing navigation works.
- Scene routing remains compatible.
- Transitions are consistent.

Do not break the `SceneRouter` system while introducing animations.

---

# 11. TECHNICAL ARCHITECTURE

This overhaul must be engineered as a maintainable Godot project.

The original repository is mostly built around `Control` nodes and programmatic GDScript UI.

Several screens currently construct their own interfaces through code.

The new system will require 3D rendering, shader composition and reusable UI components.

Do not solve this by creating one enormous script or rewriting the project from scratch.

## 11.1 Separate logic and presentation

Maintain three logical layers:

**GAMEPLAY LAYER**

Existing campaign and simulation logic.

Responsible for:

- State.
- Decisions.
- Calculations.
- Outcomes.
- Progression.

**PRESENTATION LAYER**

New 3D/2.5D scenes, animations and visual controllers.

Responsible for:

- Environment visuals.
- Cameras.
- Models.
- Effects.
- Visual state transitions.

**INTERFACE LAYER**

Shared 2D UI and interaction components.

Responsible for:

- Cards.
- Buttons.
- Panels.
- HUD.
- Telemetry display.
- Decision controls.
- Notifications.

CRT compositing is applied as the final visual treatment where appropriate.

## 11.2 Suggested organization

Review and adapt the project structure where useful.

A possible organization is:

```text
res://
├── autoload/
│   └── existing gameplay systems
├── data/
│   └── existing game data
├── assets/
│   ├── models/
│   ├── materials/
│   ├── textures/
│   ├── fonts/
│   └── effects/
├── shaders/
│   ├── crt/
│   ├── environment/
│   └── ui/
├── systems/
│   ├── rendering/
│   ├── animation/
│   ├── effects/
│   └── presentation/
├── ui/
│   ├── components/
│   ├── themes/
│   └── transitions/
├── environments/
│   ├── headquarters/
│   ├── moon/
│   ├── mission_control/
│   └── assembly/
├── screens/
│   └── existing and revised game screens
└── tests/
```

This is an architectural suggestion, not an instruction to reorganize files unnecessarily.

Prefer the smallest reliable changes.

## 11.3 Godot-specific approach

Investigate:

- `SubViewport`
- `SubViewportContainer`
- `Camera3D`
- `AnimationPlayer`
- `Tween`
- `CanvasLayer`
- `Control`
- `ShaderMaterial`
- `WorldEnvironment`
- Godot themes
- Signals
- Appropriate 3D rendering settings

Use appropriate Godot 4.7 APIs.

Avoid outdated Godot 3 syntax.

Where useful, procedural meshes and primitive geometry may be used to prototype stylized environments.

Do not require Blender-generated models for every small object.

Custom models can be introduced later when necessary.

## 11.4 New assets

Reuse existing project assets when they fit.

When creating new assets:

- Follow one cohesive style.
- Keep polygon counts and textures reasonable.
- Use reusable materials.
- Keep import paths organized.
- Do not introduce broken external dependencies.
- Avoid unnecessary binary bloat.
- Do not download unlicensed assets.
- Do not use copyrighted assets from inspiration games.

If an important custom asset cannot be produced with the available tools, use a clearly identified temporary placeholder and document the required asset.

Do not claim a placeholder is a finished production asset.

---

# 12. VISUAL POLISH STANDARDS

The game should feel satisfying even during simple interactions.

Apply the following principles across the entire project.

## 12.1 Motion

- Consistent easing.
- Spring-like interaction.
- Smooth interruption and recovery.
- No unnecessary animation delays.
- Immediate confirmation of input.
- Intentional timing differences between minor and major actions.

## 12.2 Lighting

- Clear environmental focal points.
- Stylized industrial lighting.
- Controlled emissive elements.
- Warm/cool contrast where appropriate.
- Strong separation of important objects from their backgrounds.

## 12.3 Scene composition

- Recognizable primary focal point.
- Clear interactive regions.
- Limited competing visual elements.
- Effective use of negative space.
- Consistent UI margins and alignment.

## 12.4 Feedback

Every significant action should communicate its result visually.

Examples:

- Selecting a lunar site moves and highlights the Moon.
- Choosing a vehicle component changes the rocket presentation.
- Confirming a decision triggers an appropriate animation.
- Starting a mission changes the space scene state.
- Completing an objective updates the HUD.
- An emergency causes a clearly differentiated alert.

## 12.5 Readability

Visual effects must never make essential information difficult to read.

Prioritize:

- Contrast.
- Appropriate text size.
- Stable text during interactions.
- Color-independent state indicators.
- Clear button labels.
- Predictable navigation.

---

# 13. PERFORMANCE AND COMPATIBILITY

The game should remain accessible to ordinary Windows laptops and desktops.

Target:

- Smooth interaction at 1280×720.
- A polished presentation at 1920×1080.
- Ideally 60 FPS on reasonably capable hardware.
- Stable frame timing during transitions and animations.

Do not assume high-end gaming hardware.

Optimization considerations:

- Keep geometry reasonably lightweight.
- Avoid excessive transparent particle layers.
- Avoid unnecessary per-frame allocations.
- Cache reusable assets and resources.
- Avoid creating and destroying large node trees every frame.
- Minimize expensive fullscreen shader operations.
- Use suitable texture resolutions.
- Limit unnecessary real-time lighting.
- Avoid pathological redraw loops.

Introduce quality controls if needed.

The game must remain playable if certain visual effects are disabled.

---

# 14. DEVELOPMENT ROADMAP

Implement the overhaul in controlled phases.

Do not attempt to replace every screen in one enormous change.

## PHASE 0 — BASELINE AND SAFETY

Before implementation:

1. Confirm the existing project opens.
2. Identify the current working entry scene.
3. Record the existing file structure and important dependencies.
4. Check for existing errors.
5. Establish a baseline of current functionality.
6. Confirm the project is on a dedicated development branch.
7. Identify a minimal integration plan.

Do not overwrite original gameplay logic.

Do not perform a large unrelated refactor.

If the initial audit has already established these facts, reuse it and verify only what is needed.

**Output:** A concise baseline and implementation approach.

## PHASE 1 — VISUAL FOUNDATION

Implement:

1. Global CRT rendering system.
2. Configurable CRT settings.
3. Shared animation utilities.
4. Reusable animated buttons.
5. Reusable cards and panels.
6. Standardized typography and theme.
7. Basic scene transition improvements.
8. Reduced-motion behavior.

Use existing scenes to demonstrate these systems.

Do not redesign the full game yet.

**Acceptance criteria:**

- The game runs.
- CRT works across the target rendering composition.
- Pointer interactions remain accurate.
- Basic UI controls animate correctly.
- Settings persist.
- Disabling CRT does not break rendering.
- Existing navigation still works.

## PHASE 2 — MAIN MENU AND HEADQUARTERS

Implement:

1. Cohesive main menu presentation.
2. Stylized 2.5D headquarters.
3. Interactive department highlights.
4. Ambient environmental animations.
5. Authored camera transitions.
6. Integration with existing stage routing.

**Acceptance criteria:**

- All intended department interactions work.
- Camera transitions are reliable.
- Existing stages remain accessible.
- The environment responds appropriately to campaign state.
- No progression logic changes.

## PHASE 3 — SCIENCE PLANNER AND 3D MOON

Implement:

1. Stylized 3D Moon.
2. Dedicated lunar camera system.
3. Latitude/longitude coordinate mapping.
4. Landing-site markers.
5. Smooth camera targeting.
6. Hover-driven site previews.
7. Selection states.
8. Animated site information.
9. Science equipment card styling.
10. Existing choice integration.

**Acceptance criteria:**

- All six Apollo landing sites can be previewed.
- Camera rotation works correctly.
- Every marker is geographically consistent with its site data.
- Hovering different sites does not create camera glitches.
- Selecting sites produces correct campaign state changes.
- Existing payload calculations remain unchanged.

## PHASE 4 — MISSION CONTROL

Implement:

1. Fixed-camera space environment.
2. Stylized spacecraft/rocket model.
3. Earth and star background.
4. Animated engine effects.
5. Stage separation effects.
6. Phase-based spacecraft animations.
7. Right-side dashboard.
8. Event cards and updates.
9. Existing decision integration.
10. Mission status feedback.
11. Visual integration of existing landing and staging minigames.

**Acceptance criteria:**

- Camera remains fixed in the intended scene.
- Rocket animation responds to the correct flight phases.
- Event dashboard reflects actual simulation events.
- Existing decisions remain functional.
- Mission outcomes are unchanged.
- Full flight progression reaches the report correctly.

## PHASE 5 — ENGINEERING / VEHICLE ASSEMBLY

First produce a small set of visual layout proposals.

Once the design direction is agreed:

1. Implement the selected stylized assembly environment.
2. Make the rocket visually central.
3. Add component highlighting.
4. Add installation animations.
5. Improve information panels.
6. Integrate engineering metrics.
7. Preserve every existing selection and calculation.

**Acceptance criteria:**

- All original vehicle components remain selectable.
- Rocket presentation reflects the chosen configuration.
- Engineering values remain correct.
- Existing validation and progression remain intact.

## PHASE 6 — REVIEWS AND FINAL REPORT

Implement:

1. Updated board review styling.
2. Updated scientific report presentation.
3. Cohesive technical documents.
4. Animated mission result summary.
5. Better mission event visualization.
6. Consistent victory/failure presentation.
7. Full technical report accessibility.

**Acceptance criteria:**

- Every original report remains complete.
- Decisions and consequences remain traceable.
- All data remains accurate.
- Successful and failed missions are presented coherently.

## PHASE 7 — FINAL POLISH

Complete:

1. Animation consistency pass.
2. Visual readability pass.
3. Performance profiling.
4. CRT tuning.
5. Camera transition refinement.
6. UI interaction testing.
7. Asset cleanup.
8. Regression testing.
9. Documentation.
10. Packaging and export validation.

---

# 15. TESTING AND REGRESSION REQUIREMENTS

Do not assume that code is correct because it compiles.

After each phase, verify functionality.

Use available Godot command-line tools where appropriate.

Perform editor import or parsing checks and runnable smoke tests when possible.

If a graphical test cannot be performed in the current environment, explicitly report that limitation.

Never claim that a scene was visually verified unless it was actually rendered and inspected.

Important regression targets:

- Main menu opens.
- New campaign starts.
- Headquarters navigation works.
- All 11 stages remain reachable.
- Research budgeting works.
- Science planning works.
- Landing-site selection works.
- Vehicle assembly works.
- Engineering calculations remain correct.
- Operations choices work.
- Formal reviews work.
- Mission Control progresses correctly.
- Landing and staging interactions work.
- Mission outcomes are generated correctly.
- Final report opens.
- Settings persist.
- CRT enable/disable works.
- No critical errors occur during stage transitions.

Test more than one campaign configuration where feasible, including a successful mission and at least one failure outcome.

Preserve the existing scientific validation claims and data. Do not invent new validation results.

---

# 16. VERSION CONTROL AND SAFETY

Treat the existing repository as valuable working software.

Before destructive operations:

- Inspect dependent files.
- Preserve original behavior.
- Avoid deleting assets that may still be referenced.
- Keep changes focused.
- Check the current Git status.
- Use the development branch rather than modifying the stable baseline.

Make clear, descriptive commits after verified milestones when authorized.

Do not rewrite Git history, force-push, delete branches, publish builds, or modify remote repository settings without explicit approval.

Avoid committing unnecessary generated files or temporary artifacts.

Do not include secrets or private local paths in committed files.

Retain appropriate attribution for the original project and third-party assets.

---

# 17. DOCUMENTATION REQUIREMENTS

Maintain a concise development document describing:

- New architecture.
- CRT system.
- UI animation components.
- 3D environment structure.
- Camera controllers.
- How simulation events drive visual effects.
- Asset organization.
- Performance considerations.
- Known issues.
- Remaining work.

Document how future developers can extend the visual system without rewriting existing components.

Do not produce excessive documentation at the expense of implementation.

Prioritize useful, accurate technical information.

---

# 18. HOW YOU SHOULD WORK

You are expected to actively implement the project, not simply describe what could be built.

Follow this process:

**Step 1 — Inspect**

Review relevant files, the previous audit, and the current implementation state.

**Step 2 — Plan**

For each phase, identify which scenes, scripts, resources and shaders must change.

Explain important architectural choices and risks briefly.

**Step 3 — Implement**

Write actual Godot scripts, shaders, scenes, resources and supporting assets.

Create reusable components where appropriate.

Do not stop after giving pseudocode.

**Step 4 — Test**

Run available validation and inspect errors.

Correct issues you discover.

**Step 5 — Review**

Summarize the implementation, changed files, completed features, and test results.

**Step 6 — Continue**

Move to the next agreed milestone after the current one is verified.

Avoid giant, untested changes.

Do not replace an existing working system just because a rewrite seems easier.

If an implementation approach fails, investigate the reason and make a focused correction.

Distinguish completed features from prototypes, placeholders, and unfinished work.

---

# 19. IMPLEMENTATION PRIORITIES

If time or resources are limited, prioritize in this order:

**P0 — Essential**

- Existing game must remain functional.
- Global CRT foundation.
- Consistent UI component system.
- Responsive controls and readable text.
- Stable architecture and state integration.

**P1 — Major visual transformation**

- 2.5D headquarters.
- 3D Moon selection.
- Fixed-camera Mission Control.
- Stylized spacecraft and environment animation.

**P2 — Additional visual quality**

- Vehicle Assembly redesign.
- Review/report polish.
- Advanced effects.
- Environmental detail.
- Fine animation tuning.

Do not spend excessive time creating tiny decorative effects before the foundational systems work.

---

# 20. DEFINITION OF DONE

The overhaul is successful when:

1. The game looks like a cohesive stylized indie title.
2. Every screen shares a consistent visual language.
3. CRT rendering contributes to the aesthetic without harming usability.
4. Buttons and cards feel tactile and responsive.
5. Headquarters feels like an interactive 2.5D environment.
6. Science Planner features a smooth, geographically grounded 3D Moon selector.
7. Mission Control features a compelling fixed-camera rocket animation and interactive dashboard.
8. Engineering interfaces feel playful and physical without sacrificing precision.
9. Reviews and reports have coherent, polished presentation.
10. Gameplay, calculations and outcomes remain consistent with the original implementation.
11. The project remains maintainable, testable and reasonably performant.

The target is not merely to make the current game look better.

**The target is to make the existing scientific strategy game feel like a complete, memorable and visually distinctive arcade experience.**

---

# 21. YOUR IMMEDIATE TASK

The initial repository inspection has already been completed.

Use that analysis as your starting point.

Begin by doing the following:

1. Confirm the current state of the project and development branch.
2. Identify how the existing 2D scene structure, shaders, UI controls and scene routing work.
3. Select the safest architecture for fullscreen CRT rendering and future 3D viewports.
4. Define the shared UI animation and theme system.
5. Prepare a brief implementation breakdown for Phase 1.
6. **Begin implementing Phase 1 immediately**, starting with the CRT rendering foundation and reusable animation system.
7. Validate the work before proceeding to later phases.

You may introduce well-justified technical improvements, but do not silently expand the gameplay scope or deviate from the defined artistic direction.

Use available project files as the source of truth for existing behavior.

When an aesthetic detail is unspecified, choose a sensible option consistent with the design brief.

For major unresolved artistic decisions, particularly Vehicle Assembly, present alternatives instead of committing prematurely.

**FINAL DIRECTIVE:**

Preserve the science. Preserve the strategy. Preserve the mission.

Transform the way the player experiences all three.

Build To the Far Side into a cohesive, stylized, CRT-filtered, 2.5D arcade lunar mission game.

START WITH PHASE 1.
