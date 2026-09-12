// Shared renderer for production TRIAGE geometry and effects, in Node and browser.
(function(root){
function createTriagePreview(ctx,source){
 let polygon=[],colour=[0,0,0],alpha=1,vertices=0;
 const check=(...v)=>{if(!v.every(Number.isFinite))throw Error('Non-finite TRIAGE draw');};
 const color=()=> 'rgb('+colour.join(',')+')';
 const h={clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),lerp:(a,b,t)=>a+(b-a)*t,min:Math.min,max:Math.max,sqrt:Math.sqrt,sin:Math.sin,point_direction:(x,y,a,b)=>Math.atan2(y-b,a-x)*180/Math.PI,
 dsin:a=>Math.sin(a*Math.PI/180),dcos:a=>Math.cos(a*Math.PI/180),frac:v=>v-Math.floor(v),power:Math.pow,pi:Math.PI,
 make_colour_rgb:(...v)=>v,merge_colour:(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t),c_black:[0,0,0],c_white:[255,255,255],pr_trianglefan:0,
 array_length:a=>a.length,array_push:(a,v)=>a.push(v),array_sort:(a,f)=>a.sort(f),sign:Math.sign,
 draw_set_colour:c=>{check(...c);colour=c;},draw_set_alpha:a=>{check(a);alpha=a;ctx.globalAlpha=Math.max(0,Math.min(1,a));},
 draw_primitive_begin:()=>polygon=[],draw_vertex:(x,y)=>{check(x,y);vertices++;polygon.push([x,y]);},
 draw_primitive_end:()=>{ctx.fillStyle=color();ctx.beginPath();polygon.forEach(([x,y],i)=>i?ctx.lineTo(x,y):ctx.moveTo(x,y));ctx.closePath();ctx.fill();},
 draw_triangle:(x,y,a,b,c,d)=>{check(x,y,a,b,c,d);ctx.fillStyle=color();ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(a,b);ctx.lineTo(c,d);ctx.closePath();ctx.fill();},
 draw_line_width:(x,y,a,b,w)=>{check(x,y,a,b,w);ctx.strokeStyle=color();ctx.lineWidth=Math.max(.1,w);ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(a,b);ctx.stroke();},
 draw_rectangle:(x,y,a,b,outline)=>{check(x,y,a,b);ctx.fillStyle=ctx.strokeStyle=color();outline?ctx.strokeRect(x,y,a-x,b-y):ctx.fillRect(x,y,a-x,b-y);},
 draw_ellipse:(x,y,a,b,outline)=>{check(x,y,a,b);ctx.fillStyle=ctx.strokeStyle=color();ctx.lineWidth=1.2;ctx.beginPath();ctx.ellipse((x+a)/2,(y+b)/2,Math.abs(a-x)/2,Math.abs(b-y)/2,0,0,Math.PI*2);outline?ctx.stroke():ctx.fill();},
 instance_exists:o=>!!o&&!o.destroyed,
 obj_camera:{zoom:4},obj_world:{elapsed:0},TowerChargeState:{Ready:0,Charging:1},tower_charge_progress:t=>1-t.charge_left/2.5,
 tower_move_progress:t=>t.move_elapsed/t.move_duration,tower_visual_y:t=>t.y,
 project_x:(x,y)=>540+(x-y)*52,project_y:(x,y)=>455+(x+y)*26};
 const api=new Function('h','with(h){'+source+';return {defender:draw_defender,defenderMuzzle:defender_muzzle,defenderPose:defender_pose,arc:draw_heal_arc,model:draw_triage,muzzle:triage_muzzle,pose:triage_pose,ground:triage_draw_support,charge:triage_draw_charge,shot:triage_draw_dart,mark:triage_draw_tourniquet,shield:triage_draw_shield,move:triage_draw_move,event:triage_draw_event};}')(h);
 const effect=(style,age,wx=0,wy=0)=>api.event({age,lifetime:style==='release'?1.1:style==='dart'?.35:.8,world_x:wx,world_y:wy,fx_owner:null,fx_style:style,fx_radius:2.8});
 function frame(clock,angle=320,zoom=4){
   h.obj_camera.zoom=zoom;h.obj_world.elapsed=clock;ctx.globalAlpha=1;ctx.clearRect(0,0,1100,650);
   ctx.fillStyle='#16121c';ctx.fillRect(0,0,1100,650);
   const t=clock%14,charging=t>=4&&t<6.5,travel=t>=10&&t<11,p=charging?(t-4)/2.5:0;
   const shotPhase=t<3.6?t%1:1;const shooting=t<3.6&&shotPhase<.22;
   const aim=t<4?1:charging?1:Math.exp(-4*(t-6.5));const charge=charging?1-Math.exp(-5*(t-4)):t>=6.5?Math.exp(-5*(t-6.5)):0;
   const kick=t<3.6?11*Math.exp(-9*shotPhase):0;
   const wx=travel?(1-Math.pow(1-(t-10),3))*2:t>=11?2:0;
   const tower={definition:{key:'triage',kit_duration:12,kit_radius:1.5},world_x:wx,world_y:0,x:h.project_x(wx,0),y:h.project_y(wx,0),
     idle_time:clock,facing:angle,recoil:kick,aim_blend:aim,charge_pose:charge,charge_mode:charging?1:0,charge_left:2.5*(1-p),attack_range:2.8,
     kit_left:t>=11?12-(t-11):0,kit_x:0,kit_y:0,shield_hp:t>=6.5&&t<9.5?33*(1-(t-6.5)/3):0,max_hit_points:110,
     beam:shooting?.22-shotPhase:0,shot_fx_duration:.22,beam_world_x:3.5,beam_world_y:-3,move_elapsed:t-10,move_duration:1,move_from_x:0,move_from_y:0};
   api.ground(tower);
   ctx.globalAlpha=1;ctx.fillStyle='#0b090f';ctx.beginPath();ctx.ellipse(tower.x,tower.y+5,zoom*19,zoom*5,0,0,Math.PI*2);ctx.fill();
   if(travel)api.move(tower);
   api.model(tower.x,tower.y,angle,clock,kick,aim,charge,0,zoom,travel?Math.sin((t-10)*Math.PI):0);
   api.charge(tower);api.shot(tower);api.shield(tower);
   const enemy={world_x:3.5,world_y:-3};
   ctx.globalAlpha=1;ctx.fillStyle='#705e75';ctx.beginPath();const ex=h.project_x(3.5,-3),ey=h.project_y(3.5,-3)-20*zoom;ctx.moveTo(ex,ey-22);ctx.lineTo(ex+19,ey);ctx.lineTo(ex,ey+22);ctx.lineTo(ex-19,ey);ctx.closePath();ctx.fill();
   if(t>2&&t<6.5)api.mark(enemy);
   if(shooting)effect(shotPhase<.05?'mark':'dart',shotPhase,3.5,-3);
   if(t>=6.5&&t<7.6)effect('release',t-6.5);
   if(t>=6.5&&t<7.3){effect('consume',t-6.5,3.5,-3);effect('shield',t-6.5);}
   if(t>=8&&t<8.8)effect('absorb',t-8);
   if(t>=11&&t<11.8){effect('kit',t-11);effect('land',t-11,2,0);effect('heal',t-11,2,0);}
   ctx.globalAlpha=1;ctx.fillStyle='#ffe3ef';ctx.font='22px Arial';ctx.fillText('TRIAGE / FIELD MEDIC',32,40);
   ctx.font='15px Arial';ctx.fillStyle='#c29aad';ctx.fillText(t<4?'ASSESSMENT / DARTS + TOURNIQUET':charging?'RESUSCITATION / SANCTUARY':t<10?'SHIELD / RELEASE + ABSORPTION':travel?'RAPID RESPONSE / RELOCATING':'MED KIT / DEPLOY + HEAL',32,72);
   return {vertices,alpha};
 }
 return {frame,api,h,effect,getAlpha:()=>alpha};
}
if(typeof module!=='undefined')module.exports={createTriagePreview};else root.createTriagePreview=createTriagePreview;
})(globalThis);
