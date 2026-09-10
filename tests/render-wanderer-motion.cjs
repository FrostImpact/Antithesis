const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..');
const source=['scr_defender','scr_effects'].map(n=>fs.readFileSync(path.join(root,`scripts/${n}/${n}.gml`),'utf8')).join('\n').replace(/\bmod\b/g,'%');
const html=`<!doctype html><html><meta charset="utf-8"><title>WANDERER motion study</title>
<style>body{margin:0;background:#11170e;color:#e4edcb;font:16px system-ui}main{max-width:1100px;margin:auto;padding:24px}h1{font-size:23px;letter-spacing:3px}p{color:#a5b48d}canvas{width:100%;background:#151c12;border:1px solid #39462e}button{background:#bddf72;color:#182010;border:0;padding:10px 24px;cursor:pointer}span{margin-left:20px}</style>
<main><h1>WANDERER / VIGIL</h1><p>Kneel → gather → brace → execution → settle. Rendered from the game's model and effect functions.</p><canvas id="view" width="1100" height="650"></canvas><p><button id="pause">Pause</button><span id="stage"></span></p></main>
<script>
const canvas=document.getElementById('view'),ctx=canvas.getContext('2d');let polygon=[],colour=[0,0,0],clock=0,last=0,paused=false;
const color=()=> 'rgb('+colour.join(',')+')';
const host={clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),lerp:(a,b,t)=>a+(b-a)*t,max:Math.max,sqrt:Math.sqrt,sin:Math.sin,
dsin:a=>Math.sin(a*Math.PI/180),dcos:a=>Math.cos(a*Math.PI/180),frac:v=>v-Math.floor(v),power:Math.pow,pi:Math.PI,
make_colour_rgb:(...v)=>v,merge_colour:(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t),c_black:[0,0,0],c_white:[255,255,255],pr_trianglefan:0,
array_length:a=>a.length,array_push:(a,v)=>a.push(v),array_sort:(a,f)=>a.sort(f),sign:Math.sign,
draw_set_colour:c=>colour=c,draw_set_alpha:a=>ctx.globalAlpha=Math.max(0,Math.min(1,a)),
draw_primitive_begin:()=>polygon=[],draw_vertex:(x,y)=>polygon.push([x,y]),draw_primitive_end:()=>{ctx.fillStyle=color();ctx.beginPath();polygon.forEach(([x,y],i)=>i?ctx.lineTo(x,y):ctx.moveTo(x,y));ctx.closePath();ctx.fill();},
draw_triangle:(x1,y1,x2,y2,x3,y3)=>{ctx.fillStyle=color();ctx.beginPath();ctx.moveTo(x1,y1);ctx.lineTo(x2,y2);ctx.lineTo(x3,y3);ctx.closePath();ctx.fill();},
draw_line_width:(x,y,tx,ty,w)=>{ctx.strokeStyle=color();ctx.lineWidth=Math.max(.1,w);ctx.beginPath();ctx.moveTo(x,y);ctx.lineTo(tx,ty);ctx.stroke();},
bm_add:1,bm_normal:0,gpu_set_blendmode:m=>ctx.globalCompositeOperation=m?'lighter':'source-over',
obj_camera:{zoom:6},TowerChargeState:{Ready:0,Charging:1},tower_charge_progress:t=>1-t.charge_left/1.5,
tower_visual_y:t=>t.y,project_x:x=>x,project_y:(x,y)=>y,point_direction:(x,y,tx,ty)=>Math.atan2(y-ty,tx-x)*180/Math.PI};
const api=new Function('s','with(s){'+${JSON.stringify(source)}+';return {model:draw_wanderer,muzzle:wanderer_muzzle,charge:wanderer_draw_charge_fx,shot:wanderer_draw_shot_fx};}')(host);
document.getElementById('pause').onclick=()=>{paused=!paused;document.getElementById('pause').textContent=paused?'Play':'Pause';};
function frame(now){const dt=Math.min(.05,(now-last)/1000||0);last=now;if(!paused)clock+=dt;
const t=clock%6,charging=t>=1.5&&t<3,shot=t>=3&&t<3.65,p=charging?(t-1.5)/1.5:0;
const aim=charging?1-Math.exp(-7*(t-1.5)):shot?1:t>=3.65?Math.exp(-7*(t-3.65)):0;
const charge=charging?1-Math.exp(-9*(t-1.5)):0,kick=shot?19*Math.exp(-14*(t-3)):0;
ctx.globalAlpha=1;ctx.globalCompositeOperation='source-over';ctx.clearRect(0,0,1100,650);
ctx.fillStyle='#0d120b';ctx.beginPath();ctx.ellipse(420,490,100,27,0,0,Math.PI*2);ctx.fill();
api.model(420,490,320,clock,kick,aim,charge,0,6);
const tower={x:420,y:490,idle_time:clock,facing:320,recoil:kick,aim_blend:aim,charge_pose:charge,charge_mode:charging?1:0,charge_left:1.5*(1-p),finisher_flash:shot?.65-(t-3):0,beam_world_x:960,beam_world_y:425,definition:{muzzle:api.muzzle}};
api.charge(tower);api.shot(tower);
document.getElementById('stage').textContent=charging?'EXECUTION / CHARGING':shot?'EXECUTION / FIRING':t>3.65&&t<4.5?'SETTLING':'VIGIL / KNEELING';requestAnimationFrame(frame);}
requestAnimationFrame(frame);
</script></html>`;
fs.writeFileSync(path.join(root,'docs/wanderer-motion.html'),html);
console.log('Rendered docs/wanderer-motion.html');
