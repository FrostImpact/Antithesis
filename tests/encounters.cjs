const fs=require('node:fs');
const assert=require('node:assert/strict');
const read=p=>fs.readFileSync(p,'utf8');
const translate=s=>s.replace(/\bmod\b/g,'%');
const catalog=new Function(read('scripts/scr_definitions/scr_definitions.gml')+';return build_enemy_catalog();')();
const code=translate(read('scripts/scr_encounters/scr_encounters.gml'));
const state={obj_game:{paused:false,encounter_settings:{wave_break:4}},obj_tower:'tower',obj_enemy:'enemy',
    rewards:[],loadout_round_reward:r=>state.rewards.push(r),
    array_push:(a,v)=>a.push(v),array_length:a=>a.length,min:Math.min,max:Math.max,
    hasTower:false,enemies:[],spawns:[],
    instance_exists:e=>e==='tower'?state.hasTower:e==='enemy'?state.enemies.length>0:!!e,
    instance_create_depth:(x,y,z,o,data)=>{assert.ok(catalog[data.enemy_type]);state.enemies.push(data);state.spawns.push(data);}};
for(const m of code.slice(0,code.indexOf('function encounter_build_round')).matchAll(/^\s+([a-z_]+)=/gm))state[m[1]]=undefined;
state.obj_encounter=state;
const api=new Function('s',`with(s){${code};return {init:encounter_initialize,start:encounter_start_round,tick:encounter_tick,build:encounter_build_round,escape:encounter_record_escape};}`)(state);
api.init();assert.equal(api.start(),false,'Must place a tower before starting');
state.hasTower=true;state.obj_game.paused=true;assert.equal(api.start(),false);
state.obj_game.paused=false;assert.equal(api.start(),true);assert.equal(api.start(),false,'No double-start');
assert.equal(state.round_total,21);
api.tick(0.01);assert.equal(state.spawns.length,1);
state.enemies=[];api.tick(0.01);assert.equal(state.phase,'wave','Empty lane must not finish a partially spawned wave');
state.obj_game.paused=true;const before=state.spawn_left;api.tick(10);assert.equal(state.spawn_left,before);state.obj_game.paused=false;
for(let i=0;i<200;i++)api.tick(0.05);
assert.equal(state.spawns.length,5);assert.equal(state.phase,'wave','Living enemies keep the wave active');
state.enemies=[];api.escape();api.tick(0.01);assert.equal(state.phase,'wave_break');
state.obj_game.paused=true;api.tick(10);assert.equal(state.break_left,4);state.obj_game.paused=false;
api.tick(3.9);assert.equal(state.wave_index,0);api.tick(0.11);assert.equal(state.wave_index,1);
for(let i=0;i<1000 && state.phase!=='intermission';i++){state.enemies=[];api.tick(0.05);}
assert.equal(state.phase,'intermission');assert.equal(state.spawns.length,21);
assert.deepEqual(state.rewards,[1],'A cleared round grants one stored-card reward');
assert.ok(state.spawns.some(e=>e.enemy_type==='fast'));assert.ok(state.spawns.some(e=>e.enemy_type==='heavy'));
assert.equal(state.round_escaped,1);assert.equal(state.total_escaped,1);
api.tick(100);assert.equal(state.spawns.length,21,'Intermission waits for the player');
assert.deepEqual(state.rewards,[1],'Intermission never repeats its reward');
api.start();assert.equal(state.round_number,2);assert.equal(state.round_escaped,0);assert.equal(state.total_escaped,1);
assert.ok(state.round_total>21);assert.ok(state.waves[0].health_scale>1);
const late=api.build(100);assert.ok(late.every(w=>w.enemies.length<=24 && w.interval>=0.45));
assert.ok(catalog.fast.move_speed>catalog.intrusion.move_speed && catalog.intrusion.move_speed>catalog.heavy.move_speed);
assert.deepEqual([catalog.fast.move_speed,catalog.intrusion.move_speed,catalog.heavy.move_speed],[0.95,0.56,0.28],
    'Every Blank variant keeps the requested 30% movement reduction');
console.log('PASS: start guards, all three wave compositions, staggered spawns, clear detection, pause, breaks, escapes, intermission and round scaling.');

// Execute production movement with a root and a slow, checking the drift clock.
const movementCode=translate(read('objects/obj_enemy/Step_0.gml')).replace(/\bexit;/g,'return;');
const move=new Function('s',`with(s){${movementCode}}`);
const actor={obj_game:{paused:false},obj_world:{route:[[0,0],[1,0],[1,1]]},
    delta_time:50000,elapsed:0,spawn_left:0,hit_flash:0,lock_visual:0,lock_left:0,display_hit_points:100,hit_points:100,
    progress:0,world_x:0,world_y:0,x:0,y:0,depth:0,drift_phase:0,facing:0,enemy_definition:catalog.intrusion,
    min:Math.min,max:Math.max,exp:Math.exp,floor:Math.floor,pi:Math.PI,arctan2:Math.atan2,
    array_length:a=>a.length,lerp:(a,b,t)=>a+(b-a)*t,point_distance:(x,y,a,b)=>Math.hypot(a-x,b-y),
    angle_difference:(a,b)=>(a-b+540)%360-180,project_x:x=>x,project_y:(x,y)=>y,
    enemy_movement_time:(e,dt)=>dt*actor.movementFactor,movementFactor:1,
    encounter_record_escape:()=>actor.escapes++,instance_destroy:()=>actor.destroyed=true,escapes:0};
actor.id=actor;move(actor);const normalPhase=actor.drift_phase;
actor.movementFactor=0;move(actor);assert.equal(actor.drift_phase,normalPhase,'Root freezes the drift');
actor.movementFactor=0.5;move(actor);assert.ok(Math.abs(actor.drift_phase-normalPhase*1.5)<1e-9,'Slow scales drift');
actor.obj_game.paused=true;const pausedPhase=actor.drift_phase;move(actor);assert.equal(actor.drift_phase,pausedPhase);
actor.obj_game.paused=false;actor.movementFactor=1;
for(let i=0;i<100&&!actor.destroyed;i++)move(actor);
assert.equal(actor.escapes,1);assert.equal(actor.destroyed,true);assert.ok(actor.world_y>0,'Movement follows a path corner');
console.log('PASS: fragment drift, root, slow, pause, route turns and escape recording.');

// Use real debuff integration and the real Step event to measure route distance.
actor.enemy_movement_time=new Function('s',`with(s){${translate(read('scripts/scr_combat/scr_combat.gml'))};return enemy_movement_time;}`)(actor);
function travel(stacks,duration,lock,frames){
 Object.assign(actor,{progress:0,drift_phase:0,elapsed:0,spawn_left:0,shock_stacks:stacks,
   shock_slow:stacks*.05,shock_left:duration,lock_left:lock,destroyed:false});
 for(let i=0;i<frames;i++)move(actor);
 return actor.progress;
}
const baseSpeed=catalog.intrusion.move_speed;
assert.ok(Math.abs(travel(0,0,0,8)-baseSpeed*.4)<1e-9);
assert.ok(Math.abs(travel(2,.4,0,8)-baseSpeed*.4*.9)<1e-9,'Two Vestral bolts reduce actual route travel by 10%');
assert.ok(Math.abs(travel(8,.4,0,8)-baseSpeed*.4*.6)<1e-9,'Eight stacks reduce actual route travel by 40%');
assert.equal(actor.shock_stacks,0,'Expired slows clear all stacks');
assert.ok(Math.abs(travel(8,.025,0,1)-baseSpeed*(.025*.6+.025))<1e-9,'Mid-frame expiry only slows the affected time');
assert.ok(Math.abs(travel(8,.05,.02,1)-baseSpeed*.03*.6)<1e-9,'A root ending mid-frame resumes into its active slow');
for(const d of Object.values(catalog)){
 Object.assign(actor,{enemy_definition:d,progress:0,drift_phase:0,spawn_left:d.spawn_duration,shock_left:0,shock_stacks:0,shock_slow:0,lock_left:0});
 actor.obj_game.paused=true;move(actor);assert.equal(actor.spawn_left,d.spawn_duration,'Pause freezes materialization');
 actor.obj_game.paused=false;
 for(let i=0;i<Math.floor(d.spawn_duration/.05)-1;i++)move(actor);
 assert.equal(actor.progress,0,'Enemy stays on its entrance until materialization completes');
 actor.spawn_left=.025;move(actor);
 assert.ok(Math.abs(actor.progress-d.move_speed*.025)<1e-9,'Only the post-spawn portion of the frame moves');
}
console.log('PASS: actual slow travel at 10%/40%, status expiry, root overlap, spawn movement and pause for every enemy type.');
