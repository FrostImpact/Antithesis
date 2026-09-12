// Exercise production laser state, damage and cleanup, including real enemy Step.
const fs=require('node:fs'),assert=require('node:assert/strict');
const read=p=>fs.readFileSync(p,'utf8').replace(/\bmod\b/g,'%').replace(/\bexit;/g,'return;');
const catalog=new Function(read('scripts/scr_definitions/scr_definitions.gml')+';return build_enemy_catalog();')();
const h={obj_game:{paused:false,selected_tower:null},obj_input:{hovered_tower:null},obj_placement:null,
 obj_tower:'tower',obj_impact:'impact',noone:null,towers:[],effects:[],notices:[],
 min:Math.min,max:Math.max,floor:Math.floor,exp:Math.exp,pi:Math.PI,string:String,array_push:(a,v)=>a.push(v),
 lerp:(a,b,t)=>a+(b-a)*t,point_distance:(x,y,a,b)=>Math.hypot(a-x,b-y),array_length:a=>a.length,
 instance_exists:o=>!!o&&!o.destroyed,instance_number:()=>h.towers.filter(t=>!t.destroyed).length,
 instance_find:(o,i)=>h.towers.filter(t=>!t.destroyed)[i],instance_destroy:o=>{o.destroyed=true;},
 instance_create_depth:(x,y,d,o,data)=>h.effects.push(data),
 game_select_tower:t=>h.obj_game.selected_tower=t,loadout_notice:t=>h.notices.push(t),
 project_x:x=>x,project_y:(x,y)=>y,encounter_record_escape:()=>{},
 obj_world:{route:[[0,0],[10,0],[20,0]]},delta_time:50000};
const api=new Function('h',`with(h){${read('scripts/scr_combat/scr_combat.gml')};return {tick:enemy_tick_laser,damage:tower_take_damage,target:enemy_laser_target,movement:enemy_movement_time};}`)(h);
h.enemy_tick_laser=api.tick;h.enemy_movement_time=api.movement;
const tower=(x=1)=>({world_x:x,world_y:0,x,y:0,shield_hp:0,hit_points:120,max_hit_points:120,definition:{name:'VESTRAL'},relocating:false});
const lancer=()=>({enemy_definition:catalog.lancer,world_x:0,world_y:0,x:0,y:0,laser_state:'walking',laser_clock:0,laser_target:null,lock_left:0});
function aim(e){assert.equal(api.tick(e,.05),0);assert.equal(e.laser_state,'aiming');}
function fire(e){for(let i=0;i<24;i++)api.tick(e,.05);assert.equal(e.laser_state,'firing');}
let t=tower(),e=lancer();h.towers=[t];aim(e);assert.equal(t.hit_points,120,'Warning causes no damage');
h.obj_game.paused=true;const clock=e.laser_clock;api.tick(e,4);assert.equal(e.laser_clock,clock);
assert.equal(api.damage(t,24),false);h.obj_game.paused=false;
fire(e);assert.equal(t.hit_points,96,'Laser deals exactly 24 damage');
for(let i=0;i<5;i++)api.tick(e,.05);
assert.equal(t.hit_points,96,'Beam only deals damage once');assert.equal(e.laser_state,'walking');
assert.equal(api.tick(e,.05),.05,'Walking resumes during cooldown');
e.laser_clock=0;aim(e);t.world_x=3;fire(e);assert.equal(t.hit_points,96,'Moving off the marked location dodges');
e=lancer();t.world_x=1;aim(e);e.lock_left=.8;api.tick(e,.05);
assert.equal(e.laser_state,'walking');assert.equal(t.hit_points,96,'Lock interrupts aiming');
e=lancer();aim(e);t.destroyed=true;api.tick(e,.05);assert.equal(e.laser_state,'walking','Lost target cancels safely');
h.towers=[tower(20)];e=lancer();assert.equal(api.tick(e,.05),.05,'No target in range keeps walking');
h.towers=[tower(3),tower(1)];assert.equal(api.target(e),h.towers[1],'Nearest valid tower is targeted');
// Destruction clears selection/hover and only cancels the victim's preview.
t=h.towers[1];t.hit_points=24;t.relocating=true;
const preview={moving_tower:t};h.obj_placement=preview;h.obj_game.selected_tower=t;h.obj_input.hovered_tower=t;
api.damage(t,24);assert.ok(t.destroyed);assert.ok(preview.destroyed);assert.equal(t.relocating,false);
assert.equal(h.obj_game.selected_tower,null);assert.equal(h.obj_input.hovered_tower,null);
const other=tower();h.obj_placement={moving_tower:other};api.damage(h.towers[0],999);
assert.equal(h.obj_placement.destroyed,undefined,'Another relocation preview survives');
assert.ok(h.effects.some(f=>f.popup_text==='-24'),'Damage text is emitted');
// Step integration: spawn, stationary aim, pause, debuff expiry, moving again.
e={...lancer(),id:null,elapsed:0,spawn_left:.1,hit_flash:0,lock_visual:0,display_hit_points:140,hit_points:140,
 progress:0,drift_phase:0,shock_left:0,shock_stacks:0,shock_slow:0};e.id=e;
h.towers=[tower()];h.obj_placement=null;
const step=new Function('h','e',`with(h){with(e){${read('objects/obj_enemy/Step_0.gml')}}}`);
step(h,e);step(h,e);assert.equal(e.progress,0);assert.equal(e.laser_state,'walking');
step(h,e);assert.equal(e.laser_state,'aiming');const start=e.progress;
e.shock_left=.1;e.shock_stacks=2;e.shock_slow=.1;step(h,e);step(h,e);
assert.equal(e.shock_left,0);assert.equal(e.progress,start,'Debuffs expire during stationary aim');
h.obj_game.paused=true;const before={clock:e.laser_clock,elapsed:e.elapsed};step(h,e);
assert.deepEqual({clock:e.laser_clock,elapsed:e.elapsed},before);h.obj_game.paused=false;
for(let i=0;i<40;i++)step(h,e);
assert.ok(e.progress>start,'Route travel resumes after firing');assert.equal(h.towers[0].hit_points,96);
assert.ok(new Function('s',`with(s){${read('scripts/scr_encounters/scr_encounters.gml')};return encounter_build_round(1);}`)(h)[2].enemies.includes('lancer'));
console.log('PASS: laser warning, one-hit damage, pause, dodge, Lock interrupt, lost/absent targets, cooldown walking, tower destruction cleanup and wave integration.');
