const fs=require('fs'),assert=require('node:assert/strict');
const read=p=>fs.readFileSync(p,'utf8').replace(/\bmod\b/g,'%');
let colour,alpha,rects=[];
const h={stun_left:0,id:null,x:100,y:150,definition:{key:'triage'},aim_blend:0,relocating:false,move_active:false,
 obj_camera:{zoom:1},charge_mode:0,charge_lockout:0,charge_ready_blend:1,charge_reuse_delay:10,
 TowerChargeState:{Ready:0},max_hit_points:100,display_hit_points:100,shield_hp:0,
 clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),max:Math.max,lerp:(a,b,t)=>a+(b-a)*t,
 make_colour_rgb:(...v)=>v,merge_colour:(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t),
 tower_draw_attack_fx(){},tower_draw_charge_fx(){},triage_draw_shield(){},tower_charge_progress:()=>.5,tower_visual_y:t=>t.y,
 draw_set_colour:c=>colour=c,draw_set_alpha:a=>alpha=a,
 draw_rectangle:(...r)=>{assert.ok(r.slice(0,4).every(Number.isFinite));rects.push({colour,r});}};h.id=h;
h.ui_health_colour=new Function('h',`with(h){${read('scripts/scr_interface/scr_interface.gml')};return ui_health_colour;}`)(h);
const draw=new Function('h',`with(h){${read('objects/obj_tower/Draw_73.gml')}}`);
const find=c=>rects.find(r=>JSON.stringify(r.colour)===JSON.stringify(c));
for(const zoom of [.72,1,1.28])for(const hp of [20,100])for(const shield of [0,30,150]) {
 Object.assign(h,{hit_points:hp,display_hit_points:hp,shield_hp:shield});h.obj_camera.zoom=zoom;rects=[];draw(h);
 const health=find(h.ui_health_colour(hp/100)),charge=find([179,161,112]),blue=find([91,162,218]);
 assert.ok(charge.r[3]<health.r[1],'Charge sits above HP');
 const width=36*h.clamp(zoom,.85,1.2);
 assert.ok(Math.abs((health.r[2]-health.r[0])-width*hp/(100+shield))<1e-9);
 if(shield){assert.equal(blue.r[0],health.r[2]);assert.equal(blue.r[1],health.r[1]);assert.equal(blue.r[3],health.r[3]);assert.ok(blue.r[2]<=100+width/2+1e-9);}else assert.equal(blue,undefined);
 assert.equal(alpha,1);
}
h.obj_camera.zoom=1;rects=[];draw(h);const oldTop=rects[0].r[1];h.y-=25;rects=[];draw(h);assert.equal(rects[0].r[1],oldTop-25,'Bars follow the visual position during movement');
console.log('PASS: charge above health, proportional blue shield HP, bounded fills, zoom scaling, movement anchoring and restored alpha.');

Object.assign(h,{hit_points:40,display_hit_points:100,shield_hp:30});rects=[];draw(h);
const live=find(h.ui_health_colour(.4)),trail=find([133,143,142]),shield=find([91,162,218]);
assert.ok(live.r[2]<trail.r[2]);assert.equal(shield.r[0],live.r[2]);assert.ok(shield.r[2]<trail.r[2]);
assert.ok(rects.indexOf(trail)<rects.indexOf(live),'Gray trail draws behind live HP');
console.log('PASS: live HP drops ahead of gray damage trail while shields remain appended to live HP.');
