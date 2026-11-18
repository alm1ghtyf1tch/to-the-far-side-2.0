# TO THE FAR SIDE — PHASE 4: CINEMATIC MISSION CONTROL

## Fixed-Camera 2.5D Spaceflight, Animated Spacecraft, Event-Driven Mission Dashboard & Interactive Flight Sequences

# 0. YOUR ROLE AND MISSION

You are continuing development of **To the Far Side**, a Godot 4.7/GDScript educational lunar mission strategy game undergoing a major visual overhaul.

You are acting as the project's lead game developer, technical artist, 3D environment developer, UI/UX engineer, animation programmer, and gameplay integration engineer.

**Phases 1, 2, and 3 are complete and have passed manual verification.**

Previously implemented systems include:

- Global CRT shader with curvature, scanlines, chromatic aberration, glow, and configurable settings.
- Smooth mouse-responsive screen movement with CRT overscan.
- Fullscreen, borderless fullscreen, and windowed display options.
- Shared animated UI components with tactile hover, press, and rebound effects.
- Improved main menu.
- Interactive stylized 2.5D headquarters.
- Interactive 3D Moon with an orbital camera, Apollo landing-site markers, and animated science planning.

These systems must remain functional.

Your task is now to implement **Phase 4: a visually compelling fixed-camera 2.5D Mission Control experience**.

This phase must transform the existing mission flight interface into a polished, stylized spaceflight scene in which the player watches their spacecraft carry out mission operations and responds to events through an interactive dashboard.

The experience should feel like an atmospheric arcade space simulator, while retaining the game's existing engineering depth.

**This is an implementation task. Write actual functioning code, scenes, shaders, models, materials, animations, and UI components. Do not stop after writing a proposal.**

---

# 1. ABSOLUTE REQUIREMENT — PRESERVE THE EXISTING GAMEPLAY

The purpose of Phase 4 is to replace and improve the presentation of Mission Control, not redesign its underlying mechanics.

The existing game already contains:

- Mission preparation.
- Flight outcome calculations.
- Launch and ascent events.
- Rocket staging.
- Earth orbit.
- Translunar injection.
- Lunar transfer.
- Lunar orbit insertion.
- Lunar landing.
- Lunar surface operations.
- Return trajectory.
- Re-entry and recovery.
- Mission decisions and emergency responses.
- Interactive staging and landing minigames.
- Failure scenarios.
- Multiple mission outcomes.
- Detailed mission reporting.

All these systems must remain intact.

**DO NOT MODIFY THE EXISTING PHYSICS, SCIENTIFIC FORMULAS, DECISION CONSEQUENCES, MISSION OUTCOME LOGIC, OR CAMPAIGN PROGRESSION.**

The existing simulation must remain the single source of truth.

The new rendering system should visualize what the game has already calculated.

Do not introduce fake gameplay events solely to make the animation more interesting.

Do not silently change the probabilities or consequences of failures.

Do not replace existing decisions with simpler alternatives.

Do not remove mission phases to make implementation easier.

Do not change the scientific assumptions or values contained in existing data files.

---

# 2. EXISTING CODEBASE — INSPECT BEFORE MODIFYING

Review the current implementation of the following files:

- `autoload/flight.gd`
- `autoload/campaign.gd`
- `autoload/vehicle.gd`
- `autoload/operations.gd`
- `autoload/scene_router.gd`
- `screens/flight/mission_control.gd`
- `screens/flight/mission_control.tscn`
- `screens/flight/flight_view.gd`
- `screens/flight/staging_game.gd`
- `screens/flight/landing_game.gd`
- `screens/flight/mission_report.gd`
- `data/trajectory.json`

Also inspect all Phase 1–3 components relevant to:

- CRT rendering.
- Global screen movement.
- Scene composition.
- Reusable UI controls.
- Animation helpers.
- 3D environment rendering.
- Camera systems.
- User settings.

The repository may have changed during the previous phases, so inspect the actual local files rather than assuming the original architecture is unchanged.

In particular, investigate the existing Mission Control methods responsible for:

- Beginning and finishing mission phases.
- Advancing mission events.
- Displaying event logs.
- Opening decision gates.
- Handling choices.
- Starting the staging minigame.
- Starting the landing minigame.
- Receiving minigame outcomes.
- Pausing and resuming.
- Skipping or advancing mission presentation.
- Completing the mission.
- Opening the final report.

Preserve these behavioral contracts.

**Do not rewrite `Flight.fly()` or related simulation functions merely to simplify rendering integration.**

---

# 3. ARTISTIC DIRECTION

Continue the visual identity established in the previous phases:

**STYLIZED LOW-POLY · RETRO-FUTURISTIC · 2.5D · ARCADE · CRT · SPACE-INDUSTRIAL**

Primary inspirations:

**Balatro**

- Springy panels.
- Tactile interactive controls.
- Animated cards.
- Strong selection feedback.
- Excellent information hierarchy.
- Expressive UI behavior.

**R.E.P.O.**

- Simplified physical geometry.
- Stylized 3D objects.
- Expressive lighting.
- Intentionally exaggerated visual proportions.
- Attractive low-poly environments.

**Lethal Company**

- Retro-industrial spacecraft design.
- Strong silhouettes.
- Atmospheric darkness.
- Utilitarian equipment.
- Intentionally imperfect retro rendering.

These are artistic references, not assets or designs to copy directly.

Avoid:

- Photorealism.
- Generic futuristic holographic dashboards.
- Overly complicated spaceship models.
- Unrealistic amounts of bloom.
- Hyper-detailed realistic NASA environments.
- Flat web application interfaces.
- Excessively tiny telemetry.
- Giant decorative effects that obscure gameplay.

The end result should look like a distinctive indie arcade spaceflight experience.

---

# 4. MOST IMPORTANT DESIGN DECISION — ONE FIXED CAMERA

Read this carefully.

**MISSION CONTROL MUST USE ONE STATIC CAMERA PERSPECTIVE.**

The camera must not chase the rocket, orbit around it, or dynamically fly through space.

The entire Mission Control experience should be built around a deliberately composed external observation view.

Imagine an arcade game's spaceflight scene:

- Deep space in the background.
- A large, stylized Earth visible behind the spacecraft.
- A detailed but low-poly rocket or spacecraft in the foreground.
- Animated engines, thrusters, mechanical components, and effects.
- An interactive dashboard occupying the right-hand side.

The spacecraft should remain the centre of attention.

## 4.1 Camera restrictions

The camera must NOT:

- Follow the rocket.
- Orbit around the rocket.
- Rotate in response to mouse movement.
- Continuously zoom.
- Track a spacecraft along a realistic trajectory.
- Fly between planets.
- Use a free camera.
- Repeatedly switch to cinematic angles.
- Use camera shake as the primary way to show action.

The camera should be fixed in position, orientation, and framing throughout normal mission presentation.

Use local animations and environmental state changes instead of camera motion.

The global CRT mouse-parallax effect from Phase 2 is separate and must not modify the Mission Control camera.

## 4.2 How to show motion with a stationary camera

The scene should still feel dynamic.

Use:

- Animated spacecraft components.
- Engine ignition.
- Rocket vibration.
- Thruster pulses.
- Stage separation.
- Deployable components.
- Exhaust particles.
- Engine light changes.
- Material changes.
- Small controlled object movements.
- Subtle background ambience.
- Appropriate phase-specific spacecraft configurations.

The overall scene should remain compositionally stable.

Avoid moving the entire universe or star field around the spacecraft merely to simulate travel.

## 4.3 Different environments across mission phases

The mission travels between Earth and the Moon.

A fixed-camera presentation must still communicate these changing environments.

Use an authored visual staging system that preserves the camera perspective.

For example:

- Earth-oriented backdrop during ascent and Earth orbit.
- Deep-space backdrop during translunar coast.
- Lunar-oriented backdrop during lunar orbit and operations.
- Earth-oriented backdrop during return and re-entry.

These may be different configurations of the same fixed observation stage, or carefully controlled phase-specific visual states.

The transition between them can use crossfades, environmental changes, or spacecraft configuration changes.

**Do not replace this with camera flythroughs.**

The viewer should always feel that they are looking at one consistent observation composition, even as the mission context changes.

Some phases, particularly the interactive lunar landing minigame, may require a dedicated focused gameplay presentation. Keep these transitions inside the same overall Mission Control visual language.

---

# 5. MAIN SCREEN COMPOSITION

The screen must have two primary regions.

## 5.1 Left / central region — space scene

Approximately 65–72% of available horizontal space should be devoted to the animated spacecraft environment.

This is a suggested starting proportion, not an immutable layout constraint.

The scene contains:

- Main rocket/spacecraft.
- Earth or mission-relevant celestial backdrop.
- Deep space.
- Lighting.
- Visual effects.
- Mission phase visualization.

The rocket must be visually prominent.

It should not be reduced to a small illustration in the corner.

## 5.2 Right region — mission dashboard

Approximately 28–35% of the screen should be dedicated to an interactive mission control panel.

This panel contains:

- Current mission phase.
- Mission status.
- Latest event updates.
- Important telemetry.
- Warnings.
- Player decisions.
- Emergency controls.
- Contextual action buttons.

The dashboard must feel like part of the game's retro-futuristic environment.

Use the shared Balatro-inspired animated UI system.

## 5.3 Secondary information

Use a compact top or bottom information bar if necessary for:

- Mission elapsed time.
- Phase progress.
- Objective status.
- Pause/continue controls.
- Current mission status.

Avoid making the screen resemble a dense spreadsheet.

Prioritize the information relevant to the current phase.

The full scientific details can remain accessible through expandable panels and event logs.

---

# 6. BUILD THE STYLIZED SPACE ENVIRONMENT

Create an actual 3D environment rendered into the existing game interface.

Use Godot 4.7's supported 3D rendering and viewport systems.

## 6.1 Background

Create a deep-space background with:

- Sparse stars.
- Subtle color variation.
- Strong depth perception.
- Minimal visual noise.

The environment should feel atmospheric, not empty or generic.

Avoid excessive nebula textures or enormous glowing effects.

## 6.2 Earth

Create a stylized 3D Earth.

Desired qualities:

- Recognizable spherical geometry.
- Simplified continent and ocean coloration.
- Attractive lighting.
- Strong day/night boundary.
- Controlled atmosphere-like edge glow.
- Low-poly or moderately stylized appearance.

The Earth should look coherent with the 3D Moon from Phase 3.

It should not suddenly introduce photorealistic satellite imagery if the rest of the game uses stylized materials.

The Earth is a background element.

It must not compete with the spacecraft for attention.

Subtle rotation is acceptable if it does not create noticeable large-scale background motion or undermine the stable camera composition.

## 6.3 Moon and other celestial context

During lunar phases, use the Moon or a lunar surface background where appropriate.

Reuse compatible visual resources or materials from Phase 3.

Do not duplicate the entire Science Planner system unnecessarily.

If shared planetary material or geometry components are available, reuse them.

Do not import another unrelated Moon asset with a different artistic style.

## 6.4 Lighting

Use carefully directed lighting to emphasize spacecraft silhouettes.

Potential light sources:

- Simulated sunlight.
- Engine ignition.
- Thruster emission.
- Instrument or status lights.
- Subtle edge highlights.

Engine lighting should visibly change when engines activate.

Avoid expensive lighting configurations where simpler techniques produce equivalent results.

---

# 7. SPACECRAFT AND ROCKET VISUAL SYSTEM

The spacecraft is the central object of the scene.

It must be more than a static image.

Create a stylized 3D rocket and spacecraft presentation capable of responding to actual mission configuration.

## 7.1 Visual style

Use:

- Low-poly geometry.
- Clear cylindrical stages.
- Recognizable engines.
- Simple boosters.
- Distinct spacecraft modules.
- Stylized structural details.
- Intentional materials.
- Controlled mechanical animation.

The rocket should feel like a physical game object.

Avoid overly realistic textures, extreme polygon counts, and unnecessary microscopic details.

## 7.2 Connect it to actual player design

The existing game allows players to select rocket and spacecraft components.

The Mission Control visual representation should reflect the resulting vehicle design wherever practical.

Inspect `Vehicle.design`, existing vehicle data, and available rocket sprite/model assets.

At minimum, visually distinguish the major configurations that affect the actual spacecraft silhouette, including:

- Primary stage configuration.
- Booster configuration where applicable.
- Upper stages.
- Lander.
- Crew spacecraft/capsule.
- Important mission hardware.

Do not invent parts that the player did not select.

## 7.3 Modular model architecture

Prefer a modular spacecraft hierarchy.

Conceptual example:

```text
SpacecraftVisual
├── RocketRoot
│   ├── FirstStage
│   ├── Boosters
│   ├── SecondStage
│   ├── UpperStage
│   ├── ServiceModule
│   ├── CrewCapsule
│   └── Lander
├── Engines
├── Thrusters
├── ExhaustEffects
├── SeparationEffects
└── SpacecraftAnimationController
```

Adapt this to the actual vehicle system.

Not every component must be visible in every phase.

The presentation controller should determine which assemblies are attached, detached, hidden or active.

## 7.4 Spacecraft configuration changes

When the mission progresses, the spacecraft visual should change appropriately.

For example:

- Boosters disappear after separation.
- Empty stages detach.
- Upper-stage engines activate.
- The lunar spacecraft becomes prominent in relevant phases.
- The lander appears for lunar operations.
- The capsule remains for return and re-entry.

These changes must correspond to the actual existing flight events.

Do not display successful separation if the simulation determined separation failed.

---

# 8. ANIMATION SYSTEM

Create a reusable system for controlling spacecraft animations.

Do not put every animation inside one enormous Mission Control script.

## 8.1 Engine ignition

When an engine starts:

- Exhaust appears.
- Engine glow intensifies.
- Appropriate lighting activates.
- The spacecraft can exhibit a subtle vibration.
- Relevant telemetry updates.

Use stylized flames or exhaust rather than photorealistic volumetric effects.

Engine behavior should match the phase.

Do not show large atmospheric flames during a quiet coast phase.

## 8.2 Engine shutdown

When the engine stops:

- Exhaust contracts and disappears.
- Light emission fades.
- Vibration ends.
- Telemetry reflects the phase transition.

## 8.3 Stage separation

When a stage separates:

1. Trigger the separation event.
2. Disconnect the corresponding visual module.
3. Animate it moving away from the spacecraft.
4. Apply a small controlled rotation if appropriate.
5. Transition to the next spacecraft configuration.
6. Update the dashboard.

The animation must be clear and satisfying.

It should not feel like a texture simply disappearing.

If the simulation reports an abnormal staging outcome, the presentation must reflect that outcome rather than automatically playing a perfect separation animation.

## 8.4 Thruster activity

Implement short, stylized thruster pulses for relevant mission operations.

Use controlled light and particle effects.

Do not activate thrusters randomly in a way that implies unrecorded maneuvers.

## 8.5 Mechanical animations

Depending on the actual vehicle configuration, implement appropriate:

- Lander separation.
- Module movement.
- Deployment.
- Reconfiguration.
- Capsule-related actions.
- Recovery-related transformations.

Keep the animation physically recognizable, even though the artwork is intentionally stylized.

## 8.6 Animation interruptions

All animations must tolerate:

- Pause.
- Resume.
- Phase skipping.
- Rapid event advancement.
- Mission termination.
- Scene exit.
- Decision interruptions.

No animation may leave the spacecraft in an invalid configuration after a skip or interrupted transition.

When skipping, settle directly into the correct state for the target mission phase.

---

# 9. SUPPORT ALL EXISTING FLIGHT PHASES

The original game includes ten flight phases.

Preserve their order and gameplay meaning.

Use the following as the visual-design plan, but read the existing code to determine the actual event sequence and timing.

## PHASE 1 — COUNTDOWN

Visuals:

- Full launch vehicle.
- Launch preparation state.
- Subtle equipment status lights.
- Possible launchpad/staging context.
- Engine preparation.
- Ignition sequence.

Dashboard:

- Mission readiness.
- Countdown updates.
- Launch conditions.
- Existing decision events.

The fixed camera should establish the vehicle and overall visual language.

## PHASE 2 — ASCENT

Visuals:

- Main engines active.
- Strong stylized exhaust.
- Controlled rocket vibration.
- Stage separation.
- Booster separation where applicable.
- Transition to upper-stage configuration.

Dashboard:

- Altitude or relevant phase telemetry.
- Stage status.
- Engine status.
- Warnings.
- Staging interactions.

The animation must be connected to the existing staging system.

## PHASE 3 — EARTH ORBIT

Visuals:

- Spacecraft against the Earth.
- Reduced or absent engine activity.
- Small attitude-control effects if appropriate.
- Stable orbital environment.

Dashboard:

- Earth orbit established.
- Mission status.
- Remaining delta-v or relevant margins.
- Existing operational events.

## PHASE 4 — TRANSLUNAR INJECTION

Visuals:

- Upper-stage or spacecraft engine activation.
- Clearly visible engine burn.
- Controlled lighting change.
- Transition into translunar configuration.

Dashboard:

- Current maneuver.
- Relevant delta-v data.
- Burn status.
- Existing mission events.

## PHASE 5 — COAST TO THE MOON

Visuals:

- Quiet spacecraft against deep space.
- Engines inactive.
- Atmospheric but restrained ambient presentation.
- Appropriate spacecraft configuration.

Dashboard:

- Mission updates.
- Travel status.
- Existing communication or system events.
- Relevant decisions.

The scene should feel different from ascent without introducing unnecessary camera movement.

## PHASE 6 — LUNAR ORBIT INSERTION

Visuals:

- Lunar-oriented background.
- Relevant engine burn.
- Spacecraft reconfiguration.
- Distinct lighting.

Dashboard:

- Lunar arrival.
- Maneuver status.
- Delta-v margins.
- Existing decisions.

## PHASE 7 — LANDING

Visuals:

- Lunar context.
- Lander configuration.
- Descent-related effects.
- Clear transition into the existing interactive landing sequence.

Dashboard:

- Landing status.
- Fuel and other existing relevant information.
- Existing warnings and decisions.

The landing minigame must remain fully functional.

## PHASE 8 — LUNAR SURFACE

Visuals:

- Lander or spacecraft in an appropriate surface state.
- Stylized Moon environment.
- Appropriate deployment or mission activity animations where supported.

Dashboard:

- Scientific objectives.
- Mission status.
- Surface-operation events.
- Existing results.

Do not automatically show science objectives as completed unless the simulation reports completion.

## PHASE 9 — RETURN TO EARTH

Visuals:

- Return spacecraft configuration.
- Relevant engine effects.
- Earth-oriented or deep-space background.
- Atmospheric scene composition.

Dashboard:

- Return status.
- Remaining mission objectives.
- Existing critical events.
- Relevant telemetry.

## PHASE 10 — RE-ENTRY AND SPLASHDOWN

Visuals:

- Return capsule configuration.
- Stylized re-entry heating.
- Appropriate capsule effects.
- Recovery or splashdown animation.
- Correct success or failure state.

Dashboard:

- Re-entry status.
- Recovery outcome.
- Final mission updates.

After the phase completes, preserve the existing transition to the final mission report.

---

# 10. RIGHT-SIDE DASHBOARD — CORE PLAYER INTERFACE

This dashboard is as important as the spacecraft scene.

Its role is to let the player observe mission events and make decisions without taking visual attention away from the rocket.

Use the shared Phase 1/2 animated UI components.

## 10.1 Normal state

During routine flight, show:

- Current mission phase.
- Latest update.
- Event feed.
- Relevant metrics.
- Current mission status.
- Available actions.
- Compact progress information.

The layout must remain stable and readable.

Do not show every metric at maximum prominence simultaneously.

## 10.2 Event feed

Create a chronological event feed displaying the mission's actual updates.

Each entry may include:

- Event category.
- Time or phase identifier, where supported.
- Short title.
- Explanation.
- Status indicator.
- Optional detailed information.

Use existing event log content.

Do not fabricate telemetry or event timestamps.

New events should appear with restrained animations.

Keep a scrollable history where appropriate.

Avoid aggressively auto-scrolling while the player is reading earlier events.

## 10.3 Emergency state

When the simulation triggers an event requiring a player decision:

1. Highlight the event.
2. Show an animated alert.
3. Expand the appropriate decision panel.
4. Present all original choices.
5. Make the available actions clear.
6. Wait for the player's input.
7. Confirm the selected action.
8. Resume the original mission flow when appropriate.
9. Update the visual scene based on the actual result.

The alert panel may use amber or red depending on severity.

Do not use red for every event.

## 10.4 Decision cards

Use satisfying Balatro-inspired interaction:

- Slight hover scale.
- Press compression.
- Rebound.
- Clear selection.
- Animated confirmation.
- Smooth opening and closing.

Retain the exact gameplay meaning of each existing option.

Do not add a new choice or remove an existing choice simply to simplify the interface.

## 10.5 Dashboard modes

Consider two major modes:

**MONITORING**

- Compact event feed.
- Status.
- Telemetry.
- Phase progress.

**ACTION REQUIRED**

- Prominent alert.
- Decision choices.
- Context.
- Confirmation.
- Reduced competing information.

The transition between modes should feel natural.

## 10.6 Avoid input conflicts

The dashboard must properly handle:

- Mouse input.
- Keyboard input.
- Focus navigation.
- Decision confirmation.
- Minigame input.
- Pause/resume controls.

No gameplay action should trigger twice due to overlapping UI handlers.

---

# 11. CONNECT SIMULATION TO VISUALS — EVENT-DRIVEN ARCHITECTURE

This is a critical technical requirement.

**Do not create an independent fake flight animation timeline that runs separately from the real simulation.**

We need a reliable connection between existing mission events and the new visual scene.

## 11.1 Single source of truth

The existing simulation determines:

- Mission phases.
- Vehicle state.
- Decision opportunities.
- Success/failure outcomes.
- Event causes.
- Flight progress.
- Scientific consequences.

The visual system reads this state and presents it.

## 11.2 Recommended architecture

Introduce an adapter or presentation controller.

Conceptually:

```text
Existing Flight Simulation
          |
          v
Mission Presentation Adapter
          |
          +-----------------------+
          |                       |
          v                       v
Spacecraft Visual Director   Dashboard Controller
          |                       |
          v                       v
3D Animations                Event Cards / Decisions
          |                       |
          +-----------+-----------+
                      |
                      v
               Existing Game Flow
```

Use the architecture that best fits the current project.

The adapter may normalize existing flight event dictionaries into presentation events without changing their gameplay meaning.

## 11.3 Suggested presentation events

Examples include:

- `phase_started`
- `phase_completed`
- `engine_ignited`
- `engine_shutdown`
- `stage_separated`
- `spacecraft_reconfigured`
- `mission_event_received`
- `decision_requested`
- `decision_resolved`
- `staging_started`
- `staging_completed`
- `landing_started`
- `landing_completed`
- `mission_completed`

These are conceptual event names.

Do not invent new gameplay events.

Do not add unnecessary signals where the current architecture already provides equivalent hooks.

## 11.4 Exactly-once behavior

Ensure that:

- An event is not processed twice.
- Decisions are not applied twice.
- Minigame outcomes are not recorded twice.
- A phase transition cannot be triggered repeatedly by visual callbacks.
- An animation cannot accidentally rerun the simulation.
- Scene reconstruction does not reroll random events.

Where suitable, use stable event or phase identifiers.

Avoid duplicate subscriptions and leaked signal connections.

## 11.5 Determinism and outcomes

The existing game has seeded or deterministic components in its flight preparation and outcomes.

Preserve them.

Replaying an animation must not recalculate the flight result.

Changing visual quality settings must not change mission outcomes.

Pausing, skipping, or accelerating presentation must not alter the scientific or gameplay result.

---

# 12. PRESERVE STAGING AND LANDING MINIGAMES

Two existing interactive systems require special attention.

## 12.1 Staging minigame

Inspect:

- `screens/flight/staging_game.gd`
- Existing staging integration in Mission Control.
- Corresponding flight outcome handling.

Maintain the original:

- Player controls.
- Timing requirements.
- Success/failure behavior.
- Accuracy calculations.
- Outcome consequences.

Visually integrate it with the new rocket presentation.

The player should be able to see the corresponding stages while interacting.

Stage separation animations must reflect what actually happened.

Do not automatically replace manual staging with a cinematic animation.

## 12.2 Lunar landing minigame

Inspect:

- `screens/flight/landing_game.gd`
- Existing descent mechanics.
- Controls.
- Landing zones.
- Fuel.
- Vertical and horizontal motion.
- Outcome reporting.

Preserve the full gameplay.

Upgrade its visual environment to match the new style where feasible.

A dedicated fixed-angle descent view is acceptable inside the Mission Control presentation, provided it remains consistent with the single-camera, deliberately framed aesthetic.

Do not transform it into a first-person simulator.

Do not rewrite lunar gravity or landing calculations.

## 12.3 Input and timing

Ensure the minigames correctly take control of relevant input while active.

The dashboard must not intercept their controls.

When a minigame ends, restore normal dashboard interaction.

Pause/resume must work correctly.

No input state should remain stuck after the minigame closes.

---

# 13. SPECIAL EVENTS, FAILURES AND EMERGENCIES

The existing game includes mission failures and delayed consequences.

Their visual presentation should become substantially more engaging.

## 13.1 Visualize events honestly

Examples of possible event types:

- Engine anomalies.
- Stage separation problems.
- Flight trajectory problems.
- System failures.
- Landing emergencies.
- Recovery problems.

Use actual existing events and consequences.

Do not assume every type is implemented without inspecting the current code.

## 13.2 Event presentation

When an actual critical event occurs, combine:

- Clear alert animation.
- Relevant spacecraft effect.
- Dashboard warning.
- Decision interface.
- Updated system status.

For instance, if an engine failure occurs, the affected engine visual might stop firing or change state.

But the animation should be triggered by the actual failure event, not an arbitrary random effect.

## 13.3 Failure outcomes

If the flight ends unsuccessfully:

- Stop inappropriate success animations.
- Set the spacecraft to the correct failure state.
- Display an appropriate alert.
- Present the actual outcome.
- Preserve the final report transition.

Do not always show the spacecraft exploding.

Different failures require different visual consequences.

For example, a crew escape or mission abort is not necessarily the same as complete vehicle destruction.

## 13.4 Narrative consistency

Preserve the educational value of the original game.

When an event results from a previous design decision, the event log and final report must continue explaining the relationship.

The visuals should reinforce cause and effect, not replace it with spectacle.

---

# 14. FLIGHT TIMING, PAUSE, SPEED AND SKIPPING

The current Mission Control contains event progression, pause behavior, and presentation controls.

These systems must be preserved.

## 14.1 Pause

When the player pauses:

- Mission presentation stops.
- Active spacecraft animations pause appropriately.
- Timed event transitions stop.
- The event feed remains readable.
- Settings and other allowed UI interactions can remain usable.

Do not pause the underlying application in a way that prevents necessary UI controls from functioning.

Inspect the existing implementation before choosing a pause architecture.

## 14.2 Resume

On resume:

- Animations continue correctly.
- No event is duplicated.
- No phase is skipped accidentally.
- No animation jumps unexpectedly unless that behavior is necessary to restore authoritative state.

## 14.3 Skip or fast-forward

The player must retain existing skip/advance options.

Skipping must:

- Resolve presentation state safely.
- Preserve gameplay outcomes.
- Keep pending decisions intact where required.
- Update the spacecraft model to the correct final configuration.
- Avoid duplicate phase callbacks.
- Avoid leaving particles or temporary objects behind.

If a player skips a cinematic transition, the relevant visual objects should immediately settle into the correct state.

## 14.4 Animation timing versus simulation timing

Keep a clear distinction between:

- Scientific/simulation time.
- Mission event ordering.
- Visual animation time.
- UI transition time.

Do not allow a slow animation to modify the flight calculation.

Do not use presentation frame rate as an input to scientific outcomes.

---

# 15. CRT AND PHASE 1–3 COMPATIBILITY

The existing visual systems are approved and should not be replaced.

Mission Control must integrate with:

- CRT curvature.
- Scanlines.
- Glow.
- Chromatic aberration.
- Mouse-responsive screen drift.
- Display mode switching.
- Shared UI transitions.
- Reduced motion.
- Existing game theme and fonts.

## 15.1 Rendering composition

Inspect how the Phase 2 headquarters and Phase 3 Moon render their 3D environments.

Reuse the established rendering architecture where appropriate.

A possible solution:

```text
MissionControlScreen
├── SpaceViewportContainer
│   └── SpaceViewport
│       └── SpaceEnvironment3D
│           ├── Camera3D
│           ├── Earth
│           ├── MoonContext
│           ├── SpacecraftVisual
│           ├── Lights
│           └── Effects
│
├── MissionDashboard
│   ├── PhaseHeader
│   ├── EventFeed
│   ├── TelemetryPanel
│   ├── DecisionPanel
│   └── Controls
│
├── MinigameOverlay
└── MissionPresentationController

Existing global CRT / display compositor
```

This is a conceptual hierarchy.

Adapt it to the actual project.

Do not nest redundant post-processing layers or create separate conflicting CRT effects.

## 15.2 Pointer accuracy

The global dynamic screen movement changes the displayed image.

All dashboard interactions must remain aligned with their visible positions.

Verify:

- Hover.
- Click.
- Drag, where used.
- Scroll.
- Keyboard focus.
- Minigame interactions.

Do not introduce input transformations that conflict with the existing Phase 2 implementation.

## 15.3 Display resolutions

Test at:

- 1280×720.
- 1600×900 where practical.
- 1920×1080.
- Available fullscreen/windowed modes.

The spacecraft must not become excessively small at higher resolutions.

The dashboard must not cover the main visual subject.

Use a layout that adapts correctly to the available space.

---

# 16. UI/UX POLISH REQUIREMENTS

Mission Control should feel satisfying even when the player is simply monitoring the flight.

## 16.1 Ambient visual life

During quiet phases, use subtle:

- Instrument illumination.
- Status transitions.
- Spacecraft material highlights.
- Small appropriate mechanical movements.
- Gentle dashboard activity.

Avoid constant exaggerated animation.

## 16.2 Important event feedback

When something meaningful happens:

- Use a more noticeable animation.
- Give the player enough time to understand it.
- Keep the result visible.
- Avoid immediately hiding critical information.

## 16.3 Interface readability

Maintain sufficient font sizes.

Do not force critical information into tiny labels to maximize the 3D viewport.

Use strong hierarchy:

1. Current alert or decision.
2. Mission status.
3. Relevant telemetry.
4. Event history.
5. Secondary technical details.

## 16.4 Color and status

Use coherent status colors.

Examples:

- Cyan for telemetry or neutral information.
- Amber for warnings.
- Red for critical failures.
- Green for verified positive status.
- Muted neutral tones for completed or inactive information.

Do not communicate important states through color alone.

Use text and recognizable icons where appropriate.

## 16.5 Sound

If the project has no established sound system, do not make new audio assets a blocker for this phase.

However, design the effects architecture so that future UI sounds, engine sounds, alarms and interaction feedback can be attached cleanly.

Do not introduce copyrighted sound effects without permission.

---

# 17. TECHNICAL IMPLEMENTATION GUIDELINES

Use Godot 4.7-compatible code and resources.

Suggested tools include:

- `Node3D`
- `Camera3D`
- `SubViewport`
- `SubViewportContainer`
- `AnimationPlayer`
- `AnimationTree`, if justified
- `Tween`
- `GPUParticles3D` or another appropriate particle system
- `MeshInstance3D`
- `MultiMeshInstance3D`, where justified
- `ShaderMaterial`
- `StandardMaterial3D`
- `WorldEnvironment`
- Signals and reusable scene resources

Select components based on the needs of the current project.

Do not create large abstractions where simple, focused controllers would be sufficient.

## 17.1 Separation of responsibilities

Keep the following responsibilities distinct:

**Flight model**

- Scientific calculations.
- Outcomes.
- Gameplay decisions.

**Mission presentation adapter**

- Translation of existing phase/event state into visual instructions.

**Spacecraft visual controller**

- Physical model changes.
- Engine animations.
- Stage separation.
- Effects.

**Environment controller**

- Earth/Moon/deep-space appearance.
- Lighting.
- Phase-specific background states.

**Dashboard controller**

- Event log.
- Telemetry.
- Decisions.
- Alerts.
- Player interaction.

**Mission Control coordinator**

- Synchronization.
- Phase flow.
- Pause/resume.
- Minigame transitions.
- Cleanup.

The exact script names may differ.

## 17.2 Resource lifecycle

Ensure:

- Particle systems stop when appropriate.
- Temporary effects are cleaned up.
- Old animations do not run after scene changes.
- Signal connections are not duplicated.
- Memory usage remains stable.
- Skipping does not create orphaned scene objects.

## 17.3 Avoid unnecessary changes

Do not refactor unrelated systems.

Do not modify the Science Planner, headquarters or game settings unless necessary for compatibility.

Do not redesign Vehicle Assembly in Phase 4.

That is reserved for Phase 5.

---

# 18. PERFORMANCE TARGETS

Target a polished and responsive experience on ordinary Windows gaming and productivity systems.

Aim for approximately 60 FPS at 1920×1080 on reasonably capable hardware.

Prioritize:

- Efficient models.
- Reusable geometry.
- Reasonable texture sizes.
- Simple stylized materials.
- Limited dynamic lighting.
- Efficient particles.
- Cached assets.
- Minimal per-frame allocations.
- Controlled UI redraws.

Do not use extremely high-resolution textures for objects that occupy a small portion of the screen.

Do not introduce costly real-time ray tracing or unnecessary volumetric effects.

If necessary, create low/medium/high visual quality settings compatible with the existing configuration system.

Do not sacrifice input responsiveness for visual polish.

---

# 19. IMPLEMENTATION ROADMAP

Work in manageable, testable steps.

## STEP A — BASELINE AND FLIGHT AUDIT

Before modifying Mission Control:

1. Inspect the current scene and scripts.
2. Identify the existing phase and event progression.
3. Identify where simulation results are created.
4. Identify existing decision gates.
5. Identify staging and landing minigame integration.
6. Identify pause, skip and completion behavior.
7. Record existing mission outcomes and test paths.
8. Confirm the development branch and working state.

Document the behavioral contracts that must remain intact.

Do not rewrite the flight engine.

## STEP B — STATIC CAMERA SPACE PROTOTYPE

Create the fixed-camera 3D space environment.

Implement:

- Deep-space background.
- Stylized Earth.
- Basic spacecraft model.
- Lighting.
- Camera composition.
- Integration into Mission Control.

Use simple geometry initially to validate the layout.

Ensure the camera remains completely static.

## STEP C — SPACECRAFT CONFIGURATION SYSTEM

Connect the spacecraft appearance to existing vehicle data.

Implement modular visual stages and relevant spacecraft parts.

Verify that component configuration changes do not alter gameplay state.

## STEP D — ENGINE AND MECHANICAL ANIMATION

Implement:

- Engine ignition.
- Engine shutdown.
- Exhaust.
- Engine lighting.
- Stage separation.
- Thruster pulses.
- Relevant spacecraft reconfiguration.

Ensure animations can be interrupted and restored to authoritative states.

## STEP E — MISSION PHASE VISUAL DIRECTOR

Create the controller that coordinates visual states across all ten mission phases.

Integrate phase-specific:

- Spacecraft configurations.
- Background states.
- Lighting.
- Animations.
- Environment changes.

Do not implement independent physics or mission progression.

## STEP F — INTERACTIVE MISSION DASHBOARD

Replace the existing dense Mission Control presentation with the right-hand animated dashboard.

Implement:

- Phase status.
- Telemetry.
- Event feed.
- Decision cards.
- Alerts.
- Buttons.
- Animated transitions.

Reuse existing UI components.

## STEP G — EVENT AND DECISION INTEGRATION

Connect actual flight events to visuals.

Verify:

- Event ordering.
- Decision gates.
- Emergency state.
- Visual consequences.
- Successful outcomes.
- Failure outcomes.
- No duplicated state changes.

## STEP H — MINIGAME INTEGRATION

Integrate staging and lunar landing.

Preserve all original mechanics.

Improve the surrounding visual presentation.

Test both successful and unsuccessful minigame outcomes.

## STEP I — POLISH

Refine:

- Camera composition.
- Rocket silhouette.
- Materials.
- Earth appearance.
- Engine effects.
- UI spacing.
- Animation timing.
- Readability.
- Alert states.
- Scene transitions.

Avoid leaving placeholder geometry as the final visual result without clearly documenting the limitation.

## STEP J — REGRESSION TESTING

Run available automated and manual checks.

Verify the complete mission flow.

Correct discovered errors.

Prepare a final completion report.

---

# 20. ACCEPTANCE TESTS — REQUIRED

Do not declare Phase 4 complete until these features are implemented and validated, or clearly marked for manual testing where automation is not possible.

## Visual environment

- [ ] The Mission Control screen contains a genuine 3D spacecraft scene.
- [ ] The camera remains fixed.
- [ ] The spacecraft is visually prominent.
- [ ] Earth is rendered in the appropriate background states.
- [ ] Lunar and deep-space contexts are represented appropriately.
- [ ] The visual style matches Phases 1–3.
- [ ] The scene integrates with the CRT system.
- [ ] Dynamic screen parallax does not move the Mission Control camera.

## Spacecraft

- [ ] The rocket visual uses actual player configuration where applicable.
- [ ] Engine ignition is visible.
- [ ] Engine shutdown is visible.
- [ ] Stage separation is animated.
- [ ] Spacecraft configuration changes match mission phases.
- [ ] Relevant thruster and mechanical effects work.
- [ ] Spacecraft visuals reflect important mission events.
- [ ] Animation interruption and cleanup work correctly.

## Mission progression

- [ ] Countdown works.
- [ ] Ascent works.
- [ ] Earth orbit works.
- [ ] Translunar injection works.
- [ ] Coast to the Moon works.
- [ ] Lunar orbit insertion works.
- [ ] Landing works.
- [ ] Lunar surface operations work.
- [ ] Return to Earth works.
- [ ] Re-entry and splashdown work.
- [ ] Final mission report transition works.

## Dashboard

- [ ] Right-hand dashboard displays the correct phase.
- [ ] Event feed displays actual mission events.
- [ ] Telemetry reflects authoritative game state.
- [ ] Emergency alerts work.
- [ ] Decision panels appear when required.
- [ ] All existing player choices remain available.
- [ ] Decision confirmations work.
- [ ] UI animations are consistent with previous phases.
- [ ] No duplicate decisions or events occur.

## Minigames

- [ ] Staging minigame still works.
- [ ] Staging outcomes are preserved.
- [ ] Landing minigame still works.
- [ ] Landing controls work.
- [ ] Landing calculations are unchanged.
- [ ] Minigame input does not conflict with dashboard controls.
- [ ] Results return correctly to Mission Control.

## Reliability

- [ ] Pause works.
- [ ] Resume works.
- [ ] Skip/advance works.
- [ ] Interrupted animations resolve correctly.
- [ ] Successful missions produce correct reports.
- [ ] Failed missions produce correct reports.
- [ ] No simulation outcome is recalculated by visual effects.
- [ ] The existing scientific calculations remain unchanged.
- [ ] CRT input coordinates remain accurate.
- [ ] Fullscreen and windowed modes work.
- [ ] No critical Godot errors occur.
- [ ] No major performance regression is introduced.

---

# 21. REGRESSION SCENARIOS

Test more than a single ideal mission.

Where feasible, use stable or reproducible existing mission configurations.

**Scenario A — Successful mission**

Complete a mission with favorable choices.

Verify:

- Successful staging.
- Normal flight progression.
- Lunar operations.
- Return to Earth.
- Correct final mission report.

**Scenario B — Launch or staging problem**

Use an existing scenario that produces a launch or staging issue.

Verify:

- Correct event log.
- Correct spacecraft animation.
- Correct dashboard warning.
- Correct choices, if available.
- Correct final outcome.

**Scenario C — Landing outcome**

Test the interactive landing sequence.

Verify both favorable and unfavorable outcomes, where reproducible.

**Scenario D — Interruption**

During an animation or event:

- Pause.
- Resume.
- Skip where allowed.
- Change display mode where safe.
- Confirm that state remains correct.

**Scenario E — Long flight**

Complete the full mission without restarting the scene.

Check memory usage, input responsiveness and object cleanup.

Do not create production-only cheats to force outcomes. If test hooks are necessary, isolate them clearly from the normal game.

---

# 22. DOCUMENTATION AND FINAL REPORT

When implementation is complete, provide:

1. Summary of completed features.
2. All important created and modified files.
3. Explanation of the 3D rendering architecture.
4. Explanation of why the camera remains fixed.
5. Spacecraft modeling and configuration approach.
6. Engine, staging and mechanical animation approach.
7. Event-to-animation synchronization architecture.
8. Right-hand dashboard implementation details.
9. Landing and staging integration details.
10. Confirmation that scientific and gameplay logic remains unchanged.
11. Automated validation results.
12. Manual verification instructions.
13. Known issues and limitations.
14. Remaining placeholders, if any.
15. Relevant performance observations.

If actual screenshots or rendered previews can be generated, include them.

Do not claim the scene is visually verified unless it was rendered and inspected.

Do not claim the gameplay was fully tested if only an editor import or parsing check was performed.

Clearly distinguish:

- Implemented.
- Automatically tested.
- Manually verified.
- Requires manual verification.
- Incomplete.

---

# 23. WORKING RULES

- Work only in the local development project.
- Preserve Phases 1, 2 and 3.
- Preserve all original scientific calculations.
- Do not rewrite campaign progression.
- Do not introduce unrelated gameplay features.
- Do not replace manual interactions with automatic cinematics.
- Do not create a free-moving Mission Control camera.
- Do not substitute flat animations for the requested 3D scene.
- Do not copy proprietary assets from inspiration games.
- Keep scripts and scene architecture modular.
- Use Godot 4.7-compatible APIs.
- Test incrementally.
- Avoid destructive Git operations.
- Do not push to a remote repository without authorization.
- Do not start Phase 5 until Phase 4 has been reviewed.

Make useful implementation decisions independently when the specification is clear.

For ambiguous artistic details, prioritize the established visual language and functionality.

Focus on delivering actual working features rather than producing extensive planning documents.

---

# 24. DEFINITION OF DONE

Phase 4 is complete when:

1. Mission Control looks and feels like a stylized 2.5D arcade spaceflight experience.

2. A recognizable spacecraft occupies most of the main scene.

3. The camera remains fixed while the spacecraft and its components animate.

4. Engine ignition, stage separation, flight phases and relevant mission events produce visible consequences.

5. The right dashboard clearly displays current events, telemetry and player decisions.

6. The dashboard uses the established tactile, animated UI language.

7. Mission visuals remain synchronized with the real simulation.

8. Existing staging and landing gameplay remains functional.

9. All ten flight phases remain intact.

10. Successful and unsuccessful missions retain their correct outcomes.

11. The existing CRT, screen movement, display modes and visual styling continue working.

12. The resulting scene is attractive, readable, maintainable, and reasonably performant.

---

# 25. IMMEDIATE EXECUTION INSTRUCTIONS

You have already completed Phases 1–3.

**Begin Phase 4 now.**

First, briefly inspect the actual current Mission Control code and determine the safest way to separate the existing flight logic from its visual presentation.

Then:

1. Create the fixed-camera 3D space scene.
2. Build a modular stylized rocket/spacecraft presentation.
3. Implement engine and staging animations.
4. Connect visual states to the original flight phases.
5. Build the animated right-side mission dashboard.
6. Integrate all existing decisions and emergency events.
7. Preserve and visually integrate the existing landing/staging minigames.
8. Refine materials, lighting, transitions and animations.
9. Test the full gameplay flow and important failure cases.
10. Provide a completion report.

Implement this in small verified milestones rather than one large untested rewrite.

**FINAL DIRECTIVE:**

The player must feel as if they are watching their own spacecraft carry out a real lunar mission through an extraordinary retro-futuristic arcade observation system.

The camera stays still.

The spacecraft comes alive.

The dashboard reacts to every meaningful event.

The player's decisions determine what happens.

The existing simulation remains authoritative.

**PRESERVE THE SCIENCE. PRESERVE THE STRATEGY. TRANSFORM THE EXPERIENCE.**

# BEGIN PHASE 4 — CINEMATIC MISSION CONTROL IMPLEMENTATION.
