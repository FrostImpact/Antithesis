// Render the production map and HUD at the game's actual GUI resolution.
const fs=require('node:fs'),assert=require('node:assert/strict');
const {createCanvas}=require('@napi-rs/canvas');
const {createHost}=require('./loadout.cjs');
const {h,api}=createHost();const cv=createCanvas(1366,768),g=cv.getContext('2d');
const read=p=>fs.readFileSync(p,'utf8').replace(/\bmod\b/g,'%').replace(/\bexit;/g,'return;');
let colour='#fff',points=[];
const finite=(...v)=>assert.ok(v.every(Number.isFinite));
const rgb=c=>`rgb(${c.join(',')})`;
Object.assign(h,{cos:Math.cos,floor:Math.floor,sqrt:Math.sqrt,sign:Math.sign,
 array_sort:(a,f)=>a.sort(f),array_create:(n,v)=>Array(n).fill(v),
 point_direction:(x,y,a,b)=>Math.atan2(y-b,a-x)*180/Math.PI,
 c_white:[255,255,255],c_black:[0,0,0],pr_trianglefan:0,
 merge_colour:(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t),
 draw_set_alpha:a=>{finite(a);g.globalAlpha=Math.max(0,Math.min(1,a));},
 draw_set_colour:c=>{assert.ok(c);colour=rgb(c);},
 draw_clear:c=>{g.fillStyle=rgb(c);g.fillRect(0,0,1366,768);},
 draw_rectangle_colour:(x,y,a,b,c,d,e,f)=>{const gradient=g.createLinearGradient(x,y,x,b);gradient.addColorStop(0,rgb(c));gradient.addColorStop(1,rgb(e));g.fillStyle=gradient;g.fillRect(x,y,a-x,b-y);},
 draw_rectangle:(x,y,a,b,outline)=>{finite(x,y,a,b);g.fillStyle=g.strokeStyle=colour;g.lineWidth=1;outline?g.strokeRect(x,y,a-x,b-y):g.fillRect(x,y,a-x,b-y);},
 draw_primitive_begin:()=>points=[],draw_vertex:(x,y)=>{finite(x,y);points.push([x,y]);},
 draw_primitive_end:()=>{g.fillStyle=colour;g.beginPath();points.forEach(([x,y],i)=>i?g.lineTo(x,y):g.moveTo(x,y));g.closePath();g.fill();},
 draw_line_width:(x,y,a,b,w)=>{finite(x,y,a,b,w);g.strokeStyle=colour;g.lineWidth=w;g.beginPath();g.moveTo(x,y);g.lineTo(a,b);g.stroke();},
 draw_ellipse:(x,y,a,b,outline)=>{finite(x,y,a,b);g.fillStyle=g.strokeStyle=colour;g.lineWidth=1;g.beginPath();g.ellipse((x+a)/2,(y+b)/2,Math.abs(a-x)/2,Math.abs(b-y)/2,0,0,Math.PI*2);outline?g.stroke():g.fill();},
 draw_triangle:(x,y,a,b,c,d)=>{finite(x,y,a,b,c,d);g.fillStyle=colour;g.beginPath();g.moveTo(x,y);g.lineTo(a,b);g.lineTo(c,d);g.closePath();g.fill();},
 fa_left:'left',fa_right:'right',fa_center:'center',fa_top:'top',fa_bottom:'bottom',fa_middle:'middle',
 draw_set_halign:a=>g.textAlign=a,draw_set_valign:a=>g.textBaseline=a,
 draw_text:(x,y,text)=>{finite(x,y);g.fillStyle=colour;g.fillText(text,x,y);},
 draw_text_transformed:(x,y,text,sx,sy,angle)=>{finite(x,y,sx,sy,angle);g.save();g.translate(x,y);g.rotate(-angle*Math.PI/180);g.scale(sx,sy);g.fillStyle=colour;g.fillText(text,0,0);g.restore();},
 string_height:()=>14,string_width:text=>g.measureText(text).width,string_length:s=>s.length,string_char_at:(s,n)=>s[n-1],string_copy:(s,n,l)=>s.slice(n-1,n-1+l),
 string_format:(n,w,d)=>n.toFixed(d),
 obj_camera:{zoom:1,map_angle:45},ui_draw_world_feedback:()=>{},tower_draw_shadow:()=>{},
 elapsed:2,sky_constellations:[],sky_constellation_links:[],obj_encounter:{phase:'preparation',round_number:0},
 UiAction:{None:-1,Target:0,Charge:1,Move:2,AbilityDoubleTap:3,AbilityShockBolts:4,AbilityOverloaded:5,AbilityMove:6,Spawn:7,Count:8},
 TowerChargeState:{Ready:0,Charging:1},tower_status:()=> 'READY',tower_can_charge:()=>true,tower_charge_progress:()=>0,
});
h.draw_line=(x,y,a,b)=>h.draw_line_width(x,y,a,b,1);
function wrap(text,width){const lines=[];for(const para of text.split('\n')){let line='';for(const word of para.split(' ')){const next=line?line+' '+word:word;if(line&&g.measureText(next).width>width){lines.push(line);line=word;}else line=next;}lines.push(line);}return lines;}
h.draw_text_ext=(x,y,text,sep,width)=>wrap(text,width).forEach((line,i)=>h.draw_text(x,y+i*sep,line));
h.string_height_ext=(text,sep,width)=>wrap(text,width).length*sep;
g.font='14px Arial';g.textBaseline='top';
const source=['scr_geometry','scr_map','scr_defender','scr_effects','scr_interface'].map(n=>read(`scripts/${n}/${n}.gml`)).join('\n');
const names=['project_x','project_y','map_clip_polygon','map_draw_polygon','draw_ground_tile','is_path','map_draw_spawn_platform','map_draw_base_platform','diamond','draw_defender','draw_wanderer','draw_triage','draw_vigil_icon','ui_panel_y','ui_draw_rich_text','ui_control_rect','ui_draw_button','ui_stat_breakdown','ui_draw_surface'];
const drawApi=new Function('s',`with(s){${source};return {${names.join(',')}};}`)(h);Object.assign(h,drawApi);
h.obj_game.tower_catalog.triage.draw_model=h.draw_triage;h.obj_game.tower_catalog.vestral.draw_model=h.draw_defender;h.obj_game.tower_catalog.wanderer.draw_model=h.draw_wanderer;
const room=JSON.parse(fs.readFileSync('rooms/Room1/Room1.yy','utf8').replace(/,\s*([}\]])/g,'$1'));
const instances=room.layers.find(l=>l.name==='Instances').instances;
const worldPoint=i=>[(i.x-128)/64,(i.y-96)/64];
const regions=type=>instances.filter(i=>i.objectId.name===type).map(i=>{const [x,y]=worldPoint(i);return [x-i.scaleX/2,y-i.scaleY/2,x+i.scaleX/2,y+i.scaleY/2,i.imageIndex];});
h.land_shelves=regions('obj_map_surface');h.void_regions=regions('obj_map_void');
h.route=instances.filter(i=>i.objectId.name==='obj_map_route').sort((a,b)=>a.imageIndex-b.imageIndex).map(worldPoint);
h.obj_world={route:h.route,land_shelves:h.land_shelves,void_regions:h.void_regions};
h.obj_game.config={gui_width:1366,gui_height:768,charge_key:67,move_key:77};
h.chr=n=>String.fromCharCode(n);
const ui={cr_default:0,GlossaryTerm:{None:-1},UiAction:h.UiAction,array_create:h.array_create};
const init=read('objects/obj_ui/Create_0.gml');for(const m of init.matchAll(/^([a-z_]+)=/gm))ui[m[1]]=undefined;
new Function('s',`with(s){${init}}`)(ui);h.obj_ui=ui;ui.panel_open=1;ui.panel_blend=1;
const worldDraw=new Function('s',`with(s){${read('objects/obj_world/Draw_0.gml')}}`);
h.loadout_draw=api.draw;h.loadout_reward_active=api.rewardActive;
h.ui_health_colour=new Function('s',`with(s){${read('scripts/scr_interface/scr_interface.gml')};return ui_health_colour;}`)(h);
const hudDraw=new Function('s',`with(s){with(obj_ui){${read('objects/obj_ui/Draw_64.gml')}}}`);
function render(file){worldDraw(h);hudDraw(h);fs.mkdirSync('.build',{recursive:true});fs.writeFileSync(file,cv.toBuffer('image/png'));}
api.use(0);api.tick(1);api.use(1);api.tick(1);
h.obj_game.loadout.cards=[2,2,1,1,1];h.obj_game.loadout.selected=1;h.obj_game.loadout.fan_hover[1]=1;
render('.build/loadout-review.png');
const d=h.obj_game.tower_catalog.vestral;
h.obj_game.selected_tower={definition:d,damage:d.damage,attack_shots_left:0,hit_points:d.max_hit_points,display_hit_points:d.max_hit_points,max_hit_points:d.max_hit_points,move_speed:d.move_speed,attack_interval:d.attack_interval,attack_range:d.attack_range,charge_duration:d.charge_duration,
 charge_reuse_delay:d.charge_reuse_delay,charge_mode:0,charge_lockout:0,reject_pulse:0,target_mode:0,ability_detail_open:false};
render('.build/loadout-dossier-review.png');
h.obj_game.selected_tower.ability_detail_open=true;h.obj_game.selected_tower.ability_tab=1;ui.detail_blend=1;
render('.build/loadout-ability-review.png');
const w=h.obj_game.tower_catalog.wanderer;
Object.assign(h.obj_game.selected_tower,{definition:w,damage:w.damage,hit_points:66,display_hit_points:66,max_hit_points:w.max_hit_points,move_speed:w.move_speed,attack_interval:w.attack_interval,attack_range:w.attack_range,charge_duration:w.charge_duration,vigil:4,vigil_earned:4});
render('.build/loadout-wanderer-review.png');
const medic=h.obj_game.tower_catalog.triage;
Object.assign(h.obj_game.selected_tower,{definition:medic,damage:medic.damage,hit_points:110,display_hit_points:110,max_hit_points:110,move_speed:medic.move_speed,attack_interval:medic.attack_interval,attack_range:medic.attack_range,charge_duration:medic.charge_duration,charge_reuse_delay:medic.charge_reuse_delay});
h.obj_game.loadout.selected=4;
render('.build/loadout-triage-review.png');
h.obj_game.loadout.selected=-1;h.obj_game.loadout.hover=-1;h.obj_game.selected_tower=null;
h.obj_game.loadout.bar_pinned=false;api.tick(1);
render('.build/loadout-minimized-review.png');
api.reward(1);api.tick(.7);
render('.build/reward-choice-review.png');
api.choose(1);api.tick(.4);
render('.build/reward-claim-review.png');
api.tick(.5);api.addBits(150);api.notice('Bit Cache redeemed');api.tick(.3);
render('.build/bits-gain-review.png');
// Inspect the new enemy through its actual production draw functions.
const blankApi=new Function('s',`with(s){${read('scripts/scr_blanks/scr_blanks.gml')};return {model:blank_draw_model,laser:blank_draw_laser};}`)(h);
h.draw_clear([23,29,32]);h.draw_set_colour(h.obj_game.ui_theme.title);h.draw_text(48,40,'LANCER / LASER SEQUENCE');
const laserDefinition=new Function(read('scripts/scr_definitions/scr_definitions.gml')+';return build_enemy_catalog().lancer;')();
for(const [i,state] of ['walking','aiming','firing'].entries()) {
 const x=160+i*430,y=390;h.obj_camera.zoom=2;
 const e={x,y,enemy_definition:laserDefinition,spawn_left:0,drift_phase:0,hit_flash:0,laser_state:state,
  laser_clock:state==='aiming'?.4:.2,laser_world_x:0,laser_world_y:0};
 // Isolate projection only: beam drawing and model geometry remain production code.
 const oldX=h.project_x,oldY=h.project_y;h.project_x=()=>x+145;h.project_y=()=>y+32;
 blankApi.model(e);blankApi.laser(e);h.project_x=oldX;h.project_y=oldY;
 h.draw_set_colour(h.obj_game.ui_theme.accent);h.draw_text(x-70,480,state.toUpperCase());
}
fs.writeFileSync('.build/laser-enemy-review.png',cv.toBuffer('image/png'));
console.log('PASS: rendered production map and card/loadout HUD, with and without the tower dossier.');
