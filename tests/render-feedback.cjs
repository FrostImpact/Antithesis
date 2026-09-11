// Visual QA of the production draw functions. Requires @napi-rs/canvas.
const fs=require('node:fs'),assert=require('node:assert/strict');
const {createCanvas,loadImage}=require('@napi-rs/canvas');
const read=p=>fs.readFileSync(p,'utf8').replace(/\bmod\b/g,'%');
const cv=createCanvas(1120,780),g=cv.getContext('2d');
let colour='#fff',vertices=[],alpha=1;const sprites={};
const finite=(...v)=>assert.ok(v.every(Number.isFinite));
const h={min:Math.min,max:Math.max,floor:Math.floor,sin:Math.sin,power:Math.pow,pi:Math.PI,sqrt:Math.sqrt,sign:Math.sign,
 clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),lerp:(a,b,t)=>a+(b-a)*t,
 dcos:v=>Math.cos(v*Math.PI/180),dsin:v=>Math.sin(v*Math.PI/180),
 point_direction:(x,y,a,b)=>Math.atan2(y-b,a-x)*180/Math.PI,
 make_colour_rgb:(r,g,b)=>[r,g,b],merge_colour:(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t),c_white:[255,255,255],c_black:[0,0,0],
 array_length:a=>a.length,array_push:(a,v)=>a.push(v),array_sort:(a,f)=>a.sort(f),
 obj_camera:{zoom:2},bm_add:1,bm_normal:0,pr_trianglefan:0,
 draw_set_colour:c=>colour=`rgb(${c.join(',')})`,draw_set_alpha:a=>{finite(a);assert.ok(a>=0&&a<=1);alpha=a;g.globalAlpha=a;},
 gpu_set_blendmode:m=>g.globalCompositeOperation=m?'lighter':'source-over',
 draw_primitive_begin:()=>vertices=[],draw_vertex:(x,y)=>{finite(x,y);vertices.push([x,y]);},
 draw_primitive_end:()=>{g.fillStyle=colour;g.beginPath();vertices.forEach(([x,y],i)=>i?g.lineTo(x,y):g.moveTo(x,y));g.closePath();g.fill();},
 draw_line_width:(x,y,tx,ty,w)=>{finite(x,y,tx,ty,w);g.strokeStyle=colour;g.lineWidth=w;g.beginPath();g.moveTo(x,y);g.lineTo(tx,ty);g.stroke();},
 draw_triangle:(x,y,bx,by,cx,cy)=>{finite(x,y,bx,by,cx,cy);g.fillStyle=colour;g.beginPath();g.moveTo(x,y);g.lineTo(bx,by);g.lineTo(cx,cy);g.closePath();g.fill();},
 draw_ellipse:(x,y,bx,by,outline)=>{finite(x,y,bx,by);g.fillStyle=g.strokeStyle=colour;g.lineWidth=1;g.beginPath();g.ellipse((x+bx)/2,(y+by)/2,(bx-x)/2,(by-y)/2,0,0,Math.PI*2);outline?g.stroke():g.fill();},
 draw_sprite_part_ext:(sprite,frame,sx,sy,w,hh,x,y,scaleX,scaleY,tint,a)=>{finite(sx,sy,w,hh,x,y,scaleX,scaleY,a);g.globalAlpha=a;g.drawImage(sprites[sprite],sx,sy,w,hh,x,y,w*scaleX,hh*scaleY);g.globalAlpha=alpha;},
 fa_left:'left',fa_middle:'middle',fa_top:'top',string:String,
 draw_set_halign:a=>g.textAlign=a,draw_set_valign:v=>g.textBaseline=v,
 draw_text_transformed:(x,y,text,sx,sy)=>{finite(x,y,sx,sy);g.save();g.translate(x,y);g.scale(sx,sy);g.fillStyle=colour;g.font='14px Arial';g.fillText(text,0,0);g.restore();},
 tower_move_progress:t=>t.move_elapsed/t.move_duration,
};
// World primitives and models retain their real transforms. Use screen-space
// anchors for effects in this contact sheet so each sample is independent.
const source=['scr_geometry','scr_defender','scr_effects','scr_blanks','scr_map','scr_definitions'].map(n=>read(`scripts/${n}/${n}.gml`)).join('\n');
Object.assign(h,{GlossaryTerm:{None:-1},TowerAbility:{DoubleTap:0,ShockBolts:1,Overloaded:2}});
const api=new Function('s',`with(s){${source};project_x=x=>x;project_y=(x,y)=>y;return {icon:draw_vigil_icon,shadow:tower_draw_shadow,vestral:draw_defender,wanderer:draw_wanderer,blank:blank_draw_model,spawn:blank_draw_spawn_fx,shock:blank_draw_shock_fx,catalog:build_enemy_catalog(),towers:build_tower_catalog(),platform:map_draw_endpoint_platform};}`)(h);
h.project_x=x=>x;h.project_y=(x,y)=>y;h.draw_vigil_icon=api.icon;
const popupDraw=new Function('s',`with(s){${read('objects/obj_impact/Draw_0.gml').replace(/\bexit;/g,'return;')}}`);
// Compare actual projected endpoint polygons with actual projected path tiles.
let polygons=[],points=[];
const geometryHost={...h,obj_camera:{zoom:1,map_angle:45},
 draw_primitive_begin:()=>points=[],draw_vertex:(x,y)=>points.push([x,y]),
 draw_primitive_end:()=>polygons.push(points),draw_line_width:()=>{},draw_set_alpha:()=>{},draw_set_colour:()=>{}};
const geometry=new Function('s',`with(s){${read('scripts/scr_geometry/scr_geometry.gml')}\n${read('scripts/scr_map/scr_map.gml')};return {tile:draw_ground_tile,platform:map_draw_endpoint_platform};}`)(geometryHost);
for(const zoom of [.72,1,1.28])for(const endpoint of [[1,2],[7,5]]){
 geometryHost.obj_camera.zoom=zoom;
 polygons=[];geometry.tile(...endpoint,[0,0,0]);const tile=polygons[0];
 for(const shield of [false,true]){
  polygons=[];geometry.platform(endpoint,[0,0,0],shield,1);
  assert.deepEqual(polygons[1],tile,'Both endpoint surfaces exactly match the path tile at every zoom');
 }
}
function label(text,x,y){g.globalAlpha=1;g.fillStyle='#c7d2c5';g.font='14px Arial';g.textAlign='left';g.textBaseline='top';g.fillText(text,x,y);}
async function main(){
 for(const name of ['wisp','husk','hulk']){
  const dir=`sprites/spr_blank_${name}`;const meta=JSON.parse(fs.readFileSync(`${dir}/spr_blank_${name}.yy`,'utf8').replace(/,\s*([}\]])/g,'$1'));
  sprites[name]=await loadImage(`${dir}/${meta.frames[0].name}.png`);
 }
 g.fillStyle='#18221f';g.fillRect(0,0,1120,780);
 label('VIGIL / 44px badge and stack reward progression',24,18);
 g.fillStyle='#1b1e22';g.fillRect(26,53,44,44);g.strokeStyle='#9fc163';g.strokeRect(26,53,44,44);
 api.icon(48,67,12);label('12',39,80);
 for(const [i,t] of [0,.15,.4,.7,.92].entries()){
  popupDraw({...h,effect_kind:'vigil',world_x:150+i*135,world_y:248,age:t*.95,lifetime:.95,popup_stacks:3});
 }
 label('SPAWN / ground breach to full shell',24,222);
 const d={...api.catalog.intrusion,atlas:'husk'};
 for(const [i,p] of [0,.2,.45,.7,1].entries()){
  const e={enemy_definition:d,x:140+i*195,y:410,spawn_left:d.spawn_duration*(1-p),drift_phase:1,hit_flash:0};
  api.spawn(e);api.blank(e);
 }
 g.fillStyle='#cdd2cc';g.fillRect(12,480,1096,230);
 label('SLOW / electric arcs on each moving shell',24,442);
 for(const [i,key] of ['fast','intrusion','heavy'].entries()){
  const d=api.catalog[key];const e={enemy_definition:{...d,atlas:d.model},x:130+i*145,y:645,spawn_left:0,drift_phase:1,hit_flash:0,shock_left:.3,shock_stacks:4,elapsed:i*.13};
  api.blank(e);api.shock(e);
 }
 label('SHADOWS / grounded through stance and recoil',560,442);
 h.obj_camera.zoom=2.4;
 for(const [i,key] of ['vestral','wanderer','wanderer'].entries()){
  const tower={world_x:640+i*175,world_y:645,definition:api.towers[key],move_active:false,relocating:false};
  api.shadow(tower);api[key](tower.world_x,tower.world_y,300,2,i===2?15:0,i===2?1:0,0,0,2.4);
 }
 // Verify transient rendering and zoom extremes without increasing artifact size.
 for(const zoom of [.72,1,1.28])for(const t of [0,.3,.65,.95]){
  h.obj_camera.zoom=zoom;
  popupDraw({...h,effect_kind:'vigil',world_x:-100,world_y:-100,age:t,lifetime:.95,popup_stacks:4});
 }
 label('Production geometry and sprite frames; final appearance still needs an in-editor check.',24,738);
 fs.mkdirSync('.build',{recursive:true});fs.writeFileSync('.build/feedback-review.png',cv.toBuffer('image/png'));
 const ellipse=h.draw_ellipse;let shadows=[];h.draw_ellipse=(...v)=>shadows.push(v);
 for(const key of ['vestral','wanderer'])for(const zoom of [.72,1,1.28]){
  h.obj_camera.zoom=zoom;
  const tower={world_x:300,world_y:400,definition:api.towers[key],move_active:false,relocating:false};
  shadows=[];api.shadow(tower);
  const still=shadows;assert.ok(still.length>0);
  tower.settle=1;tower.charge_pose=1;tower.recoil=29;shadows=[];api.shadow(tower);
  assert.deepEqual(shadows,still,'Stance, recoil and settling cannot move the ground shadow');
  assert.equal((still[0][0]+still[0][2])/2,300);assert.equal((still[0][1]+still[0][3])/2,400+2*zoom);
  assert.ok(Math.abs((still[0][2]-still[0][0])/zoom-(key==='wanderer'?34:30))<1e-9);
 }
 h.draw_ellipse=ellipse;
 console.log('PASS: production Vigil, spawn, shock, model and shadow draw functions; rendered .build/feedback-review.png.');
 console.log('PASS: endpoint/path footprint parity, grounded shadows through stance and recoil, and zoom scaling.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
