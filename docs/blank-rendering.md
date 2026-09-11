# Void fragment rendering

The humanoid enemy art and walking rig have been replaced with suspended mineral fragments from the null realm. Wisp is a torn splinter, Husk is a hollow diamond shell, and Hulk is a broad broken monolith. Ivory and slate plates surround dark cores with faint cold light. Small detached chips and a fixed ground shadow communicate levitation.

`tools/blank-models.cjs` contains the original polygon sculpts. `tools/bake-blanks.cjs` renders them offline from one fixed view into 48 phases per type. Body lift ranges from 2.4 to 3.7 model units with a visible tilt. Shell plates hinge and separate independently, smaller chips circle their resting positions, and the core changes size and brightness. All this motion is baked offline; the ground shadow stays fixed. Cycles take 2.4 seconds for Wisp, 3.0 for Husk and 3.6 for Hulk, with randomized initial phases. Slow scales this clock; root and pause freeze it. Travel speeds and combat values are unchanged. Hits briefly compress the sprite around its ground anchor.

Enemies materialize from a small ground breach with converging shards before becoming targetable or moving. The duration is 0.55 seconds for Wisp, 0.65 for Husk and 0.8 for Hulk. The sprite grows from its fixed ground anchor and fades in. Pause freezes the entire sequence. Active Slow draws two cyan zigzag arcs directly over the shell; these flicker using the enemy's paused simulation clock, intensify with stacks and fade at expiry. Lock's ground chains remain separate.

## Runtime and asset budget

- One sprite submission per enemy, including its shadow; a hit briefly adds one additive submission. Spawn and active Slow add short procedural effects only while needed.
- No skeleton, walking, pose evaluation, facing rows, mesh construction, projection or sorting at runtime.
- Three 960 × 480 sprite atlases, each containing 48 cells arranged in 12 columns and four rows.
- 144 total frames, compared with 768 for the previous humanoids.
- Approximately 5.27 MiB of raw RGBA content across all three strips, compared with 28.1 MiB previously: about 5.3 times less pixel storage before GameMaker texture-page padding. PNG files total roughly 126 KiB, excluding duplicate editor layer copies. This is an asset-size comparison, not an FPS measurement.
- The fixed view deliberately avoids turn animation; each silhouette remains stable around route corners.

## Regeneration and validation

Run `node tools/bake-blanks.cjs` to regenerate the actual game assets, then `node tests/render-blanks.cjs` for the still and interactive motion study. `tests/render-blanks.ps1` adds labels to the PNG study.

`node tests/blanks.cjs` verifies every shipped frame against the current sculpt, checks clipping, sprite metadata, loop seams, selection, the ground anchor, hit blending and preview syntax. `node tests/encounters.cjs` checks drift, root, slow, pause, path travel and waves. `node tests/controllers.cjs` checks combat and controls.

These automated checks pass. In-engine validation remains unconfirmed: the standalone GameMaker compiler could not obtain execution permission earlier in this session.
