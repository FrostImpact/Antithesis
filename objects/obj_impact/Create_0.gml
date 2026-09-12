if(!variable_instance_exists(id,"effect_kind")) effect_kind=burst ? "kill" : "hit";
age=0;
lifetime=effect_kind=="finisher" ? 0.7 : (effect_kind=="kill" ? 0.6 : 0.3);
particles=[];
if(effect_kind=="singularity") { lifetime=fx_style=="horizon" ? 1 : (fx_style=="pulse" ? 0.6 : 0.35); exit; }
if(effect_kind=="heal_arc") { lifetime=0.85; exit; }
if(effect_kind=="triage") { lifetime=fx_style=="release" ? 1.1 : (fx_style=="dart" ? 0.35 : 0.8); exit; }
if(effect_kind=="vigil") { lifetime=0.95; exit; }
if(effect_kind=="text") { lifetime=popup_status ? 0.65 : 0.7; exit; }
var count=effect_kind=="finisher" ? 20 : (effect_kind=="kill" ? 14 : 6);
for(var i=0;i<count;++i) {
    var angle=i/count*360+random_range(-14,14);
    var particle_speed=random_range(0.5,effect_kind=="hit" ? 1.2 : 2.2);
    array_push(particles,{wx:world_x,wy:world_y,z:20,vx:dcos(angle)*particle_speed,vy:dsin(angle)*particle_speed,
        vz:random_range(12,48),rotation:random(360),spin:random_range(-240,240),size:random_range(1.2,3.0)});
}

