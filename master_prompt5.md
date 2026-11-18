# TO THE FAR SIDE — PHASE 5: FULLSCREEN VEHICLE ASSEMBLY + IMMERSIVE OVERLAY UI

## Includes carry-over visual architecture updates from Phase 4

# 0. ROLE AND OBJECTIVE

You are continuing development of **To the Far Side**, a Godot 4.7 / GDScript lunar mission strategy game undergoing a full visual overhaul.

**Phases 1–4 are complete and functioning.**  
Your task is to implement **Phase 5: Vehicle Assembly**, while also introducing a more advanced **fullscreen immersive scene shell** that reflects feedback from Phase 4.

This is an implementation task.

You must write actual code, scenes, visual controllers, UI panels, environment scenes, animations, and integration logic.

Do not stop at planning.

---

# 1. IMPORTANT CONTEXT

## 1.1 Existing completed phases

The project already includes:

- Phase 1: CRT shader + global UI animation foundation
- Phase 2: fullscreen display improvements + stylized headquarters
- Phase 3: interactive 3D Moon science planner
- Phase 4: Mission Control with a fixed-camera 2.5D mission scene and dashboard

All these systems must remain functional.

## 1.2 New design decision from user feedback

The user tested Phase 4 and wants the next immersive screens to adopt this stronger presentation rule:

### NEW PRESENTATION RULE

**The main 3D/2.5D scene should occupy the whole screen, while interface elements float above it as overlay panels, hovering around the edges.**

This applies especially to:

- Vehicle Assembly (Phase 5)
- and should be implemented in a reusable way so Mission Control can also use the same pattern more fully

This means:

- do not trap the 3D scene inside a boxed viewport area with thick surrounding UI
- the rocket / main scene should dominate the whole screen
- overlay panels should sit on top of the scene
- some panels can slide aside, retract, collapse, or be reopened
- the UI should feel integrated, not like separate website columns

## 1.3 Vehicle Assembly priority

Phase 5’s main deliverable is **Vehicle Assembly**.

It must become one of the most visually impressive screens in the game.

The player should feel that they are standing in front of a giant mission rocket in a stylized assembly hangar and are actively configuring it.

The engineering calculations and real gameplay logic must remain intact.

---

# 2. PRESERVE EXISTING GAMEPLAY AND ENGINEERING LOGIC

This is a visual/presentational overhaul.

Do NOT change the existing engineering model.

Preserve all actual gameplay behavior and formulas, including:

- component availability
- vehicle configuration rules
- launch site selection
- payload capacity logic
- rocket delta-v calculations
- spacecraft delta-v calculations
- thrust-to-weight calculations
- mass calculations
- power calculations
- schedule/build time calculations
- budget use
- reliability/risk logic
- uncertainty margins
- progression logic
- stage validation logic
- all original choices and consequences

Do not simplify the model to make the visuals easier.

Do not replace calculations with fake visual numbers.

The existing code remains authoritative.

Animated values are presentation only.

---

# 3. FILES TO INSPECT BEFORE MODIFYING

Review the current state of the actual local repository before making changes.

Inspect at minimum:

- `autoload/vehicle.gd`
- `autoload/campaign.gd`
- `autoload/scene_router.gd`
- `screens/engineering/vehicle_assembly.gd`
- `screens/engineering/vehicle_assembly.tscn`
- `screens/engineering/rocket_stack.gd`
- any helper scenes/resources introduced in Phases 1–4
- any UI component libraries introduced earlier
- any fullscreen composition / CRT compositing architecture already built
- any shared 3D rendering or viewport-shell systems from headquarters, Moon planner, and Mission Control

Inspect the actual current data structures for:

- slot groups
- sections
- options
- selected parts
- launch sites
- validation
- displayed metrics
- current UI flow

Do not assume the original structure is unchanged after prior phases.

---

# 4. GLOBAL VISUAL DIRECTION FOR PHASE 5

Continue the project’s established visual identity:

**RETRO-FUTURISTIC · LOW-POLY · 2.5D · ARCADE · CRT · SPACE-INDUSTRIAL**

The target feeling is:

- a stylized rocket assembly hangar
- large, theatrical, game-like
- tactile and playful
- technically serious underneath
- not photorealistic
- not web-dashboard-like
- not flat
- not cluttered

Primary inspirations remain:

- **Balatro** for tactile, satisfying overlay UI and card/panel motion
- **R.E.P.O.** for stylized physical scenes, playful low-poly volume and lighting
- **Lethal Company** for industrial sci-fi mood, utilitarian machinery, and space-industrial atmosphere

Do not copy any proprietary assets, layouts, logos or exact art from those games.

The deliverable must feel original.

---

# 5. CORE DESIGN GOAL — FULLSCREEN IMMERSIVE VEHICLE ASSEMBLY

This phase must build the screen the user has in mind:

## 5.1 Main idea

The **rocket assembly scene is fullscreen**.

The rocket/hangar scene takes over the whole screen.

The user interface hovers above it around the edges.

The rocket is the hero object.

The player should feel like they are configuring a giant mission rocket in a live hangar, not editing rows in a menu.

## 5.2 Overlay UI principles

Overlay panels should feel like floating control surfaces.

Possible panel behaviors:

- slide in from edge
- retract to a tab
- collapse into a smaller card
- open on hover or click
- remain pinned if desired
- gently animate
- not permanently block the rocket

The player should be able to:

- focus on the rocket
- focus on metrics
- focus on part selection
- focus on launch site
  without losing the immersive fullscreen scene

## 5.3 Fullscreen standard should be reusable

Architect this as a reusable immersive scene-shell for later use.

It should be compatible with:

- existing CRT rendering
- mouse-responsive screen drift
- 2D overlay controls
- 3D scene viewports
- future screens

Where safe, structure the code so Mission Control can later adopt the same shell more fully, without destabilizing Phase 4 right now.

Do not perform a risky unnecessary rewrite of Mission Control in this phase.

---

# 6. VEHICLE ASSEMBLY — TARGET EXPERIENCE

The player enters Engineering / Vehicle Assembly and sees:

- a full-screen stylized rocket hangar
- a giant assembled rocket standing vertically
- gantries, catwalks, lights, support structures
- subtle atmospheric movement
- hoverable engineering panels around the screen
- category/section selectors
- part cards or trays
- live engineering stats
- satisfying part installation / removal animations

The rocket should feel monumental.

The whole screen should immediately communicate:

**“You are building the mission vehicle.”**

---

# 7. HANGAR ENVIRONMENT

## 7.1 Main scene

Create a stylized 3D/2.5D assembly hangar or vehicle integration building.

Desired characteristics:

- low-poly but attractive
- tall vertical space
- strong silhouettes
- industrial catwalks / platforms
- support structures
- overhead lights
- cool/warm contrast lighting
- blue/orange or blue/amber engineering atmosphere
- floor markings
- subtle fog or depth where appropriate
- clear focal framing

The environment should be impressive but not distract from the rocket.

## 7.2 Art direction

Do not build a realistic NASA VAB replica.

Instead create a stylized assembly space inspired by aerospace hangars.

It can feel slightly toy-like / arcade-like, while still believable.

The rocket and surrounding equipment should have satisfying proportions and readable shape language.

## 7.3 Ambient life

The scene must never feel dead.

Always include subtle idle animation such as:

- work lights flickering softly
- monitors blinking
- tiny machinery motion
- suspended gantry micro-motion
- dust motes / small particles where appropriate
- subtle camera-local scene life
- rocket micro-movements (extremely subtle)
- background machinery status lights

Do not overdo it.

The effect should make the hangar feel alive.

---

# 8. ROCKET AS THE HERO OBJECT

## 8.1 Rocket focus

The rocket must dominate the screen.

It should be significantly larger and more prominent than before.

Do not reduce it to a small preview.

The rocket should stand vertically in the hangar, with enough surrounding context to feel physically located in a real space.

## 8.2 Must reflect actual vehicle configuration

The visual rocket must respond to real player selections.

Inspect the actual vehicle configuration system and map it onto modular visual components.

At minimum, visually support the selected major configurable groups, including wherever appropriate:

- first stage
- booster configuration
- second stage
- third/upper stage
- crew spacecraft / capsule
- service module
- lunar lander
- solar arrays or power-related visible equipment
- launch escape or relevant crew safety hardware
- selected launch site context where supported

Use the actual selected parts.

Do not display components that the player did not choose.

## 8.3 Modular architecture

Create a clean modular structure.

Conceptually:

```text id="7d7w15"
AssemblyRocketRoot
├── FirstStage
├── SideBoosters
├── SecondStage
├── UpperStage
├── ServiceModule
├── CrewCapsule
├── Lander
├── EscapeSystem
├── Details
├── Lights
└── RocketVisualController
```

Adapt to the actual project.

Each major section should be independently highlightable and, when appropriate, replaceable.

## 8.4 Section highlighting

When the player selects a category / section, the corresponding physical rocket area should clearly highlight.

Possible methods:

- outline or glow
- lighting emphasis
- color tint
- animated locator ring
- nearby callout label
- support platform illumination

The player must be able to understand which part of the rocket they are configuring.

This is critical.

---

# 9. FULLSCREEN OVERLAY UI LAYOUT

## 9.1 Overall composition

Use a fullscreen scene with overlay elements, roughly along these lines:

- center / left-center: giant rocket in hangar
- left edge or lower-left: section/category selector
- right side: collapsible engineering metrics / live stats panel
- bottom: selected-part tray / option cards / confirmation controls
- top: stage title, mission info, date / budget / deadline summary
- optional small floating context panels near highlighted rocket sections

This is not a rigid layout. Refine as needed for strong composition.

## 9.2 Floating / retractable panels

At least some overlay panels should be able to retract.

Desired behaviors:

- user can collapse the metrics panel
- user can reopen it easily
- part list can appear as a tray
- contextual inspector can slide in near current focus
- panel tabs remain accessible when collapsed
- critical actions remain discoverable

This should be elegant, not gimmicky.

The player should not struggle to find information.

## 9.3 Overlay philosophy

The UI must float above the scene rather than boxing it in.

Use transparency, depth, blur-like styling where appropriate, and restrained panel backgrounds.

Panels should feel like attached control overlays, not opaque walls.

---

# 10. PART SELECTION UX

## 10.1 Section/category navigation

The player must still be able to navigate all original engineering sections.

Preserve every original section and its options.

The interface should make it clear:

- which section is currently active
- which sections are complete or unresolved
- which sections affect which rocket areas
- whether the current vehicle is valid

Use a clean section selector, possibly along the left edge or top edge.

Each section should have:

- name
- state
- visual icon / symbol where helpful
- hover animation
- selected state
- clear connection to the rocket highlight

## 10.2 Option cards

For the active section, display available parts/options using animated cards or a tray.

Card behavior should inherit the satisfying motion language from previous phases.

Each option should show relevant existing data such as:

- name
- brief description
- cost
- build time
- mass
- thrust
- power
- reliability or risk
- key pros/cons
- technical role

Use the real values from the current game.

Do not invent stats.

## 10.3 Card-to-rocket relationship

When hovering an option card:

- highlight the rocket section affected
- preview the potential visual change where feasible
- update contextual engineering summaries
- show what will be replaced or changed

When selecting a card:

- animate the installation/change
- update the rocket
- update metrics
- confirm visually

This should be satisfying.

---

# 11. INSTALLATION / REPLACEMENT ANIMATION

## 11.1 Desired feel

Changing a component must not feel like a silent value swap.

There should be a clear “assembly” sensation.

Possible animation ideas:

- component fades / slides / lowers into place
- gantry arm / support motion
- replacement part lifts in
- section reconfigures with a mechanical snap
- contextual highlight pulse
- status panel confirms update

Keep it clean and moderately quick.

## 11.2 Speed

Assembly animations should be satisfying but not slow.

Suggested feeling:

- visible enough to be rewarding
- short enough to keep workflow fast

Avoid long cinematic delays every time a player compares parts.

## 11.3 Interruptions

If the player rapidly switches between options:

- prevent broken intermediate states
- safely cancel / retarget in-progress preview animations
- ensure the rocket always settles into the correct actual selected configuration

No duplicated or desynced part visuals.

---

# 12. ENGINEERING METRICS AND TECHNICAL PANELS

## 12.1 Preserve all key engineering information

Vehicle Assembly must continue exposing the important live figures.

Include the actual existing values wherever appropriate, such as:

- rocket delta-v available vs required
- spacecraft delta-v available vs required
- payload capacity vs selected science payload
- electrical power supplied vs required
- lift-off mass
- thrust-to-weight ratio
- uncertainty reserve / margin
- budget remaining
- time remaining or build-time effect
- validation warnings or errors

Use the authoritative calculations from the actual existing systems.

## 12.2 Presentation style

The metrics panel should be clearer and more exciting than before.

It should feel like a live engineering dashboard.

Use:

- animated numbers
- readable hierarchy
- colored state indicators
- compact gauges
- progress bars where meaningful
- warning emphasis
- hover explanations / tooltips

But do not turn it into a generic corporate dashboard.

Keep it game-like and readable.

## 12.3 Collapsible panel

The metrics panel should be a floating overlay that can be:

- visible by default
- collapsed to free more scene space
- reopened easily
- optionally auto-hide if the user prefers

Make the default behavior sensible.

---

# 13. LAUNCH SITE AND CONTEXTUAL SCENES

The original engineering flow includes launch-site selection / launch context.

Preserve that functionality.

## 13.1 Launch site representation

When the player enters or selects the launch-site-related section:

Consider switching or extending the hangar presentation in a visually coherent way.

Possible approaches:

- show a launch-site map overlay while keeping the rocket in the hangar
- temporarily show the rocket on a pad / launch context preview
- show site-specific contextual information in an overlay panel

Choose the cleanest approach that preserves immersion and usability.

## 13.2 Preserve actual gameplay

Do not remove or simplify the site-selection logic.

Keep the actual launch-site rules, values and engineering implications intact.

---

# 14. READABILITY AND FULLSCREEN STANDARDS

The user wants immersive fullscreen scenes, but usability must remain strong.

## 14.1 Readability rules

Ensure:

- text remains readable at 1920×1080
- panels don’t become too transparent to read
- small engineering values are legible through the CRT
- hover states are obvious
- focused selection is unmistakable
- rocket is not hidden behind oversized opaque UI

## 14.2 Resolutions

Support the display systems already implemented in earlier phases.

Verify the screen works correctly in:

- windowed mode
- borderless fullscreen
- fullscreen
- common 16:9 resolutions, especially 1920×1080

## 14.3 Overlay scalability

UI anchors and panel sizes must adapt correctly.

The fullscreen scene should continue to feel well-composed at different window sizes.

---

# 15. SHARED IMMERSIVE SCENE SHELL

Introduce or refine a reusable fullscreen scene-shell system.

## 15.1 Purpose

This shell should support:

- full-bleed 3D/2.5D scene
- hovering overlay UI
- collapsible edge panels
- CRT compatibility
- global screen movement compatibility
- reusable top/bottom/side control zones

## 15.2 Scope for this phase

Use the shell fully in Vehicle Assembly.

If there is a safe, low-risk opportunity to structure it so Mission Control can later adopt it more fully, do so.

But do not derail Phase 5 by rewriting Phase 4 extensively.

The main deliverable remains Vehicle Assembly.

---

# 16. PHASE 4 FOLLOW-UP ARCHITECTURAL NOTE

The user provided additional feedback on Mission Control:

- the mission scene should be more fullscreen
- overlay UI should hover instead of boxing it in
- the rocket scene should remain alive with idle animation
- mission contexts should feel more visually distinct

You do NOT need to fully rework Phase 4 now unless you can do so safely via a shared shell improvement.

However:

- architect Phase 5 in a way that supports this fullscreen-overlay direction
- keep the shell reusable
- if a small safe Mission Control layout improvement naturally follows from this reusable shell, include it only if it does not risk breaking verified Phase 4 behavior

Vehicle Assembly is still the priority.

---

# 17. TECHNICAL ARCHITECTURE

Use a modular architecture.

A conceptual structure might be:

```text id="mz5h0f"
VehicleAssemblyScreen
├── FullscreenSceneShell
│   ├── AssemblyViewportContainer
│   │   └── AssemblySubViewport
│   │       └── AssemblyHangar3D
│   │           ├── Camera3D
│   │           ├── HangarEnvironment
│   │           ├── RocketRoot
│   │           ├── SupportEquipment
│   │           ├── Lights
│   │           └── AmbientAnimationController
│   ├── OverlayTopBar
│   ├── OverlaySectionSelector
│   ├── OverlayMetricsPanel
│   ├── OverlayPartTray
│   ├── OverlayContextInspector
│   └── OverlayControls
└── VehicleAssemblyController
```

Adapt to the actual project.

## 17.1 Suggested responsibility split

**Vehicle logic**

- existing engineering rules
- selected options
- calculations
- validation

**RocketVisualController**

- maps actual configuration to modular rocket visuals
- handles highlighting
- handles installation / replacement animations

**AssemblyHangarController**

- environment setup
- ambient life
- camera
- support equipment / visual staging

**OverlayUIController**

- section selector
- cards
- metrics
- contextual info
- panel collapse/reveal
- confirmations

**VehicleAssemblyCoordinator**

- connects actual vehicle state to visual and UI layers
- preserves original flow

Do not duplicate existing calculations if avoidable.

The engineering logic remains authoritative.

---

# 18. GODOT IMPLEMENTATION GUIDELINES

Use Godot 4.7-compatible systems.

Appropriate tools may include:

- `SubViewport`
- `SubViewportContainer`
- `Control`
- `CanvasLayer`
- `Camera3D`
- `AnimationPlayer`
- `Tween`
- `MeshInstance3D`
- `Node3D`
- `WorldEnvironment`
- `GPUParticles3D` where appropriate
- shared shader/material systems from previous phases

Use efficient geometry and sensible materials.

Do not create a giant unmaintainable single script.

---

# 19. PERFORMANCE

Target a smooth experience on normal Windows machines.

Use:

- low-poly models
- reusable geometry/materials
- moderate texture sizes
- controlled lighting complexity
- efficient animation logic
- no unnecessary per-frame allocations
- restrained particles

The fullscreen hangar scene must remain performant.

Avoid turning this into the heaviest scene in the game unless absolutely necessary.

---

# 20. IMPLEMENTATION ORDER

Implement the phase incrementally.

## STEP A — Audit and preserve

- inspect current Vehicle Assembly implementation
- identify all gameplay responsibilities to preserve
- identify current engineering values and UI interactions
- identify actual data/model flow
- confirm project still runs before modifications

## STEP B — Fullscreen scene shell

- create or refine the reusable fullscreen immersive shell
- verify CRT compatibility
- verify overlay input remains aligned
- verify collapsible panels work

## STEP C — Hangar prototype

- build the fullscreen hangar
- place the large rocket
- create initial composition
- add core lighting and atmosphere
- verify the rocket is the clear hero object

## STEP D — Modular rocket mapping

- connect real engineering configuration to rocket visuals
- ensure major sections visually update correctly
- verify no gameplay state is altered

## STEP E — Section highlight + option workflow

- implement section selector
- implement contextual rocket highlighting
- implement option tray/cards
- implement preview and selection behavior

## STEP F — Installation animations

- add part replacement / installation feedback
- ensure rapid switching remains stable
- visually confirm updates

## STEP G — Engineering dashboard

- build the overlay metrics panel
- animate live engineering values
- add validation warnings
- add collapse/reopen behavior

## STEP H — Launch site / contextual flows

- integrate launch-site-related assembly/selection presentation
- ensure actual logic remains intact

## STEP I — Polish

- ambient animation
- readability pass
- layout pass
- hover/selection polish
- lighting refinement
- overlay behavior refinement

## STEP J — Regression testing

- confirm calculations unchanged
- confirm navigation unchanged
- confirm no critical errors
- confirm old functionality preserved

---

# 21. ACCEPTANCE CRITERIA

Do not call Phase 5 complete unless these are true:

## Fullscreen experience

- [ ] Vehicle Assembly is now a fullscreen immersive scene
- [ ] The rocket/hangar scene dominates the screen
- [ ] Overlay UI floats above the scene
- [ ] At least some panels are collapsible / retractable
- [ ] CRT and screen-movement systems still work correctly

## Environment

- [ ] A stylized 3D/2.5D hangar exists
- [ ] The scene has ambient life
- [ ] Lighting is attractive and coherent
- [ ] The hangar feels like a real assembly space

## Rocket

- [ ] The rocket is large and visually central
- [ ] Major selected vehicle components affect the actual rocket visual
- [ ] Rocket sections can be highlighted
- [ ] Rocket updates stay synchronized with real selections
- [ ] Installation/replacement animations work

## UI / workflow

- [ ] All original engineering sections remain accessible
- [ ] All original options remain accessible
- [ ] Option cards are animated and readable
- [ ] Hovering a part previews/highlights the correct section
- [ ] Selecting a part updates the vehicle correctly
- [ ] The live stats panel reflects the authoritative calculations
- [ ] Metrics remain readable at 1920×1080
- [ ] The player can focus on the rocket without losing access to critical info

## Gameplay preservation

- [ ] Engineering calculations are unchanged
- [ ] Vehicle validation logic is unchanged
- [ ] Budget / schedule / power / mass / delta-v logic is unchanged
- [ ] Launch-site logic is preserved
- [ ] Scene navigation remains functional
- [ ] No critical bugs or errors appear

## Stability / quality

- [ ] No major performance regression
- [ ] Fullscreen/windowed modes still function
- [ ] Input alignment remains correct
- [ ] Rapid switching between options does not break visuals
- [ ] Phase 1–4 systems remain intact

---

# 22. TESTING REQUIREMENTS

Test more than the happy path.

## Scenario A — Normal build flow

- enter Vehicle Assembly
- inspect sections
- change several parts
- confirm rocket updates visually
- verify metrics update correctly

## Scenario B — Rapid comparison

- hover and switch quickly across several part cards
- ensure previews/highlights do not break
- ensure the final selected state is correct

## Scenario C — Invalid / warning-producing configuration

- choose options that create warnings or edge conditions
- verify dashboard warnings and metrics remain accurate

## Scenario D — Launch site / contextual section

- test relevant section(s)
- verify logic and presentation remain correct

## Scenario E — Display and layout

- test at 1280×720 and 1920×1080
- test windowed and borderless fullscreen
- ensure readability and composition remain good

If automated tests are limited, clearly say what requires manual verification.

Do not falsely claim visual behavior was verified unless rendered and inspected.

---

# 23. FINAL REPORT REQUIREMENTS

When complete, provide:

1. Summary of implemented Phase 5 features
2. Important files created/modified
3. Explanation of the fullscreen shell architecture
4. Explanation of the hangar scene
5. Explanation of rocket modularity and how it maps to the real vehicle data
6. Explanation of section highlighting and installation animation
7. Explanation of the overlay UI and collapsible panels
8. Confirmation that engineering/gameplay calculations were preserved
9. Testing results
10. Known issues or placeholders
11. Instructions for manually previewing and testing Vehicle Assembly
12. Note whether any safe shared-shell improvements were made that could later help Mission Control adopt the same fullscreen overlay structure

---

# 24. WORKING RULES

- Preserve all actual gameplay logic
- Preserve Phases 1–4
- Do not rewrite unrelated systems
- Do not simplify the engineering model
- Do not copy proprietary assets from inspiration games
- Keep the implementation modular
- Use Godot 4.7-compatible APIs
- Avoid destructive Git operations
- Do not push to a remote without authorization
- Do not proceed to Phase 6 before this phase is reviewed

---

# 25. FINAL DIRECTIVE

We want Vehicle Assembly to become one of the signature screens of the game.

The player should open it and immediately feel:

- the rocket is huge
- the hangar is alive
- the UI is game-like and satisfying
- every engineering choice has visible physical meaning
- the screen feels immersive and fullscreen
- the interface hovers around the experience rather than trapping it

The science and engineering underneath must remain exactly trustworthy.

**Preserve the engineering. Transform the presentation.**

Begin Phase 5 now.

Implement the reusable fullscreen immersive shell, then build the fullscreen stylized Vehicle Assembly hangar with floating overlay controls, rocket-centered composition, animated part installation, and preserved engineering logic.
