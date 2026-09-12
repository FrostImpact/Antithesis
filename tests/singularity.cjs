const fs=require('fs'),assert=require('node:assert/strict');
const read=p=>fs.readFileSync(p,'utf8').replace(/\bmod\b/g,'%');
const {createHost}=require('./loadout.cjs');const catalog=createHost().h.obj_game.tower_catalog;
function make(summon=false){
 const h={obj_game:{paused:false},obj_tower:'tower',obj_enemy:'enemy',obj_impact:'impact',obj_placement:null,noone:null,
  towers:[],enemies:[],effects:[],rewards:0,delta_time:50000,
  min:Math.min,max:Math.max,abs:Math.abs,floor:Math.floor,ceil:Math.ceil,exp:Math.exp,sin:Math.sin,pi:Math.PI,power:Math.pow,
  dcos:a=>Math.cos(a*Math.PI/180),dsin:a=>Math.sin(a*Math.PI/180),array_create:(n,v)=>Array(n).fill(v),array_length:a=>a.length,array_push:(a,v)=>a.push(v),
  clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),lerp:(a,b,t)=>a+(b-a)*t,string:String,string_format:(n,w,d)=>n.toFixed(d),
  point_distance:(x,y,a,b)=>Math.hypot(a-x,b-y),project_x:(x,y)=>x,project_y:(x,y)=>y,
  instance_exists:o=>!!o&&!o.destroyed,instance_number:o=>(o==='enemy'?h.enemies:h.towers).filter(e=>!e.destroyed).length,
  instance_find:(o,i)=>(o==='enemy'?h.enemies:h.towers).filter(e=>!e.destroyed)[i],instance_destroy:o=>o.destroyed=true,
  instance_create_depth:(x,y,d,o,data)=>h.effects.push(data),loadout_award_kill:()=>h.rewards++,
  TowerChargeState:{Ready:0,Charging:1,Burst:2,Recovery:3},TowerTargetMode:{First:0,Strongest:1,Nearest:2},
  tower_definition:()=>catalog.singularity};
 const s={tower_type:'singularity',world_x:0,world_y:0,x:0,y:0,id:null};s.id=s;
 const code=read('scripts/scr_combat/scr_combat.gml');
 const init=code.slice(code.indexOf('function tower_initialize'),code.indexOf('function tower_tick()'));
 for(const m of init.matchAll(/^([a-z_]+)=/gm))s[m[1]]=undefined;
 for(const key of ['move_from_y','move_target_y','beam_world_y','selection_amount','select_pulse','reject_pulse','damage_dealt','shots_fired'])s[key]=0;
 const a=new Function('h','s',`with(h){with(s){${code};return {init:tower_initialize,tick:tower_tick,charge:tower_request_charge,canCharge:tower_can_charge,move:tower_request_move,stun:tower_apply_stun,pulse:singularity_pulse,orbit:singularity_tick_orbit,add:singularity_add_debris,hit:singularity_damage};}}`)(h,s);
 a.init();s.settle=0;if(!summon)s.summon_left=0;h.towers=[s];return {h,s,a};
}
const enemy=(x=1,y=0,hp=1000)=>({world_x:x,world_y:y,x,y,spawn_left:0,hit_points:hp,max_hit_points:hp,progress:1,tourniquet_heal:0});
let {h,s,a}=make();h.enemies=[enemy(),enemy(-1),enemy(4),{...enemy(),spawn_left:1}];
a.tick();assert.equal(s.pulse_left,1.6);assert.equal(s.shots_fired,0);
for(let i=0;i<31;i++)a.tick();assert.equal(s.shots_fired,0);a.tick();
assert.equal(s.shots_fired,1);assert.deepEqual(h.enemies.map(e=>e.hit_points),[976,976,1000,1000]);assert.equal(s.cooldown,1.1);
s.attack_interval=.2;s.cooldown=0;a.tick();assert.equal(s.pulse_left,1.6,'Attack speed does not shorten windup');
for(let i=0;i<32;i++)a.tick();assert.equal(s.cooldown,.2);assert.equal(s.shots_fired,2);
s.density=2;s.cooldown=0;a.tick();assert.equal(s.pulse_left,0);assert.equal(s.density,1);assert.equal(s.shots_fired,3);a.tick();assert.equal(s.shots_fired,3);
// No target does not waste Density. Windup can finish into an empty lane.
h.enemies=[];s.cooldown=0;a.tick();assert.equal(s.density,1);
({h,s,a}=make());h.enemies=[enemy(1,0,1),enemy(-1,0,1),enemy(0,1,1)];a.pulse(s);
assert.equal(s.kills,3);assert.equal(h.rewards,3);assert.equal(s.debris.length,3);
for(let i=0;i<6;i++)a.add(s);assert.equal(s.debris.length,6);assert.equal(new Set(s.debris.map(p=>p.serial)).size,6);
const last=s.debris.at(-1);a.orbit(s,1);a.add(s);assert.ok(s.debris.includes(last));assert.equal(s.debris.at(-1).left,5);assert.equal(last.left,4);
a.orbit(s,4);assert.equal(s.debris.length,1);a.orbit(s,1);assert.equal(s.debris.length,0);
// Collision follows each orbit, not the entire area around the tower.
({h,s,a}=make());a.add(s);s.debris[0].angle=0;
h.enemies=[enemy(1.65,.05),enemy(0,0),enemy(-1.65,0),enemy(1.65,.05)];
a.orbit(s,.05);assert.equal(h.enemies[0].hit_points,998.56);assert.equal(h.enemies[3].hit_points,998.56);assert.equal(h.enemies[1].hit_points,1000);assert.equal(h.enemies[2].hit_points,1000);
a.orbit(s,.05);assert.equal(h.enemies[0].hit_points,998.56,'Contact cooldown is per fragment and enemy');
// Swept path catches a crossing even when neither endpoint touches the enemy.
s.debris[0].angle=0;s.debris[0].contacts=[];h.enemies=[enemy(1.65*Math.cos(.48),1.65*Math.sin(.48))];
a.orbit(s,.5);assert.ok(h.enemies[0].hit_points<1000);
// Orbital kills produce debris safely and share Tourniquet healing/rewards.
({h,s,a}=make());a.add(s);s.debris[0].angle=0;s.hit_points=100;h.enemies=[{...enemy(1.65,.05,1),tourniquet_heal:19.2}];a.orbit(s,.05);
assert.equal(s.debris.length,2);assert.equal(s.kills,1);assert.ok(Math.abs(s.hit_points-119.2)<1e-9);
// Event Horizon reserves fragments on acceptance; short-lived stacks survive as pending Density.
({h,s,a}=make());a.add(s);a.add(s);s.debris[0].left=.3;s.density=2;
assert.equal(a.charge(s),true);h.obj_game.paused=true;a.tick();assert.equal(s.charge_left,2);assert.equal(s.debris.length,0);assert.equal(s.pending_density,2);assert.equal(s.density,2);h.obj_game.paused=false;
for(let i=0;i<40;i++)a.tick();assert.equal(s.charge_mode,0);assert.equal(s.debris.length,0);assert.equal(s.density,4);assert.equal(s.pending_density,0);assert.equal(s.charge_lockout,8);
// Stun amplification, longer-refresh semantics, paused casts/movement and no input.
({h,s,a}=make());h.enemies=[enemy()];a.tick();const before=s.pulse_left;a.add(s);
assert.equal(a.stun(s,1),true);assert.equal(s.stun_left,1.5);a.stun(s,.2);assert.equal(s.stun_left,1.5);assert.equal(a.canCharge(s),false);
for(let i=0;i<20;i++)a.tick();assert.equal(s.pulse_left,before);assert.ok(s.debris[0].left<4.01);
const regular={definition:catalog.vestral,stun_left:0};a.stun(regular,1);assert.equal(regular.stun_left,1);
s.move_active=true;s.move_elapsed=0;s.stun_left=.5;a.tick();assert.equal(s.move_elapsed,0);
const loadout=createHost();assert.equal(loadout.api.use(5),true);loadout.api.tick(1);loadout.api.select(0);assert.equal(loadout.api.place(2,2).definition.key,'singularity');assert.equal(loadout.h.obj_game.loadout.bits,60);
console.log('PASS: SINGULARITY AoE, fixed windup/rate scaling, Density cadence, six-fragment cap/expiry, swept contact ticks/kills, Tourniquet healing, conversion/pause/stuns and card deployment.');
// Debris sweeps the translation between frames as its owner relocates.
({h,s,a}=make());a.add(s);s.debris[0].angle=0;s.world_x=3;h.enemies=[enemy(3,0)];a.orbit(s,.05);assert.ok(h.enemies[0].hit_points<1000);
// Expiry removes orbital hitboxes; another tower keeps independent fragments.
({h,s,a}=make());a.add(s);const separate=make();separate.a.add(separate.s);s.debris[0].left=.01;a.orbit(s,.05);assert.equal(s.debris.length,0);assert.equal(separate.s.debris.length,1);

// Summoning freezes offense and movement until the full portal emergence completes.
({h,s,a}=make(true));h.enemies=[enemy()];assert.equal(s.summon_left,1.6);assert.equal(a.canCharge(s),false);assert.equal(a.move(s),false);
h.obj_game.paused=true;a.tick();assert.equal(s.summon_left,1.6);h.obj_game.paused=false;
for(let i=0;i<31;i++)a.tick();assert.ok(s.summon_left>0);assert.equal(s.shots_fired,0);assert.equal(s.pulse_left,0);a.tick();assert.equal(s.summon_left,0);a.tick();assert.equal(s.pulse_left,1.6);
for(let i=0;i<31;i++)a.tick();assert.equal(s.shots_fired,0);a.tick();assert.equal(s.shots_fired,1);assert.equal(h.enemies[0].hit_points,976);assert.ok(s.pulse_fx>0);assert.equal(a.move(s),false);
console.log('PASS: 24 ATK, full 1.6s summon and windup, pause/input guards and impact-aligned damage.');
// Accepted charging consumes fragments once; new fragments are not swept up later.
({h,s,a}=make());a.add(s);a.add(s);s.debris[0].angle=0;h.enemies=[enemy(1.65,0)];
assert.equal(a.charge(s),true);assert.equal(s.debris.length,0);assert.equal(s.pending_density,2);
assert.equal(a.charge(s),false);assert.equal(s.pending_density,2);
for(let i=0;i<10;i++)a.tick();assert.equal(h.enemies[0].hit_points,1000,'Consumed orbit hitboxes are gone immediately');
a.add(s);const newPiece=s.debris[0];h.enemies=[];
for(let i=0;i<30;i++)a.tick();assert.equal(s.density,2);assert.equal(s.pending_density,0);assert.ok(s.debris.includes(newPiece));
({h,s,a}=make());a.add(s);s.charge_lockout=1;assert.equal(a.charge(s),false);assert.equal(s.debris.length,1);assert.equal(s.pending_density,0);
console.log('PASS: charge-start consumption, guarded double-use, immediate hitbox removal and preservation of new fragments.');
