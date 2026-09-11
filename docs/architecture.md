# Project structure

The GameMaker Asset Browser groups Objects into Managers, Actors, World, Effects, and Interface; Scripts into Configuration, Combat, Rendering, and Interface; and rooms into Rooms. GameMaker's standard on-disk resource paths remain stable, so tests and asset references continue to resolve.

Managers are created before actors. Tower instances hold independent state; shared scripts implement behavior. Do not copy combat code into new tower objects.

| Owner | Responsibility |
| --- | --- |
| obj_game | Configuration, catalogs, selection, pause and encounter settings |
| obj_input | Begin Step clicks, wheel zoom, hover, selection, keys and GUI input blocking |
| obj_camera | Smoothed zoom and world-to-screen synchronization |
| obj_combat | Advances every tower through the shared controller |
| obj_ui | Modular dossier, wrapped catalog copy, generated glossary regions, selection feedback, cursor and presentation clock |
| obj_encounter | Player-started rounds, staggered waves, clear detection, wave breaks and escape counts |
| obj_world | Irregular floating landmass, path, colour-coded endpoint platforms and aerial reality tears |
| obj_placement | Initial placement and relocation preview, shared footprint validation, confirmation and cancellation |
| obj_tower | Per-instance combat state, configured model, beam and charge bar |
| obj_enemy | Movement, health, slow stacks, Lock timers, heading and shared walk phase |
| obj_map_route / surface / void / terrain | Room Editor authoring markers consumed by obj_world at startup |

## Shared scripts

- `scr_encounters`: preparation / wave / wave_break / intermission state machine. Each round creates three wave records containing an enemy roster, spawn interval and health multiplier. Starting a round requires a tower and rejects pause or duplicate starts. Future card drafts can be inserted at the intermission boundary.
- `scr_blanks`: constant-cost sprite selection and drawing. Three assets are bound once after catalog creation. Each enemy selects one of 48 hover frames and anchors its baked ground shadow at the route position. No geometry, skeleton or facing calculations run during drawing. A hit briefly adds a second sprite submission.
- `tools/bake-blanks.cjs`: offline rasterizer for the void-fragment sculpts in `tools/blank-models.cjs`. It writes 48 hover frames per type to native GameMaker PNG assets, including editor layers. Drift uses a slow clock affected by slow, root and pause. Re-bake after changing geometry; the game does not bake at startup.

- `scr_enums`: shared UI, ability, targeting, charge-state and map-region identifiers.
- `scr_definitions`: configuration and catalogs. Tower records provide stats, wrapped UI copy, model/muzzle functions and status-effect settings.
- `scr_combat`: initialization, targeting, charge, attacks, damage accounting, status and progress. `tower_tick()` executes in the instance context provided by the combat manager.
- `scr_interface`: UI hit testing, shared control rectangles, animated panel origin, button rendering and selection feedback.
- `scr_map`: converts the Room Editor's top-down authoring grid into route, surface, void and terrain runtime data.
- `scr_geometry`: projection, inverse projection, camera synchronization and ground primitives.
- `scr_effects`: distinct charge streaks, muzzle flashes and tracer rendering. Impact objects own transient sparks and debris in world coordinates.
- `scr_defender`: Vestral's articulated model and muzzle transform. It does not handle input, damage, targeting or GUI layout.

## Adding a tower type

1. Add a uniquely keyed record to `build_tower_catalog()`, following Vestral's fields.
2. Supply `draw_model` and `muzzle` functions. They receive position, facing, time, recoil, aim and charging pose. Both callbacks also receive recovery progress and an optional world-view scale.
3. Supply hit count, `shot_interval`, hit multiplier and Shock Bolts settings. The shared sequence controller schedules the bolts, damage and kill accounting stay in `tower_fire_hit()`, and enemy status timers and movement are resolved by `enemy_movement_time()`.
4. Create `obj_tower` with a pre-creation struct containing `world_x`, `world_y` and `tower_type`. Set `obj_game.build_tower_type` to use it in the current placement flow.

The panel reads definitions and instance statistics automatically. Definitions are shared: put upgrades and temporary modifiers in instance fields rather than modifying the catalog.

## Update rules

Input resolves in Begin Step. Moving beyond the drag threshold suppresses accidental click actions but does not move the camera. The mouse wheel changes a clamped zoom target, which the camera eases toward. Only visible GUI modules block world clicks; empty space between modules remains usable. Selection is separate from Charge, which can be triggered by the panel button or keyboard. Move starts a placement preview referencing the existing tower; commit starts a short eased phase dash without recreating it. Cancel destroys only the preview. The moving tower pauses its combat timers and cannot charge.

## Building maps in the Room Editor

Room1 contains an Authoring set under Objects > World. Place these marker objects on the 64-pixel editor grid (world origin is editor position 128, 96):

- `obj_map_route`: each marker is a path node; Image Index is its travel order.
- `obj_map_surface`: position is the shelf centre, X/Y Scale are its world width/depth, and Image Index is cliff height.
- `obj_map_void`: position is the void centre and X/Y Scale are its dimensions. Placement collision uses this same data.
- `obj_map_terrain`: X Scale is collision radius, Y Scale × 100 is visual height, and Rotation supplies shape variation.

The authoring markers are hidden at runtime. `obj_world` consumes them once, so drawing, pathfinding, placement checks and terrain spawning all read the same room-authored source instead of parallel hardcoded arrays.

Combat advances once per frame in `obj_combat`. Basic attacks are sequences: their individual bolts use `shot_interval`, and the tower's ATK SPD cooldown begins after the final bolt. Overloaded banks these attack opportunities from time alone during Charge, then preserves unfinished pairs until a target is available. Enemy movement and spawning retain their own Step events. Screen positions synchronize after input and after smoothed zoom at End Step. UI feedback can respond while combat is paused.

Targeting uses world distance and a shared priority rule. A damped angular spring produces smooth tower tracking. Overloaded reacquires targets and retains queued attacks while no target is available. Shared readiness, progress and status functions keep the dossier and overhead charge bar consistent.

## Current boundaries and verification

The prototype supports repeated tower placement and player-started rounds with three staggered waves, short wave breaks, an intermission and increasing difficulty. The three ordinary Blank variants are suspended void fragments, each rendered from a 48-frame sprite atlas with independently hinged plates and randomized initial phases. They finish materializing before movement and targeting begin. Electric Slow feedback and Lock chains are independent of the baked motion. Tower shadows render once in the world ground pass, independently of model animation and hover tint. Enemy escapes are counted without a base-health penalty; victory and defeat are not yet implemented. A build menu, economy, upgrades and card drafts are also not implemented. A spatial target index can later replace the straightforward scan inside `tower_find_target()`.

`scr_loadout` owns the shuffled card deck, stored-card counts, pending card-use transaction, five hotbar slots, available tower copies and Bits. Using a card reserves one stored copy and commits its reward once the paused-aware animation completes. Placement revalidates terrain, inventory and funds before creating a tower and deducts payment only on success. The five-slot limit applies to equipped types, not deployed towers. The encounter manager deposits one reward per completed round, guarded by round number. Combat deposits kill Bits. UI drawing and input share slot rectangles and inverse-rotated card geometry.

The dossier sits above the hotbar and to the right of the card inspector. Card controls draw above the dossier, keeping use animations visible. Pit walls use convex clipping against the projected opening; footprint validation subtracts the union of shelf rectangles and rejects expanded void bounds including the rim.

`tests/controllers.cjs`, `tests/loadout.cjs` and `tests/map-collision.cjs` translate production control functions and stub engine operations to test state, input and geometry rules. They do not replace in-game testing. `tests/render-loadout.cjs` renders the production map and HUD using the actual tower model functions. Local builds and isolated runtime-test copies are in the ignored `.build` directory.


