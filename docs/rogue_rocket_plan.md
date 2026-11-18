# Project Rogue Rocket: implementation boundary

Requested by `master_prompt6.md`, which names this gameplay expansion Phase 5.5.
The final review/endings Phase 6 remains outside this task.

## Milestone order

0. Preserve Phases 1–5, verify ownership, commit/push checkpoint, configure and
   produce the initial Universal 2 macOS development build. Confirm archive
   structure and 16:10 layout separately from unavailable Mac hardware testing.
1. Mode selection, agency creation, isolated run state, versioned save/resume,
   three successive contracts, evaluation and optional Endless continuation.
2. Component offers, paid physical inventory/manufacturing, limited materials,
   guaranteed baseline procurement, and the existing assembly scene.
3. Four management actions per contract, qualification, procurement/research,
   seeded contractor/grant/quality/supplier events and recovery decisions.
4. Curated research portfolios, actual site/instrument planning on the existing
   Moon, credible instrument combinations and limited surface work allocation.
5. Original flight playback/minigames with capability-gated cruise/backup/science
   commands. Save flight at reproducible phase boundaries without rerolling it.
6. Seed sweeps, scarcity/feasibility checks, actual outcome scoring, safe bounded
   Endless constraints and terminal financial/reputation conditions.
7. Native/UI/story regressions, final archive update, verified commit/push and
   artifact/report links.

## Chosen architecture

- Keep the original Campaign, Vehicle, Operations and Flight model files intact.
  A mode adapter snapshots static model fields, projects run state into those
  models, and restores the Story session when leaving Rogue Rocket. Modified
  component parameters live in a run-only copy of the catalogue. All mass,
  propellant, power, delta-v, risk and flight outcomes use the original methods.
- Separate `user://rogue_rocket_v1.json` save with atomic replacement and a backup.
  Save explicit seed-derived offer/event counters and generated choices; UI
  animation never consumes gameplay randomness. Never write Story save files.
- Curated contracts have an evaluated reference architecture and a procurement
  fallback, checked against the actual payload/site, full parts cost, material
  recipes and schedule. A blueprint is a design; physical inventory is spent at
  launch. Unused inventory persists. No automatic recovered-stage reuse.
- Initial content stays deliberately small: four doctrines, four research themes,
  several contract templates, four management events and a limited workbench.
  The loop must work before adding more content.
- Extend the existing HQ, Moon planner, assembly and Mission Control controllers
  with mode-specific subclasses. Reuse their scenes, 3D environments, native
  tactile components, CRT and input routing. Avoid a second visual framework.
- Qualification and communications redundancy have explicit cost/time/mass/risk
  effects. Propellant loading can only decrease within existing tank capacity;
  the original rocket equation evaluates its consequences. No free thrust/Isp
  boosts, unexplained science physics bonuses or parallel success roulette.
- Science knowledge and contract grades are game abstractions. Real experiment
  context comes from the existing educational catalogue. Do not fabricate lunar
  discoveries as established facts.

## Evidence required before completion

Original simulation regression, current presentation checks, multiple seeded
full runs including failures/partial science, save/resume before/during/between
missions, inventory/resource transactions, no duplicate payouts, deterministic
offers/events, scientific capability gates, actual minigames and mode isolation.
Numerous generated seeds must have a resource-feasible reference plan; this is
mathematical coverage, not human balance testing. Native rendering, exports and
Mac hardware testing must be reported as distinct evidence.
