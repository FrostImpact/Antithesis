(function(root){
function createSingularityPreview(ctx,source){
 const base=typeof require==='function'?require('./triage-preview-host.cjs').createTriagePreview(ctx,source):root.createTriagePreview(ctx,source);
 const h=base.h;
 h.diamond=(x,y,w,height,c)=>{h.draw_set_colour(c);h.draw_triangle(x-w,y,x,y-height,x+w,y);h.draw_triangle(x-w,y,x,y+height,x+w,y);};
 const api=new Function('h','with(h){'+source+';return {model:draw_singularity,actor:singularity_draw_actor,pose:singularity_pose,clip:singularity_emergence_face,orbit:singularity_draw_orbit,charge:singularity_draw_charge,event:singularity_draw_event,portal:singularity_draw_portal,icon:draw_singularity_icon};}')(h);
 const effect=(style,t)=>api.event({age:t,lifetime:style==='horizon'?1:.6,world_x:0,world_y:0,fx_style:style,fx_radius:2.5});
 function frame(clock,angle=320,zoom=4){
  h.obj_camera.zoom=zoom;h.obj_world.elapsed=clock;h.tower_charge_progress=t=>1-t.charge_left/2;
  ctx.globalAlpha=1;ctx.fillStyle='#14101c';ctx.fillRect(0,0,1100,650);
  const t=clock%14,charging=t>=5&&t<7,windup=t>=2&&t<3.6,summon=Math.max(0,1.6-t);
  const debris=[];if(t>=3.6&&t<5)for(let i=0;i<6;i++)debris.push({angle:(i*60+clock*110)%360,left:8.6-t,serial:i});
  const instantAge=t>=8.3?(t-8.3)%1.1:1;
  const impact=t>=3.6&&t<4.3?.7-(t-3.6):instantAge<.7?.7-instantAge:0;
  const tower={x:540,y:455,world_x:0,world_y:0,facing:angle,idle_time:clock,
    definition:{key:'singularity',debris_radius:1.65,pulse_windup:1.6,pulse_recovery:.7,summon_duration:1.6},debris,density:t>=7?Math.max(0,6-Math.floor(Math.max(0,t-7.2)/1.1)):0,
    pulse_left:windup?3.6-t:0,pulse_fx:impact,skill_release:t>=7&&t<7.8?.8-(t-7):0,summon_left:summon,
    charge_mode:charging?1:0,charge_left:charging?7-t:0,attack_range:2.5};
  if(summon>0)api.portal(tower,false);
  else {ctx.fillStyle='#09060e';ctx.beginPath();ctx.ellipse(540,465,80,22,0,0,Math.PI*2);ctx.fill();}
  api.orbit(tower,false);api.actor(tower);api.orbit(tower,true);
  if(summon>0)api.portal(tower,true);else api.charge(tower);
  if(t>=3.6&&t<4.2)effect('pulse',t-3.6);
  if(t>=5&&t<6)effect('horizon',t-5);
  if(t>=7&&t<8)effect('horizon',t-7);
  if(t>=8.3&&instantAge<.6)effect('pulse',instantAge);
  ctx.globalAlpha=1;ctx.fillStyle='#e4caff';ctx.font='24px Arial';ctx.fillText('SINGULARITY / THE WEIGHT OF THE WORLD',32,42);
  ctx.font='16px Arial';ctx.fillStyle='#af91c8';ctx.fillText(summon>0?'SUMMON / PORTAL EMERGENCE':charging?'EVENT HORIZON / TWO-HANDED COMPRESSION':t>=7?'DENSITY / INSTANT IMPACT':windup?'GRAVITY WELL / RAISE + SLAM':impact>0?'GROUND IMPACT / RECOVERY':'GROUNDED STANCE',32,74);
  return base.getAlpha();
 }
 return {frame,api,h,effect};
}
if(typeof module!=='undefined')module.exports={createSingularityPreview};else root.createSingularityPreview=createSingularityPreview;
})(globalThis);
