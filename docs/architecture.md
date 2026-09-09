# Project structure

The GameMaker Asset Browser groups Objects into Managers, Actors, World, Effects, and Interface; Scripts into Configuration, Combat, Rendering, and Interface; and rooms into Rooms. GameMaker's standard on-disk resource paths remain stable, so tests and asset references continue to resolve.

Managers are created before actors. Tower instances hold independent state; shared scripts implement behavior. Do not copy combat code into new tower objects.

| Owner | Responsibility |
| --- | --- |
| obj_game | Configuration, catalogs, selection, pause and encounter settings |
| obj_input | Begin Step clicks, wheel zoom, hover, selection, keys and GUI input blocking |
| obj_camera | Smoothed zoom and world-to-screen synchronization |
| obj_combat | Advances every tower through the shared controller |
| obj_ui | Modular dossier, horizontal opt-in skill details, glossary hover easing, selection feedback, cursor and presentation clock |
| obj_encounter | Automatic regular encounters using shared settings; GUI can add heavy enemies |
| obj_world | Irregular floating landmass, path, surface faults and aerial reality tears |
| obj_placement | Initial placement and relocation preview, shared footprint validation, confirmation and cancellation |
| obj_tower | Per-instance combat state, configured model, beam and charge bar |
| obj_enemy | Movement, health, slow stacks and Lock timers |

## Shared scripts

- `scr_definitions`: configuration and catalogs. Tower records provide stats, UI text, model/muzzle functions and status-effect settings.
- `scr_combat`: initialization, targeting, charge, attacks, damage accounting, status and progress. `tower_tick()` executes in the instance context provided by the combat manager.
- `scr_interface`: UI hit testing, shared control rectangles, animated panel origin, button rendering and selection feedback.
- `scr_geometry`: projection, inverse projection, camera synchronization and ground primitives.
- `scr_effects`: distinct charge streaks, muzzle flashes and tracer rendering. Impact objects own transient sparks and debris in world coordinates.
- `scr_defender`: Vestral's articulated model and muzzle transform. It does not handle input, damage, targeting or GUI layout.

## Adding a tower type

1. Add a uniquely keyed record to `build_tower_catalog()`, following Vestral's fields.
2. Supply `draw_model` and `muzzle` functions. They receive position, facing, time, recoil, aim and charging pose. Both callbacks also receive recovery progress and an optional world-view scale.
3. Supply hit count/multiplier and Shock Bolts settings. Damage and kill accounting stay in `tower_fire()`; enemy status timers and movement are resolved by `enemy_movement_time()`.
4. Create `obj_tower` with a pre-creation struct containing `world_x`, `world_y` and `tower_type`. Set `obj_game.build_tower_type` to use it in the current placement flow.

The panel reads definitions and instance statistics automatically. Definitions are shared: put upgrades and temporary modifiers in instance fields rather than modifying the catalog.

## Update rules

Input resolves in Begin Step. Moving beyond the drag threshold suppresses accidental click actions but does not move the camera. The mouse wheel changes a clamped zoom target, which the camera eases toward. GUI-originated presses do not begin world clicks. Selection is separate from Charge, which can be triggered by the panel button or keyboard. Move starts a placement preview referencing the existing tower; commit updates its position without recreating it. Cancel destroys only the preview. The moving tower pauses its combat timers and cannot charge.

Combat advances once per frame in `obj_combat`. Enemy movement and spawning retain their own Step events. Screen positions synchronize after input and after smoothed zoom at End Step. UI feedback can respond while combat is paused.

Targeting uses world distance and a shared priority rule. A damped angular spring produces smooth tower tracking. Overloaded reacquires targets and retains queued attacks while no target is available. Shared readiness, progress and status functions keep the dossier and overhead charge bar consistent.

## Current boundaries and verification

The prototype retains one placement and automatically spawns regular enemies when the route is empty. The GUI can spawn additional heavy enemies with three times the HP and half the speed. Its controller supports multiple independent towers, but a build menu, economy, upgrades and card drafts are not implemented. A spatial target index can later replace the straightforward scan inside `tower_find_target()`.

`tests/controllers.cjs` translates production control functions and stubs engine operations to test state and input rules. It does not replace in-game testing. Local builds and isolated runtime-test copies are in the ignored `.build` directory.


