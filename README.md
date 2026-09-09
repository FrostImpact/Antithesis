# Antithesis

Open Antithesis.yyp in GameMaker and press F5.

- Click open ground to place Vestral permanently for this run.
- Hover over the tower to preview its range. Click it to open the minimal bottom-left dossier; the full range remains visible while the dossier is open.
- The three abilities form a horizontal strip. Descriptions start closed: click an ability to open it and click it again to close it. Underlined terms reveal glossary cards on hover. Click the targeting control to cycle First, Strongest and Nearest.
- Click Charge in the panel, or press C, to use Overloaded on the selected tower.
- Click Move Tower, then click valid open ground to relocate. Escape, right-click, Cancel Move or closing the panel cancels. The original tower remains in place until confirmed; stats and cooldowns are preserved. Movement is unavailable during Charge, burst or recovery. Combat timers for the moving tower pause until placement or cancellation.
- Click Spawn Heavy Enemy at the top left for an extra enemy with 300 HP and half normal speed. The button is disabled while paused.
- Roll the mouse wheel to smoothly zoom the fixed isometric view in or out.
- Escape deselects; P pauses; R restarts.

VESTRAL — “A survivor of great powers”

Double Tap resolves two hits at 50% ATK each. Vestral no longer uses ammunition or reloads. The existing base stats remain 20 ATK, 1.25 attacks/sec and 2.65 range.

Shock Bolts adds a 5% slow per hit, capped at eight stacks / 40%. Each hit refreshes all stacks for 0.4 seconds. Reaching eight stacks roots the victim with Lock for 0.8 seconds. Refreshes at the cap do not trigger another Lock; after the slow expires, a new set of stacks can trigger it again. Two animated void chains communicate Lock directly on the enemy; stack squares and the LOCK label are removed.

Overloaded stores eligible attacks during a 3.2-second Charge. It releases the stored Double Taps 0.09 seconds apart, retargeting after kills and keeping the queue if no enemy is in range. A 0.5-second recovery and six-second skill cooldown follow; regular attacks continue during cooldown.

The prototype contains one placeable tower. Regular enemies appear one at a time automatically; the spawn button can add heavy enemies alongside them. Shared definitions and managers support adding more types without duplicating the combat controller. See [the architecture guide](docs/architecture.md).

## Verification

Run `node tests/controllers.cjs` for checks against the production control logic: targeting, independent towers, Double Tap, sustained firing, slow and Lock timing, charge storage/retargeting, pause, wheel zoom, tab actions, click/key separation and GUI gesture isolation.

These tests translate GML control functions into an isolated JavaScript host. They do not verify GameMaker rendering or engine event binding, so an in-editor gameplay check is still recommended for the procedural visuals.

## Interaction references

The modular dossier separates identity, stats, controls and skill copy into clearly spaced regions instead of enclosing everything in one panel. Underlined terms reveal animated glossary cards. The environment is a naturally distorted null realm: an enlarged irregular landmass with uneven cliff depth, clustered rift growths, mineral stains, branching surface faults and suspended world-space reality tears. Its monochrome geology moves subtly without reading as constructed technology.

Polish adapted from [Overshot v.2 selection panels](https://github.com/FrostImpact/Overshot-v.2/blob/main/objects/obj_ball_select/Step_0.gml): damped opening motion, eased hover highlights, press feedback and ability-detail transitions. [Overshot enemy feedback](https://github.com/FrostImpact/Overshot-v.2/blob/main/objects/obj_basic/Draw_0.gml) informed the small hit squash and delayed health damage segment. These are original implementations for this game, with no borrowed assets.
