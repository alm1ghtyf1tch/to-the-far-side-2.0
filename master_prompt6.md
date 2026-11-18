# TO THE FAR SIDE — PHASE 5.5: PROJECT ROGUE ROCKET

## Rocket-Building Roguelite, Agency Management, Science Progression, Mission Runs, Endless Mode, Git Checkpoint & macOS Export

# 0. ROLE AND OBJECTIVE

You are continuing development of **To the Far Side**, an existing Godot 4.7 / GDScript lunar mission simulator.

The game is undergoing a visual overhaul inspired by the tactile UI of Balatro and the stylized 2.5D environments of R.E.P.O. and Lethal Company.

Phases 1–4 have been implemented and reviewed. Phase 5, the fullscreen Vehicle Assembly redesign, is currently underway or nearing completion.

The player has now approved an additional major gameplay direction:

**Transform To the Far Side into a replayable rocket-building roguelite with a structured run mode, optional endless progression, meaningful agency management, component drafting, scientific research and interactive mission operations.**

This becomes **Phase 5.5 — Project Rogue Rocket**.

It must be completed before Phase 6's final review, reporting and endings redesign.

We are NOT abandoning the original game. We are extending it with an additional gameplay mode built on the existing scientific and engineering systems.

The main requirements are:

1. Preserve the original authored campaign.
2. Introduce a rocket-building roguelite mode.
3. Make agency management, engineering and science equally meaningful.
4. Deepen flight operations through actual player decisions.
5. Introduce genuine scarcity and trade-offs.
6. Support standard runs and endless progression.
7. Reuse the existing 2.5D presentation.
8. Save and push the verified project to the user's authorized GitHub remote.
9. Add a playable macOS build for testing on an Apple Silicon MacBook Neo.

This is an implementation task, not only a game-design discussion.

However, it must be approached incrementally. Do not attempt to replace all existing systems in a single untested rewrite.

---

# 1. IMMEDIATE PRIORITY — SAVE AND PUSH THE CURRENT PROJECT

Before beginning the new gameplay expansion, preserve the working visual overhaul.

## 1.1 Check the current working state

Inspect:

- Git working tree.
- Current branch.
- Current remote.
- Pending modifications.
- Untracked project assets.
- Current Godot project validity.
- Existing export configuration.
- Phase 5 completion status.

If Phase 5 is still being modified, do not interrupt an active file operation or commit an unverified broken state.

Finish the current safe milestone or use the latest verified commit for the checkpoint.

## 1.2 Commit the project

Once the working state passes appropriate checks:

- Stage relevant source code.
- Include new Godot scenes, shaders, models and assets.
- Include appropriate project configuration and documentation.
- Exclude temporary files, editor caches, generated build outputs, credentials and secrets.
- Create a descriptive checkpoint commit.

Suggested commit message:

`Checkpoint: visual overhaul phases 1-5`

Adjust the message to match the work actually completed.

## 1.3 Push to GitHub

Push the checkpoint to the existing authorized development branch on the user's intended repository.

Before pushing, verify the remote and repository ownership.

Do not assume that the original collaborator's repository is the correct push destination.

Do not force-push, overwrite remote changes, rewrite Git history or delete branches.

If the remote contains conflicting changes, stop and report the conflict rather than overwriting them.

After the push, report:

- Repository URL.
- Branch.
- Commit SHA.
- Push result.

**The user has explicitly requested a Git push of this project checkpoint.**

If authentication or permissions prevent the push, provide the exact blocker and leave the local commit intact.

---

# 2. ADD A macOS BUILD

The user wants to play and test the game on an Apple Silicon MacBook Neo.

This requirement is independent of the new roguelite systems.

Create a macOS build of the latest stable, verified project first. Update it again after Phase 5.5 is complete.

## 2.1 Export target

Target:

- Godot 4.7-compatible export templates.
- macOS.
- Apple Silicon ARM64 compatibility.
- Prefer the official Universal 2 build where available.
- A self-contained downloadable ZIP containing the playable `.app`.

Do not downgrade the project to Godot 4.6.

## 2.2 Export configuration

Inspect `export_presets.cfg`.

Add or correct a `macOS` export preset.

Configure:

- Suitable application name.
- Valid bundle identifier.
- Correct version metadata.
- Correct project resources.
- Proper game icon where available.
- Compatible architecture.
- Correct export template.
- Appropriate development signing configuration.

Do not put passwords, private keys or certificates into Git.

For internal testing without an Apple Developer ID certificate, use Godot's supported ad-hoc signing configuration where appropriate.

Do not falsely describe an ad-hoc-signed build as notarized.

## 2.3 Build output

Preferred deliverable:

`ToTheFarSide-macOS-Dev.zip`

Use a versioned filename if appropriate.

If exporting from Windows, prefer the ZIP export rather than transferring an unpackaged `.app` bundle, as executable file permissions may not survive correctly.

The ZIP must contain a complete playable macOS application, not merely a `.pck` file or copied project folder.

## 2.4 Distribution

Make the build accessible to the user.

Prefer adding a manually triggered GitHub Actions build workflow that:

- Uses a compatible Godot version and export templates.
- Exports the macOS build.
- Validates the export result.
- Uploads the finished ZIP as a downloadable GitHub Actions artifact.

If the environment permits building the archive immediately, do so.

Keep generated binaries out of ordinary source commits unless the repository has an established policy for storing builds.

Do not automatically create a public release or distribute the build beyond the user's intended repository without approval.

## 2.5 MacBook Neo considerations

The user's MacBook Neo has an Apple A18 Pro and 8 GB of unified memory.

Optimize the build accordingly.

Check:

- 3D viewport performance.
- CRT shader overhead.
- Memory consumption.
- Resolution scaling.
- Fullscreen and windowed behavior.
- Input alignment.
- UI readability.

The laptop has a 2408×1506 native display, so the game should also handle an approximately 16:10 aspect ratio, not only 16:9.

Ensure the fullscreen overlay interfaces remain usable on this display shape.

Do not claim hardware testing was completed unless the game was actually run on macOS.

## 2.6 Documentation

Provide a short Mac installation and testing guide.

Explain that an unnotarized development build may require approval through macOS System Settings → Privacy & Security, or the appropriate supported Open workflow.

Do not suggest globally disabling Gatekeeper.

Report the build output location and download link if successfully uploaded.

---

# 3. NEW GAMEPLAY IDENTITY — A ROCKET-BUILDING ROGUELITE

The new mode is called **Rogue Rocket** during development.

The name may be changed later.

The design concept:

**The player creates a space agency, acquires and engineers rocket components, manages financial and material constraints, selects meaningful scientific objectives, and commands a sequence of lunar missions.**

Every mission creates a different engineering problem.

The objective is not to buy every best component.

The objective is to construct a viable mission architecture from limited resources, opportunities and available hardware.

The game must reward clever planning, adaptation, scientific thinking and calculated risk.

## 3.1 Three interconnected pillars

**AGENCY MANAGEMENT**

Controls:

- Funding.
- Procurement.
- Manufacturing.
- Contracts.
- Schedule.
- Inventory.
- Facilities or relevant operational capabilities.
- Project events.
- Long-term run progression.

**ENGINEERING**

Controls:

- Rocket architecture.
- Component selection.
- Component drafting.
- Hardware modifications.
- Mass.
- Thrust.
- Delta-v.
- Power.
- Reliability.
- Testing.
- Integration.

**SCIENCE**

Controls:

- Scientific objectives.
- Landing-site selection.
- Instrument selection.
- Experiment compatibility.
- Research opportunities.
- Surface operations.
- Scientific discoveries.
- Research progression.

**FLIGHT OPERATIONS**

Connects all three pillars by testing the resulting spacecraft and mission strategy.

The systems must not feel independent.

A decision in one area should have consequences in the others.

---

# 4. PRESERVE THE ORIGINAL CAMPAIGN

The current 11-stage authored lunar mission campaign must remain available.

Do not remove or overwrite it.

Introduce game-mode selection:

**STORY CAMPAIGN**

- Existing campaign.
- Existing authored progression.
- Existing scientific calculations.
- Existing narrative.
- Existing outcomes.

**ROGUE ROCKET**

- New run-based mode.
- Generated or drafted mission contracts.
- Persistent agency state within a run.
- Component drafting.
- Scientific research progression.
- Development events.
- Multiple missions.
- Optional endless continuation.

Keep save data separate between modes.

Do not allow a new roguelite economy system to silently break the original campaign.

Reuse existing models, interfaces and calculations wherever possible.

---

# 5. RUN STRUCTURE

## 5.1 Standard Run

A standard run contains three successive mission contracts.

The number three is an initial design target, subject to playtesting.

Mission difficulty increases across the run.

After the third mission, the player receives a final agency evaluation.

The player may finish the run or continue into Endless Mode.

A full standard run should eventually aim for approximately 45–75 minutes once the systems have been streamlined.

Treat this as a playtesting target, not a guarantee.

## 5.2 Endless Mode

After finishing a standard run, allow the player to continue the same agency.

Generate additional mission contracts with increasing complexity.

Difficulty should rise through meaningful mission constraints, including:

- More demanding scientific objectives.
- Reduced budget flexibility.
- More complex mission architectures.
- Contractor or material constraints.
- Higher operational requirements.
- More challenging but feasible landing sites.
- Tighter schedule requirements.

Do not simply multiply enemy health or invent unrealistic physics penalties.

The run continues until the agency can no longer sustain operations or another clearly defined terminal condition occurs.

## 5.3 Persistent agency state within a run

Between missions, preserve:

- Agency name and identity.
- Available budget.
- Relevant material inventory.
- Owned hardware and blueprints.
- Unused equipment.
- Qualified components.
- Research progress.
- Contract history.
- Agency reputation.
- Persistent event consequences.
- Mission results.
- Current difficulty/progression level.

Distinguish reusable designs from physical hardware.

A blueprint may remain permanently available within the run, while an expended stage cannot be reused as physical hardware unless a supported recovery/reuse system permits it.

Do not imply that all spacecraft hardware automatically returns intact.

---

# 6. PLAYER-CREATED SPACE AGENCY

At the start of a roguelite run, allow the player to create a basic agency identity.

Include:

- Agency name.
- Simple emblem or visual identity selection, if practical.
- Initial mission doctrine.
- Starting resources.

Avoid spending excessive development time on a complex logo editor.

The agency identity should persist across missions in the run.

## 6.1 Starting doctrines

Create a small set of meaningful agency philosophies.

Examples:

**SCIENCE FIRST**

- Greater emphasis on scientific contracts.
- More demanding research objectives.
- Potential access to scientific opportunities.
- Tighter budget or payload trade-offs.

**ENGINEERING INNOVATION**

- More experimental technology opportunities.
- More qualification uncertainty.
- Additional flexibility in hardware development.

**CONSERVATIVE PROGRAMME**

- Greater emphasis on reliability.
- More constrained research or development flexibility.
- Strong safety-oriented contract expectations.

**RAPID DEVELOPMENT**

- Greater schedule pressure.
- More aggressive procurement choices.
- Reduced time available for repeated qualification work.

These must be balanced starting conditions, not permanent overpowering buffs.

Use data-driven configurations.

---

# 7. REAL RESOURCE SCARCITY

This is one of the most important changes.

The existing campaign often provides enough funding to select expensive components without meaningful financial consequences.

Rogue Rocket must solve this.

## 7.1 Resources

Introduce a manageable economy.

Suggested initial resources:

- Money.
- Development time.
- Procurement or material stock.
- Testing capacity.
- Research knowledge.
- Existing engineering margins.

Do not add dozens of currencies.

Only add a resource when it produces interesting decisions.

## 7.2 Materials

The player should sometimes need to obtain materials or manufacturing capacity before building particular components.

Possible categories:

- Structural materials.
- Propulsion-related components.
- Electronics.
- Specialized scientific hardware.

These are abstract production resources, not a full realistic supply-chain simulator.

Do not require individual screws, bolts, wires or raw ore quantities.

## 7.3 Financial pressure

Tune contract budgets and component prices so that:

- Premium components are attractive but costly.
- Buying the most expensive option everywhere is usually impractical.
- Cheaper components have genuine advantages.
- Testing creates financial trade-offs.
- Backup systems cost money and mass.
- Materials and schedule matter.
- Players have multiple viable approaches.

Do not simply make every component more expensive.

Evaluate complete mission feasibility and opportunity costs.

## 7.4 Run-threatening consequences

The player should face meaningful setbacks.

Examples:

- Project overruns.
- Contract penalties.
- Lost hardware.
- Manufacturing delays.
- Failed qualification tests.
- Reduced agency reputation.
- Insufficient funding for another mission.

Avoid unavoidable instant failures caused solely by random events.

Provide recovery choices when feasible.

---

# 8. ROGUELIKE COMPONENT DRAFTING

This is the defining rocket-builder mechanic.

Rocket parts must function similarly to draftable cards in a deck-building game.

However, the underlying engineering remains physically grounded.

## 8.1 Component pools

Inspect the existing vehicle data and organize draftable options by appropriate categories.

Examples:

- First stages.
- Upper stages.
- Boosters.
- Engines.
- Fuel systems.
- Crew modules.
- Lunar landers.
- Power systems.
- Navigation equipment.
- Communications.
- Safety equipment.

Do not assume the exact categories without checking existing data.

## 8.2 Drafting

At suitable development milestones, offer a limited selection of available components.

An initial prototype can present three choices.

The player may:

- Select an offered part.
- Purchase it if affordable.
- Reserve it for later if that mechanic is implemented.
- Skip a draft for a modest alternative resource benefit.

The exact options depend on:

- Run seed.
- Contract requirements.
- Agency doctrine.
- Current inventory.
- Technology availability.
- Procurement conditions.

Do not allow every component to be purchased from an unlimited global catalog in Rogue Rocket mode.

## 8.3 Build feasibility

A generated component offer must obey actual equipment compatibility rules.

Avoid creating impossible missions because no compatible propulsion or spacecraft components appeared.

Maintain a viable baseline selection or an emergency procurement fallback.

The player may make poor choices, but the game must not force failure before meaningful decisions occur.

## 8.4 Part differences

Cards should show actual engineering values.

Include relevant:

- Mass.
- Thrust.
- Specific impulse.
- Propellant capacity.
- Power.
- Cost.
- Development time.
- Reliability.
- Material requirements.
- Compatibility.

Use existing calculations and data wherever possible.

## 8.5 Component variety

Avoid simple rarity tiers where every rare part is objectively superior.

Create trade-offs.

An experimental engine may be more efficient but require more expensive qualification.

A simpler stage might be heavier but reliable and available immediately.

A lightweight subsystem might save mass but offer less redundancy.

Both premium and inexpensive components should have legitimate uses.

---

# 9. ENGINEERING WORKBENCH

The player should eventually be able to engineer or modify certain components.

Implement a limited initial customization system.

Possible modifications:

- Propellant loading.
- Tank sizing within supported limits.
- Payload allocation.
- Power reserve configuration.
- Structural safety margin.
- Redundancy configuration.
- Engine qualification level.
- Selected subsystem upgrades.

Use physically and mathematically consistent transformations.

Do not allow arbitrary changes to thrust, efficiency or reliability without appropriate constraints.

Every modification should have a cost or trade-off.

Full freeform rocket-engine design is outside the initial MVP scope.

Prefer a working modification system with three or four meaningful choices over a huge nonfunctional editor.

---

# 10. AGENCY MANAGEMENT EVENTS

Introduce development-phase events.

Examples:

- Contractor delay.
- Additional safety requirement.
- Unexpected procurement opportunity.
- Manufacturing quality concern.
- Research grant opportunity.
- Supplier component shortage.
- Political deadline pressure.
- Scientific discovery changing mission priorities.

Each event must have:

- Trigger conditions.
- Clear description.
- Relevant choices.
- Resource consequences.
- Potential future implications.
- An appropriate chance of occurrence where randomness is used.

Events should be sensitive to current agency state.

Do not present choices that are impossible due to insufficient resources without marking them unavailable.

Avoid events that exist only to deduct money.

Some events should offer positive opportunities.

The player should learn to prepare for categories of risk, rather than memorize a single scripted sequence.

---

# 11. SCIENCE AS A FULL GAMEPLAY PILLAR

Science must be equally important to engineering and management.

The Science Planner from Phase 3 should become more than a site and instrument selection screen.

## 11.1 Scientific objectives

At the start of each mission, offer research objectives based on the mission contract.

Examples:

- Lunar surface composition.
- Subsurface structure.
- Seismic studies.
- Thermal properties.
- Solar-wind interactions.
- Regolith investigation.
- Geological mapping.

Use scientifically credible objectives.

Do not introduce fantasy scientific facts.

## 11.2 Research drafting

Allow the player to select a limited research portfolio.

For example, a mission may offer three possible research objectives, from which the player selects one or two.

Objectives influence:

- Landing-site desirability.
- Required instruments.
- Mission time.
- Payload requirements.
- Potential rewards.
- Scientific opportunities.

This gives the Science team its own meaningful drafting decisions.

## 11.3 Instrument combinations

Introduce scientifically justified instrument synergies.

Examples:

- Seismic measurements combined with heat-flow observations improve the scope of lunar-interior investigations.
- Surface imagery combined with spectral measurements provides better geological context.
- Sample collection combined with appropriate analysis produces complementary scientific evidence.

Represent these through additional experiment objectives or knowledge rewards.

Do not invent unexplained mass, delta-v or physics bonuses.

## 11.4 Scientific operations

Add a lightweight interactive science-operations layer.

During lunar surface operations, the player should allocate limited resources among scientific tasks.

Resources may include:

- EVA time.
- Electrical energy.
- Available consumables.
- Instrument deployment time.
- Communication or data capacity.
- Crew workload.

The player must decide which experiments to prioritize.

Completing all experiments should not always be possible.

## 11.5 Scientific discoveries

Successful experiments should produce meaningful run rewards.

Possible rewards:

- Scientific knowledge.
- Reputation.
- Future research contracts.
- New instrument blueprints.
- Better information about certain mission risks.
- Research-related funding.

Maintain a distinction between scientifically credible discoveries and game abstractions.

Avoid claiming random fictional results are established real-world lunar facts.

## 11.6 Scientific failure

A mission may land successfully but fail to accomplish its research objectives.

That should matter.

Likewise, a mission may fail to complete every science task but still produce valuable data.

Science performance should have its own evaluation.

Do not treat science as an optional bonus disconnected from run progression.

---

# 12. ACTIVE FLIGHT OPERATIONS

Preserve the existing Phase 4 Mission Control and its fixed-camera visual identity.

Deepen the gameplay through meaningful command choices.

## 12.1 Three event categories

**ROUTINE OPERATIONS**

- Planned mission execution.
- Equipment activation.
- Maneuver confirmation.
- Status monitoring.

**SCIENTIFIC OPPORTUNITIES**

- Optional observations.
- Additional instrument use.
- Alternative science objectives.
- Opportunities enabled by remaining reserves.

**EMERGENCIES**

- Engine anomalies.
- Power problems.
- Navigation issues.
- Landing difficulties.
- Other events actually supported by the simulation.

## 12.2 Operational decision constraints

Available actions must depend on:

- Actual spacecraft configuration.
- Remaining propellant.
- Available delta-v.
- Equipment redundancy.
- Power.
- Crew and vehicle state.
- Mission trajectory.
- Relevant planning choices.

Do not offer actions that are physically impossible.

## 12.3 Strategic consequences

Flight outcomes should be influenced by earlier design decisions.

Examples:

- Extra propellant may allow a contingency burn.
- Redundant equipment may provide a recovery option.
- Better qualification testing may reduce relevant uncertainty.
- A limited science payload may restrict optional objectives.
- Insufficient power may force the player to prioritize instruments.

Do not create a separate random success percentage that ignores these systems.

## 12.4 Preserve minigames

Do not remove or rewrite the existing staging and landing minigames.

Integrate them appropriately.

New flight decisions should complement the current gameplay.

---

# 13. SCORING, REWARDS AND PROGRESSION

Every mission needs a clear evaluation.

Use multiple performance dimensions:

- Agency management.
- Engineering design.
- Flight operations.
- Scientific return.
- Mission safety.
- Contract fulfillment.

Do not simply assign one score based on total money saved.

## 13.1 Contract completion

Each mission has:

- Mandatory objectives.
- Optional objectives.
- Defined constraints.
- Clear rewards.
- Failure and partial-success conditions.

A mission can have partial success.

For example, a safe return with reduced science should be evaluated differently from complete spacecraft loss.

## 13.2 Run evaluation

After three missions:

- Calculate aggregate performance.
- Show agency development.
- Show cumulative science.
- Show engineering achievements.
- Show financial condition.
- Show major decisions and consequences.
- Assign an appropriate run grade.
- Offer Endless continuation if unlocked by the run's completion criteria.

## 13.3 Horizontal progression

Unlocks should primarily introduce new strategic possibilities.

Examples:

- New component families.
- Alternative mission doctrines.
- Additional scientific contracts.
- Unusual engineering architectures.
- New development-event types.
- More demanding mission categories.

Avoid permanent upgrades that simply make every later run easier.

The player should gain options and mastery, not an unbeatable advantage.

---

# 14. RUN GENERATION AND FAIRNESS

Use a reproducible seed system.

A generated run should be deterministic for gameplay-relevant random choices.

Separate presentation randomness from gameplay randomness.

Changing CRT settings or triggering animations must not affect future event draws.

## 14.1 Generate valid contracts

Every generated mission must satisfy reasonable feasibility constraints.

The game should verify that available technology, starter inventory, economic resources and procurement paths permit at least one viable mission plan.

Do not assume a contract is achievable simply because its numbers appear plausible.

## 14.2 Avoid unwinnable drafting

Provide reasonable safeguards against impossible combinations.

Possible solutions:

- Guaranteed baseline parts.
- Limited rerolls.
- Emergency procurement at a significant cost.
- Conditional draft pools.
- Contract generation aware of available equipment.

## 14.3 Controlled difficulty

Difficulty should increase through genuine decisions.

Do not produce impossible contracts by increasing requirements indefinitely.

If endless progression reaches practical engineering limits, generate increasingly difficult trade-offs and programme conditions rather than violating physical feasibility.

## 14.4 Seed sharing

Display the run seed in the run summary.

Allow players to enter a seed to replay the same challenge if practical.

This makes challenge comparisons and debugging easier.

---

# 15. SAVE SYSTEM

The new mode must support save/resume.

Persist:

- Current run mode.
- Seed.
- Random generator state or equivalent deterministic progression.
- Agency resources.
- Inventories.
- Contracts.
- Mission history.
- Selected vehicle configurations.
- Scientific research progress.
- Current stage.
- Outstanding events.
- Appropriate flight state.

Use a versioned save schema.

Do not overwrite Story Campaign saves.

Handle missing or outdated data safely.

A saved run must not reroll component offers or events when reopened.

---

# 16. PRESENTATION INTEGRATION

Reuse all completed visual systems.

**Agency management**

- Use the Phase 2 headquarters and its interactive departments.

**Engineering**

- Use the Phase 5 fullscreen assembly hangar.
- Show component drafts as animated cards and trays.
- Reflect part installation on the physical rocket.

**Science**

- Use the Phase 3 orbital Moon selector.
- Integrate research objectives, experiment cards and scientific operations.

**Mission Control**

- Use the Phase 4 space scene.
- Preserve the fixed-camera approach.
- Support the user's requested fullscreen scene with floating, retractable overlays when safely available.

Do not build a second, inconsistent UI framework for Rogue Rocket.

Use the existing CRT, animated cards, screen movement, display settings and visual language.

---

# 17. PROPOSED TECHNICAL ARCHITECTURE

Separate the roguelite layer from existing campaign logic.

A possible organization:

```text
res://systems/roguelite/
    run_manager.gd
    agency_state.gd
    contract_generator.gd
    component_draft.gd
    procurement_manager.gd
    development_events.gd
    science_research.gd
    science_operations.gd
    run_scoring.gd
    run_save_manager.gd

res://data/roguelite/
    contracts.json
    doctrines.json
    draft_pools.json
    development_events.json
    research_objectives.json
    experiment_synergies.json
    rewards.json

res://screens/roguelite/
    mode_selection/
    agency_creation/
    run_overview/
    contract_selection/
    run_results/
```

These are proposed locations, not mandatory file names.

Adapt the architecture to the actual project.

Use the existing scientific and vehicle calculations.

Avoid duplicating the rocket equation, flight outcome calculations or engineering validation.

Use adapters where the existing Campaign model is too tightly coupled to the original authored progression.

Do not make the original story campaign depend on Rogue Rocket data.

---

# 18. IMPLEMENTATION PLAN

Build a playable vertical slice before expanding content.

## MILESTONE 0 — CHECKPOINT AND MAC BUILD

Complete the verified Git checkpoint, push, export configuration and initial playable macOS ZIP.

Report the results.

## MILESTONE 1 — RUN FRAMEWORK

Implement:

- Story Campaign / Rogue Rocket mode selection.
- Agency creation.
- Run state.
- Mission contracts.
- Three-mission progression.
- Basic run results.
- Endless continuation framework.
- Save/resume.

Use simple contract templates initially.

## MILESTONE 2 — COMPONENT DRAFTING AND ECONOMY

Implement:

- Draft offers.
- Compatible part pools.
- Inventory and procurement.
- Resource expenditure.
- Real financial scarcity.
- Vehicle Assembly integration.
- Component selection and validation.

This must produce a playable engineering decision loop.

## MILESTONE 3 — MANAGEMENT EVENTS

Implement:

- Development cycles.
- Limited project actions.
- Testing choices.
- Contractor events.
- Resource consequences.
- Persistent agency effects.

Ensure players face meaningful opportunity costs.

## MILESTONE 4 — SCIENCE GAMEPLAY

Implement:

- Research objective drafting.
- Instrument synergies.
- Landing-site-specific scientific opportunities.
- Limited science operations.
- Research rewards.
- Science evaluation.

Science must have meaningful decisions before and during flight.

## MILESTONE 5 — FLIGHT OPERATIONS

Integrate existing mission logic with new operational opportunities and contingency choices.

Test that available choices depend on actual vehicle capabilities.

Do not rewrite original flight physics.

## MILESTONE 6 — BALANCING AND ENDLESS

Implement:

- Difficulty progression.
- Feasibility checks.
- Standard run completion.
- Endless continuation.
- Scoring.
- Seed reproducibility.
- Additional contract variety.

## MILESTONE 7 — VALIDATION AND BUILD UPDATE

Test all systems.

Resolve critical bugs.

Create an updated macOS development export.

Commit and push the completed, verified gameplay phase to the authorized branch.

---

# 19. ACCEPTANCE CRITERIA

## Run structure

- [ ] Story Campaign remains playable.
- [ ] Rogue Rocket mode is selectable.
- [ ] Agency creation works.
- [ ] Multiple missions share persistent run resources.
- [ ] A three-mission standard run can complete.
- [ ] Endless mode can continue the agency.
- [ ] Run results reflect actual outcomes.
- [ ] Save/resume works.

## Engineering

- [ ] Components are draftable.
- [ ] Draft offers are compatible with mission requirements.
- [ ] Procurement consumes resources.
- [ ] Expensive components create actual opportunity costs.
- [ ] Rocket configuration updates visually.
- [ ] The vehicle remains governed by real calculations.
- [ ] Basic engineering modifications work if implemented.
- [ ] Infeasible configurations show clear warnings.

## Management

- [ ] Agency finances persist.
- [ ] Development cycles work.
- [ ] Events produce meaningful choices.
- [ ] Project actions consume appropriate resources.
- [ ] Budget and schedule pressure matter.
- [ ] Poor decisions can threaten the run.
- [ ] Recoverable setbacks offer meaningful responses.

## Science

- [ ] Research objectives are selectable.
- [ ] Scientific objectives affect mission planning.
- [ ] Instruments have credible combined uses.
- [ ] Science operations offer meaningful allocation decisions.
- [ ] Scientific results affect progression.
- [ ] Science scoring is distinct from generic mission success.

## Flight

- [ ] Existing phases and minigames work.
- [ ] New operational decisions respect actual spacecraft capabilities.
- [ ] Flight consequences reflect earlier decisions.
- [ ] Successful and unsuccessful missions both resolve correctly.
- [ ] No duplicate mission outcomes occur.

## macOS and Git

- [ ] Current verified source is committed.
- [ ] Source is pushed to the authorized remote branch.
- [ ] A valid macOS export preset exists.
- [ ] A playable macOS ZIP is produced.
- [ ] The build is accessible to the user.
- [ ] Mac testing instructions are provided.
- [ ] Generated binaries and secrets are excluded from source commits.
- [ ] An updated export is prepared after the gameplay expansion.

---

# 20. TESTING REQUIREMENTS

Test multiple runs and configurations.

At minimum:

1. Complete the original Story Campaign without roguelite features affecting it.
2. Complete a standard Rogue Rocket run.
3. Continue the completed run into Endless Mode.
4. Verify component drafting with multiple seeds.
5. Test constrained budgets and expensive hardware choices.
6. Test an invalid rocket configuration.
7. Test a mission with limited science capacity.
8. Test research objectives and instrument synergy conditions.
9. Test operational decisions affected by vehicle design.
10. Test agency financial failure or another valid run-ending condition.
11. Save and resume during planning.
12. Save and resume between missions.
13. Verify deterministic behavior for repeated seeds.
14. Test UI responsiveness and scene transitions.
15. Validate Windows and macOS export configurations.

Run an automated simulation over numerous generated seeds where practical to detect infeasible contracts.

Do not claim a generated mission is fair merely because a few seeds worked.

Distinguish mathematical feasibility checks from human playtesting.

---

# 21. SCOPE CONTROL

This is a large gameplay expansion.

Prioritize a complete playable vertical slice over dozens of unfinished systems.

For the initial MVP:

- Use a modest number of curated contract templates.
- Use a limited but meaningful component draft pool.
- Use a small number of management events.
- Use several scientifically valid research objectives.
- Use a few meaningful operational decisions.
- Support the three-mission run and endless continuation.

Add more content after the core loop is stable.

Avoid implementing every conceivable mechanic immediately.

Do not create a massive technology tree, a full factory simulator, or a physically unrestricted spacecraft CAD system in the first version.

The main objective is to create a replayable system with meaningful strategic consequences.

---

# 22. FINAL DELIVERABLES

Provide a report containing:

1. Git checkpoint status, branch, commit SHA and remote.
2. macOS export status and artifact location.
3. The implemented game-mode architecture.
4. Agency management systems.
5. Rocket drafting and economy mechanics.
6. Science gameplay mechanics.
7. Flight operations changes.
8. Run and Endless progression.
9. Scoring and save system.
10. Test results.
11. Known balance issues.
12. Remaining placeholders.
13. Instructions for playing the new mode.
14. Instructions for downloading and launching the macOS build.
15. A list of future improvements.

Clearly distinguish implemented features from proposals.

Do not claim that the user-tested Mac build works until it has actually been launched on compatible Mac hardware.

---

# 23. FINAL DIRECTIVE

**To the Far Side must become a rocket-building roguelite in which the player creates an agency, assembles a mission vehicle from limited opportunities, establishes a scientific research strategy, and commands the spacecraft they designed.**

The player's decisions must create consequences across all three pillars.

Agency management affects engineering possibilities.

Engineering affects scientific capacity and flight capabilities.

Science affects contract priorities, instrument selection and future rewards.

Flight operations test every previous decision.

The game must provide a reason to start another mission and discover a different strategy.

**Immediate priority: safely save and push the current verified project, and create the macOS development build.**

Then, after Phase 5 is completed and verified, begin Phase 5.5 with a small but fully playable roguelite vertical slice.

Do not proceed to Phase 6 until the gameplay expansion has been reviewed.

PRESERVE THE SCIENCE.

MAKE THE TRADE-OFFS MATTER.

MAKE EVERY ROCKET BUILD DIFFERENT.

MAKE EVERY RUN WORTH PLAYING.

# BEGIN PROJECT ROGUE ROCKET.
