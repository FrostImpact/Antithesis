const fs=require('fs'),assert=require('node:assert/strict');
const h={obj_game:{paused:false},obj_tower:'tower',obj_enemy:'enemy',obj_impact:'impact',obj_placement:null,obj_input:{hovered_tower:null},noone:null,
 TowerChargeState:{Ready:0,Charging:1},towers:[],enemies:[],min:Math.min,max:Math.max,string:String,string_format:(n,w,d)=>n.toFixed(d),
 array_length:a=>a.length,array_push:(a,v)=>a.push(v),point_distance:(x,y,a,b)=>Math.hypot(x-a,y-b),
 instance_exists:o=>!!o&&!o.destroyed,instance_number:o=>(o==='tower'?h.towers:h.enemies).length,
 instance_find:(o,i)=>(o==='tower'?h.towers:h.enemies)[i],instance_destroy:o=>o.destroyed=true,instance_create_depth:()=>{},
 game_select_tower:()=>{},loadout_notice:()=>{}};
const src=fs.readFileSync('scripts/scr_combat/scr_combat.gml','utf8').replace(/\bmod\b/g,'%');
const a=new Function('h',`with(h){${src};return {damage:tower_take_damage,finish:triage_resuscitate,tick:triage_tick_support,heal:tower_heal};}`)(h);
const tower=(x,key='vestral')=>({world_x:x,world_y:0,x,y:0,definition:{key,name:key,kit_radius:1.5},max_hit_points:100,hit_points:100,shield_hp:0,charge_mode:0,kit_left:0});
const medic=tower(0,'triage'),ally=tower(1),far=tower(10);Object.assign(medic,{attack_range:2.8,charge_mode:1,damage:24});h.towers=[medic,ally,far];
a.damage(ally,1000);assert.equal(ally.hit_points,1);a.damage(medic,1000);assert.equal(medic.hit_points,1);
h.enemies=[{world_x:1,world_y:0,tourniquet_heal:19.2},{world_x:8,world_y:0,tourniquet_heal:19.2}];
a.finish(medic);medic.charge_mode=0;
assert.deepEqual(h.towers.map(t=>t.shield_hp),[30,30,30]);assert.equal(h.enemies[0].tourniquet_heal,0);assert.equal(h.enemies[1].tourniquet_heal,19.2);
a.damage(ally,20);assert.equal(ally.hit_points,1);assert.equal(ally.shield_hp,10);
a.tick(1);assert.equal(ally.shield_hp,0);assert.equal(far.shield_hp,20);a.tick(2);assert.equal(far.shield_hp,0);
Object.assign(medic,{kit_x:0,kit_y:0,kit_left:12,kit_healed:[]});
a.tick(.05);assert.ok(Math.abs(ally.hit_points-29.8)<1e-9);a.tick(.05);assert.ok(Math.abs(ally.hit_points-29.8)<1e-9);
far.world_x=1;far.hit_points=50;a.tick(.05);assert.ok(Math.abs(far.hit_points-78.8)<1e-9);
medic.kit_healed=[];medic.kit_left=12;a.tick(.05);assert.ok(Math.abs(ally.hit_points-58.6)<1e-9);
a.tick(12);assert.equal(medic.kit_left,0);
a.heal(ally,1000);assert.equal(ally.hit_points,100);
console.log('PASS: Sanctuary floor including self, global shield, local Tourniquet consumption, shield absorption/decay, kit entry/replacement/expiry and heal cap.');

h.obj_game.paused=true;far.shield_hp=30;medic.kit_left=12;a.tick(5);assert.equal(far.shield_hp,30);assert.equal(medic.kit_left,12);
const {createHost}=require('./loadout.cjs');
const loadout=createHost();
assert.equal(loadout.api.use(4),true);loadout.api.tick(1);
assert.equal(loadout.h.obj_game.loadout.keys[0],'triage');
assert.equal(loadout.api.select(0),true);
const deployed=loadout.api.place(2,2);
assert.equal(deployed.definition.key,'triage');assert.equal(loadout.h.obj_game.loadout.bits,100);
console.log('PASS: TRIAGE starter card redemption, tray selection and 100-Bit deployment.');
