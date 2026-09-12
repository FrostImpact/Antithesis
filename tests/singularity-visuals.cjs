const fs=require('fs'),assert=require('node:assert/strict');const {createSingularityPreview}=require('./singularity-preview-host.cjs');
const source=['scr_defender','scr_effects'].map(n=>fs.readFileSync(`scripts/${n}/${n}.gml`,'utf8')).join('\n').replace(/\bmod\b/g,'%');
const ctx=new Proxy({},{get:(o,k)=>k in o?o[k]:(()=>{}),set:(o,k,v)=>(o[k]=v,true)}),p=createSingularityPreview(ctx,source);
for(const zoom of [.72,1,1.28,4])for(const angle of [0,90,180,270,320])for(const t of [0,.5,.91,1.2,3.01,4.9,5.01,6.3,9.5])assert.equal(p.frame(t,angle,zoom),1);
for(const style of ['pulse','horizon','hit','debris'])for(const age of [0,.05,.3,1])p.effect(style,age);
console.log('PASS: SINGULARITY mesh, six-fragment orbit, charge/pulse/Density effects at five facings and four scales; finite geometry and restored draw state.');
// The carry-and-slam pose reaches overhead, contacts the ground, then recovers.
const pose=p.api.pose;
assert.ok(pose(1,.8,0,0,0).right[2]>115);
assert.ok(pose(1,1,0,0,0).right[2]<0);
assert.ok(pose(1,1,0,0,0).right.every((v,i)=>Math.abs(v-pose(1,0,1,0,0).right[i])<1e-9),'Impact starts where the slam ends');
assert.ok(pose(1,0,.05,0,0).right[2]>pose(1,0,1,0,0).right[2]);
assert.ok(pose(1,0,0,.5,0).left[2]>65,'Event Horizon raises both hands');
// Emergence clips polygons at the physical ground plane.
for(const offset of [0,40,100,145]) {
 const points=p.api.clip([[-5,0,-20],[5,0,30],[0,5,120]],offset);
 assert.ok(points.every(v=>v[2]>=-16));
 if(offset===145)assert.equal(points.length,0);
}
let vertices=0;const prior=p.h.draw_vertex;p.h.draw_vertex=(x,y)=>{vertices++;prior(x,y);};
p.api.model(0,0,320,0,0,0,0,0,1,0,0,0,0);assert.equal(vertices,0,'Model begins completely underground');
p.api.model(0,0,320,0,0,0,0,0,1,0,0,.55,0);const partial=vertices;assert.ok(partial>0);
vertices=0;p.api.model(0,0,320,0,0,0,0,0,1,0,0,1,0);assert.ok(vertices>partial);
console.log('PASS: overhead carry, ground-contact continuity, recovery, distinct skill pose and true ground-clipped emergence.');
// Each state boundary shares the same idle/held joint targets.
const closePose=(a,b)=>{
 for(const key of ['bob','weight','ritual'])assert.ok(Math.abs(a[key]-b[key])<1e-5,key);
 for(const key of ['right','left','right_elbow','left_elbow'])assert.ok(a[key].every((v,i)=>Math.abs(v-b[key][i])<1e-5),key);
};
for(const clock of [0,.7,2.3,5]) {
 const idle=pose(clock,0,0,0,0);
 closePose(pose(clock,0,0,1,0),pose(clock,0,0,0,1));
 closePose(pose(clock,0,0,.000001,0),idle);
 closePose(pose(clock,0,0,0,.000001),idle);
 closePose(pose(clock,0,.000001,0,0),idle);
 closePose(pose(clock,1,0,0,0),pose(clock,0,1,0,0));
}
console.log('PASS: full joint/body continuity at charge start, charge-to-release, slam-to-recovery and return-to-idle boundaries.');
