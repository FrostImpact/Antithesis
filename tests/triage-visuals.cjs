const fs=require('fs'),assert=require('node:assert/strict');
const {createTriagePreview}=require('./triage-preview-host.cjs');
const ctx=new Proxy({},{get:(o,k)=>k in o?o[k]:(()=>{}),set:(o,k,v)=>(o[k]=v,true)});
const source=['scr_defender','scr_effects'].map(n=>fs.readFileSync(`scripts/${n}/${n}.gml`,'utf8')).join('\n').replace(/\bmod\b/g,'%');
const preview=createTriagePreview(ctx,source);
for(const scale of [.72,1,1.28,4])for(const angle of [0,90,180,270,320])for(const time of [0,.08,2.1,4.01,5.8,6.51,7,8.1,10.4,11.2,13.8]) {
 preview.frame(time,angle,scale);
 assert.equal(preview.getAlpha(),1,'All effect paths restore alpha');
}
for(const style of ['release','kit','land','expire','heal','shield','protect','absorb','break','mark','consume','dart','kill']) {
 for(const t of [0,.01,.3,.79,1.2]) {preview.effect(style,t);assert.equal(preview.getAlpha(),1);}
}
const pose=preview.api.pose;
assert.notDeepEqual(pose(1,0,0,0).hand,pose(1,0,1,0).hand,'Aiming raises the applicator');
assert.notDeepEqual(pose(1,0,1,0).hand,pose(1,11,1,0).hand,'Recoil moves the weapon hand');
assert.notDeepEqual(pose(1,0,1,0).support,pose(1,0,1,1).support,'Sanctuary raises the free palm');
for(const angle of [0,90,180,270,320])for(const kick of [0,11])for(const charge of [0,.5,1])assert.ok(preview.api.muzzle(0,0,angle,1,kick,1,charge,0,1).every(Number.isFinite));
// Actual effect Create/Step/Draw events: no generic particles, pause and cleanup.
const read=p=>fs.readFileSync(p,'utf8').replace(/\bmod\b/g,'%').replace(/\bexit;/g,'return;');
const run=p=>new Function('h',`with(h){${read(p)}}`);
const e={id:null,effect_kind:'triage',burst:false,fx_style:'release',fx_owner:null,fx_radius:2.8,world_x:0,world_y:0,
 age:0,lifetime:0,particles:[],obj_game:{paused:true},delta_time:50000,min:Math.min,array_length:a=>a.length,
 variable_instance_exists:()=>true,instance_destroy:()=>e.destroyed=true,triage_draw_event:preview.api.event};e.id=e;
run('objects/obj_impact/Create_0.gml')(e);assert.equal(e.lifetime,1.1);assert.deepEqual(e.particles,[]);
run('objects/obj_impact/Step_0.gml')(e);assert.equal(e.age,0);
e.obj_game.paused=false;run('objects/obj_impact/Step_0.gml')(e);assert.equal(e.age,.05);
run('objects/obj_impact/Draw_0.gml')(e);
for(let i=0;i<24;i++)run('objects/obj_impact/Step_0.gml')(e);assert.ok(e.destroyed);
// Repeated rendering at paused game time produces the exact same geometry.
const frames=[];let points=[];ctx.moveTo=(x,y)=>points.push([x,y]);ctx.lineTo=(x,y)=>points.push([x,y]);
for(let i=0;i<2;i++){points=[];preview.frame(5.8);frames.push(points);}
assert.deepEqual(frames[0],frames[1]);
console.log('PASS: TRIAGE poses/muzzle, all effect styles, five facings/four scales, deterministic pause, restored alpha and effect event lifetime.');

for(const zoom of [.72,1,1.28,4])for(const angle of [0,90,180,270,320])for(const aim of [0,.5,1])for(const kick of [0,11]) {
 preview.api.defender(0,0,angle,1,kick,aim,0,0,zoom);
 assert.ok(preview.api.defenderMuzzle(0,0,angle,1,kick,aim,0,0,zoom).every(Number.isFinite));
}
const recipient={world_x:2,world_y:1,y:500};
const arc={age:0,lifetime:.85,world_x:-2,world_y:0,source_height:6,target_x:2,target_y:1,fx_owner:recipient};
for(const age of [0,.1,.3,.6,.84,.85])for(const destroyed of [false,true]) {
 arc.age=age;recipient.destroyed=destroyed;preview.api.arc(arc);assert.equal(preview.getAlpha(),1);
}
console.log('PASS: VESTRAL idle/aim/recoil geometry, muzzle projection, and healing arcs with moving or removed recipients.');
