# Antithesis

Open Antithesis.yyp in GameMaker and press F5.

- Press **1** for Vestral or **2** for WANDERER, then click open ground to place the chosen tower. Repeat to add another tower; Vestral is the initial preview.
- Hover over the tower to preview its range. Click it to open the minimal bottom-left dossier; the full range remains visible while the dossier is open.
- Abilities appear in a vertical list (three for Vestral, four for WANDERER). Click an ability to open its description and click again to close it. Underlined terms reveal glossary cards on hover. Click the targeting control to cycle First, Strongest and Nearest.
- Click Charge in the panel, or press C, to use Overloaded on the selected tower.
- Click Move Tower, then click valid open ground to relocate. Escape, right-click, Cancel Move or closing the panel cancels. Confirming sends the tower through a short phase dash with fading echoes; stats and cooldowns are preserved and its combat timer remains paused until arrival. Movement is unavailable during Charge, burst or recovery.
- Click Spawn Heavy Enemy at the top left for an extra enemy with 300 HP and half normal speed. The button is disabled while paused.
- Roll the mouse wheel to smoothly zoom the fixed isometric view in or out.
- Escape deselects; P pauses; R restarts.

VESTRAL — “A survivor of great powers”

Double Tap resolves two hits at 50% ATK each, separated by a 0.09-second snap delay. The full ATK SPD downtime begins only after the second bolt. Vestral no longer uses ammunition or reloads. The existing base stats remain 20 ATK, 1.25 attacks/sec and 2.65 range.

Shock Bolts adds a 5% slow per hit, capped at eight stacks / 40%. Each hit refreshes all stacks for 0.4 seconds. Reaching eight stacks roots the victim with Lock for 0.8 seconds. Refreshes at the cap do not trigger another Lock; after the slow expires, a new set of stacks can trigger it again. Two animated void chains communicate Lock directly on the enemy; stack squares and the LOCK label are removed.

Overloaded banks attack opportunities throughout its 3.2-second Charge using Vestral's attack clock, even when no enemy is in range. It releases the stored Double Taps with their two-bolt cadence and a short delay between pairs, retargeting after kills and keeping the queue through an empty lane. A 0.5-second recovery and six-second skill cooldown follow; regular attacks continue during cooldown.

WANDERER — “The patient hunter”

Vigil suppresses automatic attacks. Mark of the Hunter executes an enemy strictly below 3.5% maximum HP, checked before and after each skill-triggered Basic Attack. WANDERER never applies Vestral's slow or Lock.

Execution charges for 1.5 seconds and fires once at any distance using First, Strongest or Nearest targeting. It resolves against the enemies present when charging finishes. Its cooldown is eight seconds; a kill from either skill resets it immediately. A charge without a target finishes and enters cooldown.

Skilled Sniper fires once immediately on arrival after a confirmed move, using normal 3.4 range. Cancelled or invalid moves do not fire or spend Vigil. The model directly references the supplied WANDERER sculpt: an extended beaked ivory hood, recessed black face with a cyan slit, torn faceted ivory mantle, dark tapered limbs, an exposed mechanical shin and knee ring, and a long steel-blue scoped rifle. Jointed arms support the weapon through its lowered rest, raised aim, charge crouch and recoil; the cloak sways and trails during movement. Charge and shot effects use the reference's cyan accent.

The [model study](docs/wanderer-design.png) shows resting, Execution and rear views rendered from the production geometry. Regenerate its SVG with `node tests/render-wanderer.cjs`, or both SVG and PNG with `powershell -File tests/render-wanderer.ps1`. This preview checks the model independently of GameMaker's scene rendering.

WANDERER now idles on one knee, including when tracking enemies, then rises into a braced skill pose and returns to kneeling after recoil. Its palette uses pale lime fabric, olive metal and luminous lime accents. Its exclusive effects include two spiraling streams of leaf shards, a broken ground seal, rising fragments, a late-charge lens flare, a piercing shot, muzzle splinters and an outward-fracturing impact that persists after a kill. Movement sheds the same custom leaf shapes; no Vestral impact instances are emitted. Effects respect pause and camera zoom. The [motion study](docs/wanderer-motion.html) plays the full sequence using production draw functions; regenerate it with `node tests/render-wanderer-motion.cjs`.

Initial balance choices are centralized in `build_tower_catalog`: 60 base ATK; each kill grants one Vigil per 25 actual damage dealt by the killing attack (rounded up, minimum one, maximum four, including execution damage). Each of the first 12 lifetime stacks grants permanent +2 ATK; later stacks grant +0.5 ATK. Each skill spends one available stack when it resolves, including when no target is present. Skills remain usable at zero to avoid preventing WANDERER from earning its first kill. Spending never removes earned ATK or resets the lifetime breakpoint. The dossier shows available and lifetime-earned stacks.

Regular enemies appear one at a time automatically; the spawn button can add heavy enemies alongside them. Shared definitions and managers support adding more types without duplicating the combat controller. Map geometry is authored with marker objects directly in Room1. See [the architecture guide](docs/architecture.md).

## Verification

Run `node tests/controllers.cjs` for checks against the production control logic: targeting, independent towers, Double Tap, sustained firing, slow and Lock timing, charge storage/retargeting, pause, wheel zoom, tab actions, exact GUI hit regions, room-authored geometry, relocation animation and click/key separation.

These tests translate GML control functions into an isolated JavaScript host. They do not verify GameMaker rendering or engine event binding, so an in-editor gameplay check is still recommended for the procedural visuals.

WANDERER checks cover suppression of normal attacks, global targeting, strict execution thresholds, Vigil gains and the 12-stack breakpoint, permanent ATK, both cooldown-reset paths, movement arrival attacks, empty lanes, pause, the fourth ability tab, and finite model/muzzle geometry across animated poses and facings.

## Interaction references

The modular dossier separates identity, stats, controls and skill copy into clearly spaced regions instead of enclosing everything in one panel. Underlined terms reveal animated glossary cards. The environment is a naturally distorted null realm: an enlarged irregular landmass with uneven cliff depth, clustered rift growths, mineral stains, branching surface faults and suspended world-space reality tears. Its monochrome geology moves subtly without reading as constructed technology.

Polish adapted from [Overshot v.2 selection panels](https://github.com/FrostImpact/Overshot-v.2/blob/main/objects/obj_ball_select/Step_0.gml): damped opening motion, eased hover highlights, press feedback and ability-detail transitions. [Overshot enemy feedback](https://github.com/FrostImpact/Overshot-v.2/blob/main/objects/obj_basic/Draw_0.gml) informed the small hit squash and delayed health damage segment. These are original implementations for this game, with no borrowed assets.
