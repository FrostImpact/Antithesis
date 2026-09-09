// Executes the production GML control functions in an isolated JS host.
// This checks state transitions, not GameMaker rendering or engine event binding.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const translate = text => text.replace(/\bmod\b/g, '%');
const definitions = new Function('draw_defender', 'defender_muzzle', `${translate(read('scripts/scr_definitions/scr_definitions.gml'))}; return build_tower_catalog();`)(() => {}, () => {});
const code = translate(read('scripts/scr_combat/scr_combat.gml'));
const shared = { paused: false };
function makeTower(enemies, definition = definitions.vestral) {
  const s = {
    tower_type: 'vestral', world_x: 0, world_y: 0, x: 0, y: 0,
    obj_game: shared, obj_enemy: 'enemy', obj_impact: 'impact',
    noone: null, delta_time: 1e6 / 120,
    min: Math.min, max: Math.max, abs: Math.abs, exp: Math.exp, sin: Math.sin, pi: Math.PI,
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
  };
  // GML implicitly creates instance fields. Predeclare those fields in this host.
  const init = code.slice(code.indexOf('function tower_initialize'), code.indexOf('function tower_tick'));
  for (const match of init.matchAll(/^([a-z_]+)=/gm)) s[match[1]] = undefined;
  for (const key of ['kills', 'damage_dealt', 'shots_fired', 'hover_amount', 'selection_amount', 'select_pulse', 'reject_pulse', 'beam_world_y']) s[key] = 0;
  s.id = s;
  const api = new Function('s', `with(s) { ${code}; return {init:tower_initialize,tick:tower_tick,charge:tower_request_charge,target:tower_find_target,progress:tower_charge_progress,fire:tower_fire,shock:enemy_apply_shock,movement:enemy_movement_time}; }`)(s);
  api.init(); s.settle = 0; s.facing = 0; s.aim_blend = 1;
  return { s, api };
}
const enemy = (health = 1000, worldX = 1, progress = 1) => ({ hit_points: health, world_x: worldX, world_y: 0, x: 20, y: 0, progress, shock_stacks:0, shock_left:0, shock_slow:0, lock_left:0 });
const run = (tower, frames) => { for (let i = 0; i < frames; i++) tower.api.tick(); };

const first = enemy(1000, 2, 8), strong = enemy(2000, 1.5, 2), near = enemy(500, 0.5, 1), outside = enemy(9999, 9, 99);
const t = makeTower([first, strong, near, outside]);
assert.equal(t.api.target(t.s), first);
t.s.target_mode = 1; assert.equal(t.api.target(t.s), strong);
t.s.target_mode = 2; assert.equal(t.api.target(t.s), near);

const a = makeTower([enemy()]), b = makeTower([enemy()]);
assert.equal(a.api.charge(a.s), true);
assert.equal(b.s.charge_mode, 'ready', 'Another tower must keep independent state');
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

const empty = makeTower([]);
empty.api.charge(empty.s); run(empty, 500);
assert.equal(empty.s.shots_fired, 0);
assert.equal(empty.s.stored_shots, 0);
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
console.log('PASS: targeting modes/range, independent tower state, charge suppression, Double Tap burst, queue retention, empty charge, pause, reuse delay, definition-driven stats.');

const actor = { x: 500, y: 300, facing: 300, charge_mode: 'ready' };
const input = {
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
input.mouse_check_button = () => input.held;
input.mouse_check_button_released = () => input.released;
input.mouse_wheel_up = () => input.wheel_up;
input.mouse_wheel_down = () => input.wheel_down;
input.keyboard_check_pressed = key => key === input.key;
input.game_select_tower = tower => { input.obj_game.selected_tower = tower; };
input.tower_request_charge = tower => { if (tower) input.charge_requests++; };
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

// Evaluate every cursor branch: GML compiles unknown constants as variable reads.
const uiStep = read('objects/obj_ui/Step_2.gml');
const cursorStep = new Function('s', `with(s) { ${uiStep.slice(uiStep.indexOf('var next_cursor='))} }`);
const cursor = {obj_input:{dragging:false,hovered_tower:null},active_cursor:0,hovered_term:-1,
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
v.api.fire(v.s,victim);
assert.equal(victim.hit_points,9980);
assert.equal(v.s.hits_landed,2);
assert.equal(victim.shock_stacks,2);
assert.equal(victim.shock_slow,0.1);
for(let i=0;i<3;i++) v.api.fire(v.s,victim);
assert.equal(victim.shock_stacks,8);
assert.equal(victim.shock_slow,0.4);
assert.equal(victim.lock_left,0.8);
assert.equal(v.api.movement(victim,0.2),0,'Lock prevents movement');
v.api.fire(v.s,victim);
assert.ok(Math.abs(victim.lock_left-0.6)<1e-9,'Refreshing capped slow must not refresh Lock');
assert.ok(Math.abs(v.api.movement(victim,0.7)-0.1)<1e-9,'Movement resumes when Lock ends mid-frame');
assert.equal(victim.shock_stacks,0);
assert.equal(victim.shock_slow,0);
for(let i=0;i<8;i++) v.api.shock(victim,definitions.vestral);
assert.equal(victim.lock_left,0.8,'A new set of stacks can Lock again');
const sustained=makeTower([enemy(10000)]);
for(let i=0;i<40;i++) sustained.api.fire(sustained.s,sustained.api.target(sustained.s));
assert.equal(sustained.s.shots_fired,40,'Vestral never runs out of ammo');
assert.equal(sustained.s.hits_landed,80);
const fragile=makeTower([enemy(5)]);
fragile.api.fire(fragile.s,fragile.api.target(fragile.s));
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
leavingEnemy.world_x=1; run(waiting,120); assert.equal(waiting.s.shots_fired,4);
console.log('PASS: Double Tap damage, unlimited attacks, lethal hits, shock cap/refresh/expiry, longer Lock, retargeting and waiting.');

const panel={panel_left:24,panel_top:438,panel_width:1044,panel_height:290,panel_open:1,spawn_left:30,spawn_top:60,spawn_width:214,spawn_height:42};
const uiHost={clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),noone:null,obj_ui:panel,obj_game:{selected_tower:v.s},mb_left:1,mx:0,my:0,
  instance_exists:e=>e!=null,mouse_check_button_pressed:()=>true,
 point_in_rectangle:(x,y,l,t,r,b)=>x>=l&&x<=r&&y>=t&&y<=b,string_width:s=>s.length*6};
uiHost.device_mouse_x_to_gui=()=>uiHost.mx;
uiHost.device_mouse_y_to_gui=()=>uiHost.my;
uiHost.game_select_tower=t=>uiHost.obj_game.selected_tower=t;
uiHost.tower_cancel_move=()=>false;
const uiApi=new Function('s',`with(s){${feedbackSource};return {click:ui_handle_input,blocked:ui_pointer_blocked,term:ui_term_at_pointer};}`)(uiHost);
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
uiHost.mx=panel.panel_left+120;uiHost.my=panel.panel_top+50;
assert.equal(uiApi.term(),0,'Great powers exposes a glossary card');
v.s.ability_tab=1;uiHost.mx=panel.panel_left+620+"Upon reaching maximum stacks, the enemy is inflicted with ".length*6+2;uiHost.my=panel.panel_top+120;
assert.equal(uiApi.term(),2,'Lock exposes a glossary card');
v.s.ability_tab=2;uiHost.mx=panel.panel_left+620+"For every attack that would have been performed during ".length*6+2;uiHost.my=panel.panel_top+60;
assert.equal(uiApi.term(),1,'Charge exposes a glossary card');
uiHost.mx=panel.panel_left+1000;uiHost.my=panel.panel_top+280;
uiApi.click();assert.equal(uiHost.obj_game.selected_tower,v.s,'Tower dossier has no close button');
const towerUiCopy=read('objects/obj_ui/Draw_64.gml');
assert.ok(towerUiCopy.includes('Basic Attacks fire twice, each dealing 50% ATK.'));
assert.ok(towerUiCopy.includes('Basic Attacks slow enemies for 5%, lasting for 0.4s.'));
assert.ok(towerUiCopy.includes('instead, release it at the end of charge with a low delay between shots.'));
assert.equal(towerUiCopy.includes('*great powers*')||towerUiCopy.includes('*Charge*')||towerUiCopy.includes('Lock*'),false,'Visible glossary terms have no asterisks');
uiHost.mx=panel.panel_left+tabPositions[2][0];uiHost.my=panel.panel_top+tabPositions[2][1];uiApi.click();
assert.equal(v.s.ability_detail_open,false,'Clicking the open vertical ability closes its description');
console.log('PASS: fitted modular dossier, vertical ability stack, closed-by-default descriptions, underlined hover glossary, exact skill copy, and no close button.');

const worldDraw=read('objects/obj_world/Draw_0.gml');
assert.equal(worldDraw.includes('shard'),false,'Triangular platform-end shards are removed');
const worldCreate=read('objects/obj_world/Create_0.gml');
assert.ok(worldCreate.includes('terrain_style:"null_pillar"'),'Map has bold, uninterrupted null mountain masses');
assert.ok(worldCreate.includes('land_shelves=')&&worldCreate.includes('void_regions=')&&worldCreate.includes('sky_constellations=')&&worldCreate.includes('sky_constellation_links='),'Shelves, absence and aerial constellations share authored realm data');
assert.equal(worldCreate.includes('surface_faults='),false,'Ground crack data is removed');
assert.equal(worldDraw.includes('surface_faults'),false,'Ground cracks are not rendered');
assert.equal(/pylon|registry|terminal|sky_nodes/i.test(worldDraw+worldCreate),false,'Environment contains no engineered pylons, terminals or sky frame');
assert.ok(worldDraw.includes('array_length(land_shelves)'),'Renderer uses connected isometric shelf planes');
assert.ok(worldDraw.includes('array_length(void_regions)'),'Renderer cuts a physical void into the shelf');
assert.ok(worldDraw.includes('array_length(sky_constellations)')&&worldDraw.includes('link_progress')&&worldDraw.includes('project_x(point[0],point[1])'),'Constellations zip through projected world coordinates');
assert.equal(/for\s*\(var tier=/.test(read('objects/obj_terrain/Draw_0.gml')),false,'Mountain silhouettes are single masses, not cube stacks');
const lockDraw=read('objects/obj_enemy/Draw_0.gml');
assert.ok(lockDraw.includes('var link_t=')&&!lockDraw.includes('chain_dark'),'Lock uses one link per clean chain');
console.log('PASS: clean ground plane, connected isometric strata, solid mountain silhouettes, periodic physical constellations, and minimal Lock chains.');


// The UI can process input at invalid depths while silently failing to render.
const roomStartup=read('rooms/Room1/RoomCreationCode.gml');
const uiDepth=Number(roomStartup.match(/instance_create_depth\(0,0,(-?\d+),obj_ui\)/)[1]);
assert.ok(uiDepth>-16000 && uiDepth<16000,'UI must be created inside the drawable depth range');
const uiEvents=JSON.parse(read('objects/obj_ui/obj_ui.yy'));
assert.ok(uiEvents.visible && uiEvents.eventList.some(e=>e.eventType===8 && e.eventNum===64),'Visible UI must bind Draw GUI');
const enemyCatalog=new Function(`${translate(read('scripts/scr_definitions/scr_definitions.gml'))}; return build_enemy_catalog();`)();
assert.equal(enemyCatalog.heavy.max_hit_points,enemyCatalog.intrusion.max_hit_points*3);
assert.equal(enemyCatalog.heavy.move_speed,enemyCatalog.intrusion.move_speed*0.5);
const spawned=[];
uiHost.obj_enemy='enemy';
uiHost.instance_create_depth=(x,y,depth,object,settings)=>spawned.push({object,settings});
uiHost.mx=panel.spawn_left+20;uiHost.my=panel.spawn_top+20;
uiHost.obj_game.selected_tower=null;
assert.equal(uiHost.obj_game.selected_tower,null);
assert.equal(uiApi.blocked(),true,'Spawn button blocks world gestures without a selected tower');
uiApi.click();assert.deepEqual(spawned,[{object:'enemy',settings:{enemy_type:'heavy'}}]);
uiHost.obj_game.paused=true;uiApi.click();assert.equal(spawned.length,1,'Paused button must not spawn');
uiHost.obj_game.paused=false;
const initEnemy=new Function('s',`with(s){${read('objects/obj_enemy/Create_0.gml')}}`);
for(const type of ['intrusion','heavy']) {
 const e={id:null,enemy_type:type,obj_game:{enemy_catalog:enemyCatalog},obj_world:{route:[[1,2]]},
 variable_instance_exists:(id,key)=>key in id,variable_struct_get:(s,k)=>s[k],project_x:x=>x,project_y:(x,y)=>y};
 for(const match of read('objects/obj_enemy/Create_0.gml').matchAll(/^([a-z_]+)=/gm))e[match[1]]=undefined;
 e.id=e;initEnemy(e);
 assert.equal(e.hit_points,enemyCatalog[type].max_hit_points);
 assert.equal(e.max_hit_points,e.hit_points);
 assert.equal(e.enemy_definition.move_speed,enemyCatalog[type].move_speed);
}
console.log('PASS: drawable GUI depth/event binding, spawn button without selection, pause guard and heavy enemy initialization.');

// Relocation uses the same instance and rejects path, terrain and occupied ground.
const mover=makeTower([enemy()]);
const terrain=[{world_x:4,world_y:4,radius:0.6}];
const neighbour={world_x:5,world_y:5};
const moveState={obj_game:shared,obj_world:{route:[[1,1],[2,1]],void_regions:[[6,0,7,1]]},obj_terrain:'terrain',obj_tower:'tower',obj_placement:null,
 noone:null,max:Math.max,abs:Math.abs,array_length:a=>a.length,
 point_distance:(x,y,a,b)=>Math.hypot(x-a,y-b),project_x:x=>x*10,project_y:(x,y)=>y*10,
 instance_exists:v=>v!=null&&!v.destroyed,instance_number:o=>o==='terrain'?terrain.length:2,
 instance_find:(o,i)=>o==='terrain'?terrain[i]:[mover.s,neighbour][i]};
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
assert.deepEqual([mover.s.world_x,mover.s.world_y,mover.s.kills,mover.s.damage_dealt,mover.s.cooldown],[3,3,2,160,0.4]);
assert.equal(mover.s.relocating,false);
moveState.obj_placement=null;mover.s.charge_mode='charging';assert.equal(moveApi.start(mover.s),false);
uiHost.obj_game.selected_tower=mover.s;
let chargeClicks=0,moveClicks=0;
uiHost.tower_request_charge=t=>{assert.equal(t,mover.s);chargeClicks++;};
uiHost.tower_request_move=t=>{assert.equal(t,mover.s);moveClicks++;};
uiHost.mx=panel.panel_left+280;uiHost.my=panel.panel_top+230;uiApi.click();assert.equal(chargeClicks,1);
uiHost.mx=panel.panel_left+100;uiHost.my=panel.panel_top+269;uiApi.click();assert.equal(moveClicks,1);
console.log('PASS: relocation footprint checks, duplicate/charge/pause guards, cancel, preserved combat state and Charge/Move buttons.');
