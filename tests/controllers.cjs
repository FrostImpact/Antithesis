// Executes the production GML control functions in an isolated JS host.
// This checks state transitions, not GameMaker rendering or engine event binding.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const translate = text => text.replace(/\bmod\b/g, '%');
const GlossaryTerm={None:-1,GreatPowers:0,Charge:1,Lock:2,Count:3};
const TowerAbility={DoubleTap:0,ShockBolts:1,Overloaded:2,Count:3};
const TowerTargetMode={First:0,Strongest:1,Nearest:2,Count:3};
const TowerChargeState={Ready:0,Charging:1,Burst:2,Recovery:3};
const UiAction={None:-1,Target:0,Charge:1,Move:2,AbilityDoubleTap:3,AbilityShockBolts:4,AbilityOverloaded:5,AbilityMove:6,Spawn:7,Count:8};
const definitions = new Function('draw_defender', 'defender_muzzle', 'draw_wanderer', 'wanderer_muzzle', 'GlossaryTerm', 'TowerAbility', `function draw_singularity(){} function singularity_muzzle(){} function draw_triage(){} function triage_muzzle(){} ${translate(read('scripts/scr_definitions/scr_definitions.gml'))}; return build_tower_catalog();`)(() => {}, () => {}, () => {}, () => {}, GlossaryTerm, TowerAbility);
const code = translate(read('scripts/scr_combat/scr_combat.gml'));
const shared = { paused: false };
function makeTower(enemies, definition = definitions.vestral) {
  const s = {
    tower_type: 'vestral', world_x: 0, world_y: 0, x: 0, y: 0,
    obj_game: shared, obj_enemy: 'enemy', obj_impact: 'impact',
    noone: null, delta_time: 1e6 / 120,
    floor:Math.floor,string_format:(n,w,d)=>n.toFixed(d),ceil:Math.ceil,min: Math.min, max: Math.max, abs: Math.abs, exp: Math.exp, sin: Math.sin, pi: Math.PI,
    power:Math.pow,array_create:(count,value)=>Array(count).fill(value),array_length:value=>value.length,
    clamp: (v, a, b) => Math.max(a, Math.min(b, v)),
    lerp: (a, b, t) => a + (b - a) * t,
    point_distance: (a, b, c, d) => Math.hypot(c - a, d - b),
    point_direction: () => 0, angle_difference: (a, b) => ((a - b + 540) % 360) - 180,
    tower_definition: () => definition,
    instance_exists: value => value != null && !value.destroyed,
    instance_number: () => enemies.filter(e => !e.destroyed).length,
    instance_find: (_, i) => enemies.filter(e => !e.destroyed)[i],
    instance_destroy: value => { value.destroyed = true; },
    instance_create_depth: () => {},
    loadout_award_kill:()=>{},
    project_x:(x,y)=>x,project_y:(x,y)=>y,
    TowerChargeState,TowerTargetMode,
  };
  // GML implicitly creates instance fields. Predeclare those fields in this host.
  const init = code.slice(code.indexOf('function tower_initialize'), code.indexOf('function tower_tick'));
  for (const match of init.matchAll(/^([a-z_]+)=/gm)) s[match[1]] = undefined;
  for (const key of ['kills', 'damage_dealt', 'shots_fired', 'hover_amount', 'selection_amount', 'select_pulse', 'reject_pulse', 'beam_world_y']) s[key] = 0;
  s.id = s;
  const api = new Function('s', `with(s) { ${code}; return {init:tower_initialize,tick:tower_tick,charge:tower_request_charge,target:tower_find_target,progress:tower_charge_progress,begin:tower_begin_attack,tickAttack:tower_tick_attack_sequence,fireHit:tower_fire_hit,shock:enemy_apply_shock,movement:enemy_movement_time}; }`)(s);
  api.init(); s.settle = 0; s.facing = 0; s.aim_blend = 1;
  return { s, api };
}
const enemy = (health = 1000, worldX = 1, progress = 1) => ({ spawn_left:0, hit_points: health,max_hit_points:health, world_x: worldX, world_y: 0, x: 20, y: 0, progress, shock_stacks:0, shock_left:0, shock_slow:0, lock_left:0 });
const run = (tower, frames) => { for (let i = 0; i < frames; i++) tower.api.tick(); };
const fireBasic = (tower,target) => {
  tower.api.begin(tower.s,false);
  tower.api.tickAttack(tower.s,0,target,tower.s.instance_exists(target));
  if(tower.s.attack_shots_left>0) tower.api.tickAttack(tower.s,tower.s.shot_interval,target,tower.s.instance_exists(target));
};

const first = enemy(1000, 2, 8), strong = enemy(2000, 1.5, 2), near = enemy(500, 0.5, 1), outside = enemy(9999, 9, 99);
const arriving=enemy(100,1,100);arriving.spawn_left=0.2;
const spawnTarget=makeTower([arriving]);
assert.equal(spawnTarget.api.target(spawnTarget.s,true),null,'Materializing enemies cannot be targeted');
arriving.spawn_left=0;assert.equal(spawnTarget.api.target(spawnTarget.s,true),arriving);
const t = makeTower([first, strong, near, outside]);
assert.equal(t.api.target(t.s), first);
t.s.target_mode = TowerTargetMode.Strongest; assert.equal(t.api.target(t.s), strong);
t.s.target_mode = TowerTargetMode.Nearest; assert.equal(t.api.target(t.s), near);

const a = makeTower([enemy()]), b = makeTower([enemy()]);
assert.equal(a.api.charge(a.s), true);
assert.equal(b.s.charge_mode, TowerChargeState.Ready, 'Another tower must keep independent state');
run(a, 384);
assert.equal(a.s.shots_fired, 0, 'Charging must suppress attacks');
assert.equal(a.s.stored_shots, 4);
assert.ok(Math.abs(a.api.progress(a.s) - 1) < 1e-9);
run(a, 120);
assert.equal(a.s.shots_fired, 4);
assert.equal(a.s.damage_dealt, 80, 'Four Double Taps, no finisher bonus');
assert.equal(a.s.hits_landed,8);
assert.equal(a.s.stored_shots, 0);
assert.equal(a.api.progress(a.s), 0);
assert.equal(a.api.charge(a.s), false, 'Reuse delay must reject a repeated request');

const dying = makeTower([enemy(20)]);
dying.api.charge(dying.s); run(dying, 504);
assert.equal(dying.s.shots_fired, 1);
assert.equal(dying.s.stored_shots, 3, 'Overloaded retains attacks when target dies');
assert.equal(dying.s.kills, 1);

const emptyLane=[];
const empty = makeTower(emptyLane);
empty.api.charge(empty.s); run(empty, 500);
assert.equal(empty.s.shots_fired, 0);
assert.equal(empty.s.stored_shots, 4,'Overloaded banks attacks even when no enemy is in range');
assert.equal(empty.s.charge_mode,TowerChargeState.Burst,'An empty lane keeps the stored burst ready for a future target');
emptyLane.push(enemy(1000));run(empty,180);
assert.equal(empty.s.shots_fired,4,'Every targetless banked attack releases after a target arrives');
assert.equal(empty.s.hits_landed,8,'Stored Double Taps retain both delayed bolts');
const paused = makeTower([enemy()]); paused.api.charge(paused.s); run(paused, 50);
const before = paused.s.charge_left; shared.paused = true; run(paused, 100);
assert.equal(paused.s.charge_left, before); shared.paused = false;

const custom = makeTower([enemy()], { ...definitions.vestral, damage: 7, attack_range: 1.2 });
assert.equal(custom.s.damage, 7);
assert.equal(custom.s.attack_range, 1.2);
assert.equal(definitions.vestral.damage, 20, 'Per-instance initialization must not alter the catalog');
const smooth = makeTower([enemy()]);
smooth.s.point_direction=()=>90; smooth.s.facing=0; smooth.s.turn_velocity=0; smooth.s.cooldown=99;
smooth.api.tick();
assert.ok(smooth.s.facing>0 && smooth.s.facing<1,'Turn spring must ease in rather than snapping to a fixed step');
const firstTurnVelocity=smooth.s.turn_velocity; smooth.api.tick();
assert.ok(smooth.s.turn_velocity>firstTurnVelocity,'Turn spring accelerates smoothly toward its target');
run(smooth,240);
assert.ok(Math.abs(smooth.s.angle_difference(90,smooth.s.facing))<1,'Turn spring settles on its target');
const cadenceTarget=enemy(10000);const cadence=makeTower([cadenceTarget]);
cadence.api.tick();
assert.equal(cadence.s.hits_landed,1,'A basic attack starts with one bolt');
assert.ok(cadence.s.shot_fx_duration<cadence.s.shot_interval,'The first tracer clears before the second bolt');
run(cadence,10);assert.equal(cadence.s.hits_landed,1,'The second bolt is separated by a short delay');
run(cadence,1);assert.equal(cadence.s.hits_landed,2,'The second bolt completes the Double Tap');
assert.ok(cadence.s.cooldown>0.79,'The full ATK SPD cooldown starts after the second bolt');
run(cadence,94);assert.equal(cadence.s.hits_landed,2,'No new basic attack starts during the post-pair cooldown');
run(cadence,3);assert.equal(cadence.s.hits_landed,3,'The next basic attack starts only after the full cooldown');
console.log('PASS: targeting, independent state, two-bolt cadence, post-pair cooldown, charge suppression, targetless Overloaded banking, queue retention, pause, reuse delay, and definition-driven stats.');

const actor = { x: 500, y: 300, facing: 300, charge_mode: TowerChargeState.Ready };
const input = {
  ord: s=>s.charCodeAt(0),
  obj_tower: 'tower', obj_placement: 'placement', noone: null,
  obj_camera: { map_angle: 45, target_zoom: 1 }, obj_game: { selected_tower: null, paused: false, config: { drag_threshold: 6, zoom_step: 0.1, zoom_min: 0.72, zoom_max: 1.28, restart_key: 82, pause_key: 80, charge_key: 67 } },
  mouse_x: 500, mouse_y: 280, mb_left: 1, mb_right: 2, vk_escape: 27,
  pointer_down: false, dragging: false, press_x: 0, press_y: 0, last_drag_x: 0,
  pressed_tower: null, clicked_tower: null, clicked_ground: false, hovered_tower: null,
  pressed: false, held: false, released: false, wheel_up: false, wheel_down: false, key: null, blocked: false,
  min: Math.min, max: Math.max,
  point_distance: (a,b,c,d) => Math.hypot(c-a,d-b),
  instance_exists: e => e != null && e !== 'placement',
  instance_number: () => 1, instance_find: () => actor,
  camera_sync_actors: () => {}, ui_handle_input: () => {}, room_restart: () => {},
  charge_requests: 0,
};
input.ui_pointer_blocked = () => input.blocked;
input.mouse_check_button_pressed = button => button===1 && input.pressed;
input.tower_cancel_move=()=>false;
input.obj_game.loadout={selected:-1};input.loadout_select=()=>{};
input.loadout_reward_active=()=>false;
input.mouse_check_button = () => input.held;
input.mouse_check_button_released = () => input.released;
input.mouse_wheel_up = () => input.wheel_up;
input.mouse_wheel_down = () => input.wheel_down;
input.keyboard_check_pressed = key => key === input.key;
input.game_select_tower = tower => { input.obj_game.selected_tower = tower; };
input.tower_request_charge = tower => { if (tower) input.charge_requests++; };
input.obj_game.config.move_key=77;
input.tower_request_move=tower=>{input.move_target=tower;};
const inputSource = translate(read('objects/obj_input/Step_1.gml')).replace(/\bexit;/g, 'return;');
const inputTick = new Function('s', 'actor', `with(s) { ${inputSource} }`);
function pointer(pressed, held, released, x = 500, y = 280) {
  Object.assign(input, { pressed, held, released, mouse_x: x, mouse_y: y });
  inputTick(input, actor);
}
pointer(true,true,false); pointer(false,false,true);
assert.equal(input.obj_game.selected_tower, actor);
assert.equal(input.charge_requests, 0, 'Clicking selects, never charges');
input.key = 67; pointer(false,false,false); input.key = null;
assert.equal(input.charge_requests, 1, 'C dispatches charge to the selected tower');
input.obj_game.selected_tower = null;
pointer(true,true,false); pointer(false,true,false,550,280); pointer(false,false,true,550,280);
assert.equal(input.obj_game.selected_tower, null, 'Dragging over a tower must not select it');
assert.equal(input.clicked_ground, false, 'Dragging must not place a tower');
assert.equal(input.obj_camera.map_angle, 45, 'Dragging must not orbit the map');
input.blocked = true;
const angle = input.obj_camera.map_angle;
pointer(true,true,false); pointer(false,true,false,600,280); pointer(false,false,true,600,280);
assert.equal(input.obj_camera.map_angle, angle, 'Panel-originated gestures cannot rotate the map');
assert.equal(input.clicked_ground, false);
input.blocked = false; input.wheel_up = true; pointer(false,false,false); input.wheel_up = false;
assert.equal(input.obj_camera.target_zoom,1.1,'Wheel up zooms in');
input.wheel_down = true; pointer(false,false,false); input.wheel_down = false;
assert.equal(input.obj_camera.target_zoom,1,'Wheel down zooms out');
console.log('PASS: click selection, C dispatch, drag suppression, fixed orbit, wheel zoom, and GUI gesture isolation.');
input.obj_game.selected_tower=null;input.key=67;pointer(false,false,false);
assert.equal(input.charge_requests,2,'C charges hovered tower with no open dossier');
assert.equal(input.obj_game.selected_tower,null,'Hover shortcut does not open a dossier');
let requested=null;input.tower_request_charge=tower=>requested=tower;
const selectedElsewhere={x:20,y:20};input.obj_game.selected_tower=selectedElsewhere;
pointer(false,false,false);assert.equal(requested,actor,'Hover takes priority over another selected tower');
pointer(false,false,false,700,500);assert.equal(requested,selectedElsewhere,'Selection is the fallback off a tower');
input.blocked=true;pointer(false,false,false);assert.equal(requested,selectedElsewhere,'UI cannot hover a tower behind it');
input.blocked=false;input.obj_game.selected_tower=null;input.key=77;pointer(false,false,false);
assert.equal(input.move_target,actor,'M starts a move directly from hover');
input.key=null;input.obj_game.selected_tower=null;
console.log('PASS: hover charge/move without selection, hover priority, selected fallback and UI occlusion.');
input.loadout_reward_active=()=>true;requested=null;input.key=67;
pointer(true,true,false);assert.equal(requested,null,'Reward overlay blocks tower shortcuts');
assert.equal(input.pointer_down,false);assert.equal(input.hovered_tower,null);
input.key=null;input.pressed=false;input.held=false;input.loadout_reward_active=()=>false;

// Evaluate every cursor branch: GML compiles unknown constants as variable reads.
const uiStep = read('objects/obj_ui/Step_2.gml');
const cursorStep = new Function('s', `with(s) { ${uiStep.slice(uiStep.indexOf('var next_cursor='))} }`);
const cursor = {obj_input:{dragging:false,hovered_tower:null},active_cursor:0,hovered_term:-1,
  loadout_pointer_blocked:()=>false,
  ui_action_at_pointer:()=>-1,cr_default:0,cr_handpoint:1,instance_exists:v=>v!=null,updates:[]};
cursor.window_set_cursor = value => cursor.updates.push(value);
cursorStep(cursor);
cursor.obj_input.hovered_tower = actor; cursorStep(cursor);
cursor.obj_input.dragging = true; cursorStep(cursor); cursorStep(cursor);
cursor.obj_input.dragging = false; cursor.obj_input.hovered_tower = null; cursorStep(cursor);
assert.deepEqual(cursor.updates,[1,0]);
console.log('PASS: default and hover cursors; dragging no longer advertises orbit.');

const feedbackSource=translate(read('scripts/scr_interface/scr_interface.gml'));
const feedbackBody=feedbackSource.slice(feedbackSource.indexOf('function ui_draw_world_feedback'));
const rangeCalls=[];
const viewTower={hover_amount:0,selection_amount:0,select_pulse:0,attack_range:2.65,world_x:0,world_y:0,x:0,y:0};
const view={obj_tower:viewTower,c_white:0,pr_trianglefan:0,
  max:Math.max,
  dcos:a=>Math.cos(a*Math.PI/180),dsin:a=>Math.sin(a*Math.PI/180),
  make_colour_rgb:()=>0,draw_set_alpha:()=>{},draw_set_colour:()=>{},
  draw_primitive_begin:()=>{},draw_vertex:()=>{},draw_primitive_end:()=>{},draw_line_width:()=>{},
  project_x:(x,y)=>x,project_y:(x,y)=>y,draw_range:(x,y,r)=>rangeCalls.push(r)};
const drawFeedback=new Function('s',`with(s){${feedbackBody};return ui_draw_world_feedback;}`)(view);
drawFeedback();
assert.equal(rangeCalls.length,0,'Idle towers do not show attack range');
viewTower.hover_amount=0.4;drawFeedback();
assert.ok(Math.abs(rangeCalls.pop()-2.3638)<1e-9,'Hover radius eases toward full size');
viewTower.hover_amount=0.2;drawFeedback();
assert.ok(Math.abs(rangeCalls.pop()-2.2684)<1e-9,'Leaving hover smoothly contracts');
viewTower.hover_amount=0;viewTower.selection_amount=1;drawFeedback();
assert.ok(Math.abs(rangeCalls.pop()-2.65)<1e-9,'An open tower GUI keeps full range visible');
assert.equal(read('objects/obj_placement/Draw_0.gml').includes('draw_range('),false);
assert.equal(definitions.vestral.burst_interval,0.09);
console.log('PASS: hover range, persistent selected range, no placement range, and charged-shot cadence.');

const enemyOverlay=read('objects/obj_enemy/Draw_73.gml');
assert.equal(enemyOverlay.includes('shock_stacks'),false,'Health overlay has no Lock stack squares');
assert.equal(enemyOverlay.includes('LOCK'),false,'Health overlay has no LOCK text');
assert.ok(read('objects/obj_enemy/Draw_0.gml').includes('lock_visual'),'Lock has an in-world chain effect');
const uiDraw=read('objects/obj_ui/Draw_64.gml');
assert.equal(/DRAG\s+orbit|P\s+pause|R\s+restart/i.test(uiDraw),false,'Legacy control legend is removed');
console.log('PASS: chain-based Lock feedback, clean enemy health bars, and removed legacy control legend.');


// Vestral: independent hit accounting, unlimited attacks and status timing.
const victim=enemy(10000), v=makeTower([victim]);
assert.equal(/\bammo\b/i.test(read('scripts/scr_combat/scr_combat.gml')+read('scripts/scr_definitions/scr_definitions.gml')+read('objects/obj_tower/Draw_73.gml')),false,'Vestral has no ammo system or counter');
fireBasic(v,victim);
assert.equal(victim.hit_points,9980);
assert.equal(v.s.hits_landed,2);
assert.equal(victim.shock_stacks,2);
assert.equal(victim.shock_slow,0.1);
for(let i=0;i<3;i++) fireBasic(v,victim);
assert.equal(victim.shock_stacks,8);
assert.equal(victim.shock_slow,0.4);
assert.equal(victim.lock_left,0.8);
assert.equal(v.api.movement(victim,0.2),0,'Lock prevents movement');
fireBasic(v,victim);
assert.ok(Math.abs(victim.lock_left-0.6)<1e-9,'Refreshing capped slow must not refresh Lock');
assert.ok(Math.abs(v.api.movement(victim,0.7)-0.1)<1e-9,'Movement resumes when Lock ends mid-frame');
assert.equal(victim.shock_stacks,0);
assert.equal(victim.shock_slow,0);
for(let i=0;i<8;i++) v.api.shock(victim,definitions.vestral);
assert.equal(victim.lock_left,0.8,'A new set of stacks can Lock again');
const sustained=makeTower([enemy(10000)]);
for(let i=0;i<40;i++) fireBasic(sustained,sustained.api.target(sustained.s));
assert.equal(sustained.s.shots_fired,40,'Vestral never runs out of ammo');
assert.equal(sustained.s.hits_landed,80);
const fragile=makeTower([enemy(5)]);
fireBasic(fragile,fragile.api.target(fragile.s));
assert.equal(fragile.s.hits_landed,1,'No second damage event against a dead enemy');
assert.equal(fragile.s.damage_dealt,5);
assert.equal(fragile.s.kills,1);
const targets=[enemy(20),enemy(1000)]; const retarget=makeTower(targets);
retarget.api.charge(retarget.s); run(retarget,504);
assert.equal(retarget.s.shots_fired,4);
assert.equal(targets[1].hit_points,940,'Burst retargets after a kill');
const leavingEnemy=enemy(); const waiting=makeTower([leavingEnemy]);
waiting.api.charge(waiting.s); run(waiting,384); leavingEnemy.world_x=99;
run(waiting,120); assert.equal(waiting.s.stored_shots,4);
leavingEnemy.world_x=1; run(waiting,150); assert.equal(waiting.s.shots_fired,4);
console.log('PASS: Double Tap damage, unlimited attacks, lethal hits, shock cap/refresh/expiry, longer Lock, retargeting and waiting.');

const panel={panel_left:24,panel_top:438,panel_open:1,spawn_left:30,spawn_top:60,spawn_width:214,spawn_height:42,term_regions:[],tooltip_rect:[0,0,0,0]};
const richDraws=[];
const uiHost={clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),noone:null,obj_ui:panel,obj_game:{selected_tower:v.s,ui_theme:{underline:0}},mb_left:1,mx:0,my:0,
  loadout_pointer_blocked:()=>false,loadout_handle_input:()=>false,
  instance_exists:e=>e!=null,mouse_check_button_pressed:()=>true,
 point_in_rectangle:(x,y,l,t,r,b)=>x>=l&&x<=r&&y>=t&&y<=b,string_width:s=>s.length*6,
 string_height:()=>12,string_length:s=>s.length,string_char_at:(s,i)=>s[i-1],
 draw_set_colour:()=>{},draw_line:()=>{},draw_text:(x,y,text)=>richDraws.push({x,y,text}),array_push:(a,v)=>a.push(v),
 UiAction,GlossaryTerm,TowerTargetMode,array_length:a=>a.length,is_undefined:v=>v===undefined};
uiHost.device_mouse_x_to_gui=()=>uiHost.mx;
uiHost.device_mouse_y_to_gui=()=>uiHost.my;
uiHost.game_select_tower=t=>uiHost.obj_game.selected_tower=t;
uiHost.tower_cancel_move=()=>false;
const uiApi=new Function('s',`with(s){${feedbackSource};return {click:ui_handle_input,blocked:ui_pointer_blocked,term:ui_term_at_pointer,rich:ui_draw_rich_text};}`)(uiHost);
assert.equal(v.s.ability_detail_open,false,'Ability descriptions start closed');
const tabPositions=[[485,17],[485,61],[485,105]];
for(let i=0;i<3;i++) {
 uiHost.mx=panel.panel_left+tabPositions[i][0];uiHost.my=panel.panel_top+tabPositions[i][1];
 assert.equal(uiApi.blocked(),true); uiApi.click(); assert.equal(v.s.ability_tab,i);
 assert.equal(v.s.ability_detail_open,true);
 assert.equal(uiHost.obj_game.selected_tower,v.s,'Ability tabs must not close the panel');
}
uiHost.mx=panel.panel_left+50;uiHost.my=panel.panel_top+230;
uiApi.click();assert.equal(v.s.target_mode,1);
panel.term_regions=[{term:GlossaryTerm.GreatPowers,left:100,top:470,right:180,bottom:490},
 {term:GlossaryTerm.Lock,left:650,top:540,right:690,bottom:560},
 {term:GlossaryTerm.Charge,left:720,top:510,right:770,bottom:530}];
uiHost.mx=120;uiHost.my=480;
assert.equal(uiApi.term(),0,'Great powers exposes a glossary card');
v.s.ability_tab=1;uiHost.mx=660;uiHost.my=550;
assert.equal(uiApi.term(),2,'Lock exposes a glossary card');
v.s.ability_tab=2;uiHost.mx=730;uiHost.my=520;
assert.equal(uiApi.term(),1,'Charge exposes a glossary card');
uiHost.mx=panel.panel_left+1000;uiHost.my=panel.panel_top+280;
assert.equal(uiApi.blocked(),false,'Empty space between UI modules must remain clickable world space');
uiApi.click();assert.equal(uiHost.obj_game.selected_tower,v.s,'Tower dossier has no close button');
const towerUiCopy=read('objects/obj_ui/Draw_64.gml');
const towerDefinitionCopy=read('scripts/scr_definitions/scr_definitions.gml');
assert.ok(towerDefinitionCopy.includes('Basic Attacks fire twice, each dealing 50% of ATK.'));
assert.ok(towerDefinitionCopy.includes('Basic Attacks slow enemies for 5%, lasting for 0.4s.'));
assert.ok(towerDefinitionCopy.includes('instead, release it at the end of charge with a low delay between shots.'));
assert.ok(towerUiCopy.includes('ui_draw_rich_text')&&feedbackSource.includes('ui_register_term'),'Skill copy uses shared wrapping and generated glossary regions');
for(const ability of [definitions.vestral.abilities[TowerAbility.ShockBolts],definitions.vestral.abilities[TowerAbility.Overloaded]]) {
 richDraws.length=0;panel.term_regions=[];uiApi.rich(0,0,100,ability.paragraphs,18,0);
 assert.ok(richDraws.every(token=>token.x+token.text.length*6<=100),`${ability.title} text must remain inside its box`);
}
assert.equal(towerDefinitionCopy.includes('*great powers*')||towerDefinitionCopy.includes('*Charge*')||towerDefinitionCopy.includes('Lock*'),false,'Visible glossary terms have no asterisks');
uiHost.mx=panel.panel_left+tabPositions[2][0];uiHost.my=panel.panel_top+tabPositions[2][1];uiApi.click();
assert.equal(v.s.ability_detail_open,false,'Clicking the open vertical ability closes its description');
console.log('PASS: modular hit regions, click-through empty space, wrapped catalog copy, vertical ability tabs, and generated glossary regions.');

const worldDraw=read('objects/obj_world/Draw_0.gml');
assert.equal(worldDraw.includes('shard'),false,'Triangular platform-end shards are removed');
const worldCreate=read('objects/obj_world/Create_0.gml');
const mapSource=read('scripts/scr_map/scr_map.gml');
const roomSource=read('rooms/Room1/Room1.yy');
const roomData=JSON.parse(roomSource.replace(/,\s*([}\]])/g,'$1'));
const mapInstances=roomData.layers.find(layer=>layer.name==='Instances').instances;
const routeMarkers=mapInstances.filter(instance=>instance.objectId.name==='obj_map_route').sort((a,b)=>a.imageIndex-b.imageIndex);
assert.equal(routeMarkers.length,14);
assert.deepEqual(routeMarkers.map(marker=>marker.imageIndex),Array.from({length:14},(_,i)=>i),'Room route markers keep a complete travel order');
assert.ok(mapSource.includes('terrain_style:"null_pillar"'),'Map has bold, uninterrupted null mountain masses');
assert.ok(worldCreate.includes('land_shelves=')&&worldCreate.includes('void_regions=')&&worldCreate.includes('sky_constellations=')&&worldCreate.includes('sky_constellation_links='),'Shelves, absence and aerial constellations share authored realm data');
assert.ok(worldCreate.includes('map_collect_route()')&&roomSource.includes('obj_map_route')&&roomSource.includes('obj_map_surface')&&roomSource.includes('obj_map_void')&&roomSource.includes('obj_map_terrain'),'Gameplay map geometry is authored with Room Editor markers');
assert.equal(worldCreate.includes('surface_faults='),false,'Ground crack data is removed');
assert.equal(worldDraw.includes('surface_faults'),false,'Ground cracks are not rendered');
assert.equal(/pylon|registry|terminal|sky_nodes/i.test(worldDraw+worldCreate),false,'Environment contains no engineered pylons, terminals or sky frame');
assert.ok(worldDraw.includes('array_length(land_shelves)'),'Renderer uses connected isometric shelf planes');
assert.ok(worldDraw.includes('array_length(void_regions)'),'Renderer cuts a physical void into the shelf');
assert.ok(worldDraw.includes('array_length(sky_constellations)')&&worldDraw.includes('link_progress')&&worldDraw.includes('project_x(point[0],point[1])'),'Constellations zip through projected world coordinates');
assert.ok(mapSource.includes('function map_draw_spawn_platform')&&worldDraw.includes('map_draw_spawn_platform(route,elapsed)'),
    'A red warning platform is anchored to the first authored route node');
assert.ok(mapSource.includes('function map_draw_base_platform')&&worldDraw.includes('map_draw_base_platform(route,elapsed)'),
    'An aqua shield platform is anchored to the final authored route node');
assert.ok(mapSource.includes('_route[0]')&&mapSource.includes('_route[array_length(_route)-1]'),
    'Endpoint landmarks follow room-authored route changes');
assert.ok(mapSource.includes('make_colour_rgb(235,61,69)')&&mapSource.includes('make_colour_rgb(103,226,221)'),
    'Spawn and base outlines retain their red and aqua identities');
assert.equal(worldDraw.includes('map_draw_spawn_portal')||worldDraw.includes('map_draw_base_rift'),false,
    'The former portal and vertical rift are no longer drawn');
assert.equal(/for\s*\(var tier=/.test(read('objects/obj_terrain/Draw_0.gml')),false,'Mountain silhouettes are single masses, not cube stacks');
const lockDraw=read('objects/obj_enemy/Draw_0.gml');
assert.ok(lockDraw.includes('var link_t=')&&!lockDraw.includes('chain_dark'),'Lock uses one link per clean chain');
console.log('PASS: clean ground plane, connected isometric strata, solid mountain silhouettes, periodic physical constellations, and minimal Lock chains.');


// The UI can process input at invalid depths while silently failing to render.
const roomStartup=read('rooms/Room1/RoomCreationCode.gml');
const uiDepth=Number(roomStartup.match(/instance_create_depth\(0,0,(-?\d+),obj_ui\)/)[1]);
assert.ok(uiDepth>-16000 && uiDepth<16000,'UI must be created inside the drawable depth range');
const uiEvents=read('objects/obj_ui/obj_ui.yy');
assert.ok(uiEvents.includes('"visible":true') && /"eventNum":64,"eventType":8/.test(uiEvents),'Visible UI must bind Draw GUI');
const enemyCatalog=new Function('GlossaryTerm','TowerAbility',`${translate(read('scripts/scr_definitions/scr_definitions.gml'))}; return build_enemy_catalog();`)(GlossaryTerm,TowerAbility);
assert.equal(enemyCatalog.heavy.max_hit_points,enemyCatalog.intrusion.max_hit_points*3);
assert.equal(enemyCatalog.heavy.move_speed,enemyCatalog.intrusion.move_speed*0.5);
const spawned=[];
uiHost.obj_enemy='enemy';
uiHost.instance_create_depth=(x,y,depth,object,settings)=>spawned.push({object,settings});
uiHost.mx=panel.spawn_left+20;uiHost.my=panel.spawn_top+20;
uiHost.obj_game.selected_tower=null;
assert.equal(uiHost.obj_game.selected_tower,null);
assert.equal(uiApi.blocked(),true,'Spawn button blocks world gestures without a selected tower');
let roundRequests=0;
uiHost.encounter_start_round=()=>{roundRequests++;};
uiApi.click();assert.equal(roundRequests,1,'Round button dispatches to the guarded encounter controller');
assert.equal(spawned.length,0,'Round button must not directly create a debug enemy');
uiHost.obj_game.paused=false;
const initEnemy=new Function('s',`with(s){${read('objects/obj_enemy/Create_0.gml')}}`);
for(const type of ['intrusion','fast','heavy']) {
 const e={id:null,noone:null,enemy_type:type,health_scale:1,random:n=>n*0.37,ceil:Math.ceil,arctan2:Math.atan2,pi:Math.PI,obj_game:{enemy_catalog:enemyCatalog},obj_world:{route:[[1,2],[2,2]]},
 variable_instance_exists:(id,key)=>key in id,variable_struct_get:(s,k)=>s[k],project_x:x=>x,project_y:(x,y)=>y};
 for(const match of read('objects/obj_enemy/Create_0.gml').matchAll(/^([a-z_]+)=/gm))e[match[1]]=undefined;
 e.id=e;initEnemy(e);
 assert.equal(e.hit_points,enemyCatalog[type].max_hit_points);
 assert.equal(e.max_hit_points,e.hit_points);
 assert.equal(e.enemy_definition.move_speed,enemyCatalog[type].move_speed);
 assert.equal(e.spawn_left,enemyCatalog[type].spawn_duration);
 assert.ok(e.drift_phase>0 && e.drift_phase<Math.PI*2);
}
console.log('PASS: GUI binding, round button dispatch without selection, and all three Blank initializations.');

// Relocation uses the same instance and rejects path, terrain and occupied ground.
const mover=makeTower([enemy()]);
const terrain=[{world_x:4,world_y:4,radius:0.6}];
const neighbour={world_x:5,world_y:5};
const moveState={obj_game:shared,obj_world:{route:[[1,1],[2,1]],void_regions:[[6,0,7,1]]},obj_terrain:'terrain',obj_tower:'tower',obj_placement:null,
 noone:null,max:Math.max,abs:Math.abs,array_length:a=>a.length,
 point_distance:(x,y,a,b)=>Math.hypot(x-a,y-b),project_x:x=>x*10,project_y:(x,y)=>y*10,
 TowerChargeState,TowerTargetMode,clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),lerp:(a,b,t)=>a+(b-a)*t,power:Math.pow,
 instance_exists:v=>v!=null&&!v.destroyed,instance_number:o=>o==='terrain'?terrain.length:2,
 instance_find:(o,i)=>o==='terrain'?terrain[i]:[mover.s,neighbour][i]};
moveState.map_point_on_surface=(x,y)=>x>=-0.15&&x<=8.15&&y>=-0.15&&y<=6.15&&!(x>=5.66&&x<=7.34&&y>=-0.34&&y<=1.34);
moveState.variable_instance_exists=(owner,key)=>owner!=null&&key in owner;
moveState.instance_create_depth=(x,y,d,o,settings)=>{moveState.obj_placement={...settings};};
moveState.instance_destroy=o=>{o.destroyed=true;moveState.obj_placement=null;};
const moveApi=new Function('s',`with(s){${code};return {start:tower_request_move,cancel:tower_cancel_move,commit:tower_commit_move,valid:placement_is_valid};}`)(moveState);
assert.equal(moveApi.valid(1,1,mover.s),false);
assert.equal(moveApi.valid(4,4,mover.s),false);
assert.equal(moveApi.valid(5,5,mover.s),false);
assert.equal(moveApi.valid(6.5,0.5,mover.s),false,'Terrain absences reject placement');
assert.equal(moveApi.valid(-1,2,mover.s),false);
assert.equal(moveApi.valid(3,3,mover.s),true);
mover.s.kills=2;mover.s.damage_dealt=160;mover.s.cooldown=0.4;
assert.equal(moveApi.start(mover.s),true);
assert.equal(moveApi.start(mover.s),false,'Cannot start a duplicate relocation');
assert.equal(mover.api.charge(mover.s),false,'Cannot charge while moving');
const remaining=mover.s.cooldown;run(mover,120);assert.equal(mover.s.cooldown,remaining,'Movement freezes this tower combat clock');
assert.equal(moveApi.commit(mover.s,1,1),false);
assert.equal(mover.s.world_x,0,'Invalid destination leaves original position unchanged');
assert.equal(moveApi.cancel(),true);
assert.equal(mover.s.relocating,false);
assert.equal(mover.s.world_x,0);
assert.equal(moveApi.start(mover.s),true);
shared.paused=true;assert.equal(moveApi.commit(mover.s,3,3),false);shared.paused=false;
assert.equal(moveApi.commit(mover.s,3,3),true);
assert.equal(mover.s.move_active,true,'A valid move starts the phase dash instead of teleporting');
assert.equal(mover.s.world_x,0,'The dash begins at the original footprint');
assert.ok(Math.abs(mover.s.move_duration-Math.hypot(3,3)/mover.s.move_speed)<1e-9);
run(mover,Math.ceil(mover.s.move_duration*120));
assert.deepEqual([mover.s.world_x,mover.s.world_y,mover.s.kills,mover.s.damage_dealt,mover.s.cooldown],[3,3,2,160,0.4]);
assert.equal(mover.s.relocating,false);
assert.equal(mover.s.move_active,false);
moveState.obj_placement=null;mover.s.charge_mode=TowerChargeState.Charging;assert.equal(moveApi.start(mover.s),false);
uiHost.obj_game.selected_tower=mover.s;
let chargeClicks=0,moveClicks=0;
uiHost.tower_request_charge=t=>{assert.equal(t,mover.s);chargeClicks++;};
uiHost.tower_request_move=t=>{assert.equal(t,mover.s);moveClicks++;};
uiHost.mx=panel.panel_left+280;uiHost.my=panel.panel_top+230;uiApi.click();assert.equal(chargeClicks,1);
uiHost.mx=panel.panel_left+100;uiHost.my=panel.panel_top+269;uiApi.click();assert.equal(moveClicks,1);
console.log('PASS: room-surface footprint checks, duplicate/charge/pause guards, cancel, animated dash, preserved combat state and controls.');

// WANDERER uses the same production controller, with no autonomous attacks.
const hunterVictim=enemy(1000,20,5);
const hunter=makeTower([hunterVictim],definitions.wanderer);
run(hunter,600);
assert.equal(hunter.s.shots_fired,0);
assert.equal(hunter.api.target(hunter.s),null);
assert.equal(hunter.api.charge(hunter.s),true);
run(hunter,180);
assert.equal(hunter.s.shots_fired,0,'Execution keeps charging past the old 1.5s windup');
run(hunter,121);
assert.equal(hunterVictim.hit_points,940,'Execution hits outside normal range');
assert.equal(hunter.s.shots_fired,1);
assert.ok(hunter.s.charge_lockout>0);
assert.equal(hunterVictim.shock_stacks,0,'Hunter attacks never apply Shock Bolts');
assert.equal(hunter.s.vigil,0,'Zero-stack skills must remain usable');

const executeVictim=enemy(100,20);executeVictim.hit_points=63;
const execution=makeTower([executeVictim],definitions.wanderer);
execution.s.vigil=2;
execution.api.charge(execution.s);run(execution,301);
assert.equal(executeVictim.destroyed,true,'A hit leaving less than 3.5% executes');
assert.equal(execution.s.damage_dealt,63,'Execution damage counts actual remaining health');
assert.equal(execution.s.vigil,5,'Execution preserves two stacks and earns three for 63 damage');
assert.equal(execution.s.damage,66);
assert.ok(Math.abs(execution.s.charge_lockout-3.2)<0.01,'A killing Execution leaves 40% of its eight-second cooldown');
assert.equal(execution.api.charge(execution.s),false,'A kill cannot chain directly into another charge');
run(execution,385);assert.equal(execution.api.charge(execution.s),true);

const below=enemy(10000);below.hit_points=349;
const preExecute=makeTower([below],definitions.wanderer);
preExecute.api.fireHit(preExecute.s,below);
assert.equal(below.destroyed,true,'Already below threshold executes even above ATK');
assert.equal(preExecute.s.vigil_earned,4,'A kill grants at most four stacks');
const partial=makeTower([enemy(20)],definitions.wanderer);partial.s.charge_lockout=5;
partial.api.fireHit(partial.s,partial.s.instance_find('enemy',0));
assert.equal(partial.s.charge_lockout,2,'Mark removes 60% of the remaining cooldown');
const boundary=enemy(10000);boundary.hit_points=350;
const exact=makeTower([boundary],definitions.wanderer);exact.s.damage=0;
exact.api.fireHit(exact.s,boundary);
assert.equal(boundary.hit_points,350,'Exactly 3.5% does not execute');

const crossing=makeTower([enemy(100)],definitions.wanderer);
crossing.s.vigil_earned=11;crossing.s.damage=120;
crossing.api.fireHit(crossing.s,crossing.s.instance_find('enemy',0));
assert.equal(crossing.s.vigil_earned,15);
assert.equal(crossing.s.damage,123.5,'Only the twelfth lifetime stack gets the full ATK bonus');

const moveVictim=enemy(60,2);
const sniper=makeTower([moveVictim],definitions.wanderer);
Object.assign(sniper.s,{move_active:true,relocating:true,move_duration:2/sniper.s.move_speed,move_target_x:2,move_target_y:0,vigil:1,charge_lockout:5});
run(sniper,Math.ceil(sniper.s.move_duration*120));
assert.equal(sniper.s.move_active,false);
assert.equal(sniper.s.shots_fired,0,'Relocation no longer triggers a skill attack');
assert.equal(moveVictim.hit_points,60);
assert.equal(sniper.s.charge_lockout,5,'Relocation preserves the paused cooldown');
assert.equal(sniper.s.damage,60);
assert.equal(sniper.s.vigil,1,'Relocation no longer spends Vigil');
run(sniper,120);assert.equal(sniper.s.shots_fired,0);

const emptyHunter=makeTower([],definitions.wanderer);
emptyHunter.s.vigil=1;emptyHunter.api.charge(emptyHunter.s);
shared.paused=true;run(emptyHunter,200);
assert.equal(emptyHunter.s.charge_left,2.5);assert.equal(emptyHunter.s.vigil,1);
shared.paused=false;run(emptyHunter,301);
assert.equal(emptyHunter.s.shots_fired,0);
assert.equal(emptyHunter.s.vigil,1,'Execution preserves Vigil even without a target');
assert.equal(emptyHunter.s.charge_mode,TowerChargeState.Ready);
assert.ok(emptyHunter.s.charge_lockout>0,'An empty lane finishes cleanly');
const ordering=makeTower([enemy(100,12,9),enemy(300,8,2),enemy(50,5,1)],definitions.wanderer);
assert.equal(ordering.api.target(ordering.s,true).progress,9);
ordering.s.target_mode=TowerTargetMode.Strongest;assert.equal(ordering.api.target(ordering.s,true).hit_points,300);
ordering.s.target_mode=TowerTargetMode.Nearest;assert.equal(ordering.api.target(ordering.s,true).world_x,5);
shared.selected_tower=sniper.s;
uiHost.obj_game.selected_tower=sniper.s;
uiHost.mx=panel.panel_left+485;uiHost.my=panel.panel_top+149;
assert.equal(uiApi.blocked(),false,'The removed fourth ability leaves no invisible click region');
uiApi.click();assert.equal(sniper.s.ability_tab,0);
assert.equal(sniper.s.ability_detail_open,false);
assert.equal(definitions.wanderer.abilities.length,3);
console.log('PASS: WANDERER passive, global targeting, execute boundaries, Vigil cap/breakpoint, permanent ATK, 60% cooldown reduction, longer charge, removed move skill, empty lane and pause.');

// Exercise the actual procedural mesh across its animated poses and facings.
let meshVertices=[];
const rigHost={clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),lerp:(a,b,t)=>a+(b-a)*t,
  max:Math.max,sqrt:Math.sqrt,
  sin:Math.sin,dsin:v=>Math.sin(v*Math.PI/180),dcos:v=>Math.cos(v*Math.PI/180),
  make_colour_rgb:()=>0,merge_colour:()=>0,c_black:0,pr_trianglefan:0,
  array_length:a=>a.length,array_push:(a,v)=>a.push(v),array_sort:(a,f)=>a.sort(f),sign:Math.sign,
  draw_set_colour:()=>{},draw_primitive_begin:()=>{},draw_primitive_end:()=>{},
  draw_vertex:(x,y)=>{assert.ok(Number.isFinite(x)&&Number.isFinite(y));meshVertices.push([x,y]);}};
const rig=new Function('s',`with(s){${translate(read('scripts/scr_defender/scr_defender.gml'))};return {draw:draw_wanderer,muzzle:wanderer_muzzle};}`)(rigHost);
for(const angle of [0,90,180,270,300]) for(const pose of [[0,0,0,0,0],[1,0,1,1,0],[2,11,1,0,0],[3,0,1,0,1]]) {
  meshVertices=[];rig.draw(200,200,angle,...pose,1);
  assert.ok(meshVertices.length>100);
  const muzzle=rig.muzzle(200,200,angle,...pose,1);
  assert.ok(muzzle.every(Number.isFinite));
}
console.log('PASS: WANDERER procedural model produces finite geometry and muzzle positions across idle, charge, recoil, recovery and five facings.');

// Idle tracking must not stand the hunter up; only skills raise the weapon.
const resting=makeTower([enemy()],definitions.wanderer);run(resting,400);
assert.ok(resting.s.aim_blend<0.001);
resting.api.charge(resting.s);run(resting,90);assert.ok(resting.s.aim_blend>0.9 && resting.s.aim_blend<0.95);
shared.paused=true;const frozenPose=[resting.s.charge_left,resting.s.idle_time,resting.s.charge_pose];
run(resting,60);assert.deepEqual([resting.s.charge_left,resting.s.idle_time,resting.s.charge_pose],frozenPose);
shared.paused=false;
let sharedImpacts=0;resting.s.instance_create_depth=(x,y,d,o,s)=>{if(s.effect_kind!='text') sharedImpacts++;};
run(resting,211);assert.equal(sharedImpacts,0,'WANDERER never emits Vestral impact particles');
assert.ok(resting.s.finisher_flash>0.6,'Shot animation outlasts the brief damage beam');
run(resting,400);assert.ok(resting.s.aim_blend<0.001,'Returns to kneeling after recoil');
let effectCalls=0,fxAlpha=1,fxBlend=0;
const recordFx=(...values)=>{assert.ok(values.every(v=>typeof v==='boolean'||Number.isFinite(v)));effectCalls++;};
const fxHost={...rigHost,obj_camera:{zoom:1},TowerChargeState,pi:Math.PI,bm_add:1,bm_normal:0,c_white:0,
    frac:v=>v-Math.floor(v),power:Math.pow,
    project_x:x=>x,project_y:(x,y)=>y,tower_visual_y:t=>t.y,tower_move_progress:()=>0.5,
    tower_charge_progress:t=>1-t.charge_left/t.charge_duration,
    point_direction:(x,y,tx,ty)=>Math.atan2(y-ty,tx-x)*180/Math.PI,
    draw_set_alpha:v=>{assert.ok(Number.isFinite(v));fxAlpha=v;},gpu_set_blendmode:v=>fxBlend=v,
    draw_triangle:recordFx,draw_line_width:recordFx};
const fxApi=new Function('s',`with(s){${translate(read('scripts/scr_effects/scr_effects.gml'))};return {charge:tower_draw_charge_fx,shot:tower_draw_attack_fx,move:tower_draw_move_fx};}`)(fxHost);
const fxTower={...resting.s,definition:{...definitions.wanderer,muzzle:rig.muzzle},charge_mode:TowerChargeState.Charging};
for(const p of [0,0.5,0.99]) {fxTower.charge_left=fxTower.charge_duration*(1-p);effectCalls=0;fxApi.charge(fxTower);assert.ok(effectCalls>=110);}
for(const age of [0,0.12,0.4,0.64]) {fxTower.finisher_flash=0.65-age;effectCalls=0;fxApi.shot(fxTower);assert.ok(effectCalls>=92);}
fxTower.move_active=true;fxTower.move_from_x=0;fxTower.move_from_y=0;effectCalls=0;fxApi.move(fxTower);assert.equal(effectCalls,48);
assert.equal(fxAlpha,1);assert.equal(fxBlend,0);
console.log('PASS: kneeling with targets, skill rise/settle, paused poses, exclusive WANDERER particles, finite charge/shot/move effects and restored draw state.');

panel.term_regions=[];richDraws.length=0;
uiApi.rich(0,0,332,definitions.vestral.role_copy,18,0);
const phrase=panel.term_regions.filter(r=>r.term===GlossaryTerm.GreatPowers);
assert.equal(phrase.length,1,'Great powers is one continuous link');
assert.equal(phrase[0].right-phrase[0].left,uiHost.string_width('great powers'));
assert.ok(richDraws.some(d=>d.text==='great powers'));
Object.assign(uiHost,{string:String,string_format:(v,w,d)=>v.toFixed(d),min:Math.min,max:Math.max});
const stats=new Function('s',`with(s){${translate(read('scripts/scr_interface/scr_interface.gml'))};return ui_stat_breakdown;}`)(uiHost);
const buffed=makeTower([],definitions.wanderer);buffed.s.vigil_earned=15;buffed.s.damage=90.5;
const breakdown=stats(buffed.s,0).body;
assert.ok(breakdown.includes('12 x 2 = +24'));
assert.ok(breakdown.includes('3 x 0.5 = +1.5'));
assert.ok(breakdown.includes('Other adjustments: 5'));
assert.ok(breakdown.includes('Total ATK: 90.5'));
assert.ok(stats(buffed.s,1).body.includes('disables automatic attacks'));
assert.ok(stats(buffed.s,2).body.includes('Execution ignores range'));
assert.ok(stats(buffed.s,3).body.includes('Skill cooldown: 8s'));
uiHost.obj_game.selected_tower=buffed.s;uiHost.mx=panel.panel_left+25;uiHost.my=panel.panel_top-35;
assert.equal(uiApi.blocked(),true,'Vigil badge must not place towers through the UI');
uiHost.mx=panel.panel_left+48;assert.equal(uiApi.blocked(),false,'Shrinking the badge restores world clicks outside its new edge');
const notices=[];const notified=makeTower([enemy(100)],definitions.wanderer);
notified.s.instance_create_depth=(x,y,d,o,s)=>notices.push(s);
const lethal=notified.s.instance_find('enemy',0);lethal.hit_points=63;
notified.api.fireHit(notified.s,lethal);
assert.equal(notices.length,2);assert.equal(notices[0].effect_kind,'text');
assert.equal(notices[1].effect_kind,'vigil');assert.equal(notices[1].popup_stacks,3);
assert.equal(notices[0].popup_text,'63','Damage text includes executed remaining health');
const statuses=[];const statusTower=makeTower([enemy()]);
statusTower.s.instance_create_depth=(x,y,d,o,s)=>statuses.push(s);
const statusVictim=statusTower.s.instance_find('enemy',0);
for(let i=0;i<12;i++) statusTower.api.shock(statusVictim,definitions.vestral);
assert.deepEqual(statuses.map(s=>s.popup_text),['Slow','Lock'],'Status refreshes do not spam labels');
console.log('PASS: continuous glossary phrase, stat calculations and modifiers, badge hit region, lethal damage text and non-repeating status labels.');
assert.equal(notified.s.recoil,29,'WANDERER recoil starts stronger than its previous 19-unit kick');
const popup={effect_kind:'text',popup_status:true,popup_text:'Lock',popup_lane:0,world_x:1,world_y:1,
    age:0,lifetime:0,particles:[],obj_game:{paused:false},delta_time:100000,obj_camera:{zoom:1},
    id:{},variable_instance_exists:()=>true,min:Math.min,max:Math.max,power:Math.pow,sin:Math.sin,pi:Math.PI,
    clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),array_length:a=>a.length,instance_destroy:()=>{},
    project_x:x=>x,project_y:(x,y)=>y,fa_center:0,fa_bottom:1,fa_left:2,fa_top:3,c_black:0,
    make_colour_rgb:()=>0,draw_set_halign:()=>{},draw_set_valign:()=>{},draw_set_colour:()=>{},
    draw_set_alpha:a=>assert.ok(a>=0&&a<=1),draw_text:(x,y)=>assert.ok(Number.isFinite(x)&&Number.isFinite(y))};
const eventFn=p=>new Function('s',`with(s){${translate(read(p)).replace(/\bexit;/g,'return;')}}`);
eventFn('objects/obj_impact/Create_0.gml')(popup);assert.deepEqual(popup.particles,[]);
const popupStep=eventFn('objects/obj_impact/Step_0.gml');popup.obj_game.paused=true;popupStep(popup);assert.equal(popup.age,0);
popup.obj_game.paused=false;popupStep(popup);assert.equal(popup.age,0.05);
for(const age of [0,0.2,0.64]) {popup.age=age;eventFn('objects/obj_impact/Draw_0.gml')(popup);}
console.log('PASS: text effects create no particles, pause with gameplay, and draw finite bouncing/fading labels.');
// TRIAGE uses the production attack and charge controller.
{
 const victim=enemy(1000);victim.tourniquet_heal=0;
 const {s,api}=makeTower([victim],definitions.triage);
 s.hit_points=40;
 api.fireHit(s,victim);api.fireHit(s,victim);
 assert.equal(victim.tourniquet_heal,0);
 api.fireHit(s,victim);
 assert.equal(victim.hit_points,928);assert.ok(Math.abs(victim.tourniquet_heal-19.2)<1e-9);
 assert.equal(api.movement(victim,1),.75);assert.equal(victim.shock_stacks,0);
 victim.hit_points=1;api.fireHit(s,victim);
 assert.ok(Math.abs(s.hit_points-59.2)<1e-9);
 const meshes=new Function('s',`with(s){${translate(read('scripts/scr_defender/scr_defender.gml'))};return {draw:draw_triage,muzzle:triage_muzzle};}`)(rigHost);
 for(const angle of [0,90,180,270,320]) {
   meshes.draw(400,400,angle,1,4,1,1,0,3);
   assert.ok(meshes.muzzle(400,400,angle,1,4,1,1,0,3).every(Number.isFinite));
 }
 console.log('PASS: TRIAGE dart damage, third-hit Tourniquet, 25% slow, killer healing and model geometry.');
}

{
 const victim=enemy(500);victim.tourniquet_heal=24;
 const {s,api}=makeTower([victim],definitions.triage);
 s.obj_tower='tower';s.array_push=(a,v)=>a.push(v);
 s.instance_number=o=>o==='tower'?1:1;s.instance_find=o=>o==='tower'?s:victim;
 assert.equal(api.charge(s),true);
 shared.paused=true;api.tick();assert.equal(s.charge_left,2.5);shared.paused=false;
 for(let i=0;i<302 && s.charge_mode===TowerChargeState.Charging;i++)api.tick();
 assert.equal(s.charge_mode,TowerChargeState.Ready);assert.equal(victim.tourniquet_heal,0);
 assert.equal(s.shield_hp,33);assert.equal(s.hits_landed,0);assert.equal(s.charge_lockout,10);
 s.move_elapsed=0;s.move_duration=.1;s.move_active=true;s.relocating=true;
 s.move_from_x=0;s.move_from_y=0;s.move_target_x=3;s.move_target_y=0;
 for(let i=0;i<13;i++)api.tick();
 assert.equal(s.move_active,false);assert.equal(s.kit_left,12);assert.equal(s.kit_x,0);assert.equal(s.world_x,3);
 assert.deepEqual(s.kit_healed,[]);
 console.log('PASS: TRIAGE charge pause/completion, no charge attacks, cooldown and med-kit creation at departure point on arrival.');
}
{
 const e=enemy(1000);e.tourniquet_heal=0;
 const {s,api}=makeTower([e],definitions.triage);const emitted=[];
 s.instance_create_depth=(x,y,d,o,data)=>emitted.push(data);
 api.fireHit(s,e);api.fireHit(s,e);api.fireHit(s,e);
 assert.equal(emitted.filter(f=>f.fx_style==='dart').length,3);
 assert.equal(emitted.filter(f=>f.fx_style==='mark').length,1);
 assert.ok(!emitted.some(f=>f.effect_kind==='hit'||f.effect_kind==='kill'),'TRIAGE uses its own impact palette');
 e.hit_points=1;s.hit_points=40;api.fireHit(s,e);
 for(const style of ['kill','consume','heal'])assert.ok(emitted.some(f=>f.fx_style===style));
 const arc=emitted.find(f=>f.effect_kind==='heal_arc');assert.ok(arc);
 assert.equal(arc.world_x,e.world_x);assert.equal(arc.world_y,e.world_y);assert.equal(arc.fx_owner,s);
 console.log('PASS: TRIAGE attacks emit pink dart/mark effects and lethal Tourniquet triggers consume + healing cues.');
}

// Damage feedback holds the previous HP, then drains independently of live HP.
{
 const feedback=makeTower([]);const t=feedback.s;const previous=t.hit_points;
 t.hit_points=previous-30;t.hit_flash=.3;
 run(feedback,12);assert.equal(t.display_hit_points,previous,'Gray trail holds after impact');
 run(feedback,36);assert.ok(t.display_hit_points<previous&&t.display_hit_points>t.hit_points,'Gray trail catches up after the delay');
 t.obj_game.paused=true;const held=t.display_hit_points;run(feedback,24);assert.equal(t.display_hit_points,held);
 t.obj_game.paused=false;t.hit_points=previous;feedback.api.tick();assert.equal(t.display_hit_points,previous,'Healing clears the stale damage trail');
 console.log('PASS: delayed HP trail, smooth catch-up, pause and healing recovery.');
}
{
 const gravity=makeTower([],definitions.singularity);
 uiHost.obj_game.selected_tower=gravity.s;uiHost.mx=panel.panel_left+485;uiHost.my=panel.panel_top+149;
 assert.equal(uiApi.blocked(),true);uiApi.click();assert.equal(gravity.s.ability_tab,3);assert.equal(gravity.s.ability_detail_open,true);
 uiApi.click();assert.equal(gravity.s.ability_detail_open,false);
 assert.ok(stats(gravity.s,1).body.includes('downtime only'));
 console.log('PASS: SINGULARITY fourth ability input and fixed-windup stat explanation.');
}
{
 const gravity=makeTower([],definitions.singularity);uiHost.obj_game.selected_tower=gravity.s;
 for(const badgeX of [22,76]) {uiHost.mx=panel.panel_left+badgeX;uiHost.my=panel.panel_top-30;assert.equal(uiApi.blocked(),true);}
 uiHost.mx=panel.panel_left+49;assert.equal(uiApi.blocked(),false,'Space between badges stays click-through');
 console.log('PASS: Debris/Density badges own their visible hit regions without blocking the gap.');
}
