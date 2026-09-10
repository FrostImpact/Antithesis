// Short-lived combat effects are distinct from the static map and its range overlays.
function tower_draw_attack_fx(_tower) {
    if(_tower.definition.key=="wanderer") { wanderer_draw_shot_fx(_tower); return; }
    if(_tower.beam<=0) return;
    var muzzle=_tower.definition.muzzle(_tower.x,tower_visual_y(_tower),_tower.facing,
        _tower.idle_time,_tower.recoil,_tower.aim_blend,_tower.charge_pose,_tower.recovery_left/0.5,obj_camera.zoom);
    _tower.shot_x=muzzle[0]; _tower.shot_y=muzzle[1];
    var tx=project_x(_tower.beam_world_x,_tower.beam_world_y);
    var ty=project_y(_tower.beam_world_x,_tower.beam_world_y)-20*obj_camera.zoom;
    var intensity=clamp(_tower.beam/max(0.001,_tower.shot_fx_duration),0,1);
    var special=_tower.finisher_flash>0;
    var colour=_tower.definition.key=="wanderer" ? make_colour_rgb(69,226,235) : (special ? make_colour_rgb(242,216,148) : make_colour_rgb(111,218,239));
    draw_set_alpha(intensity*0.3);
    draw_set_colour(colour);
    draw_line_width(muzzle[0],muzzle[1],tx,ty,(special ? 7 : 4)*obj_camera.zoom);
    draw_set_alpha(intensity);
    draw_set_colour(c_white);
    draw_line_width(muzzle[0],muzzle[1],tx,ty,1.3*obj_camera.zoom);
    // Parallel shock tracers make the two-hit attack readable at this scale.
    draw_set_colour(colour);
    draw_set_alpha(intensity*0.7);
    draw_line_width(muzzle[0],muzzle[1]+3*obj_camera.zoom,tx,ty+3*obj_camera.zoom,obj_camera.zoom);
    // A directional flash opens at the actual moving muzzle.
    if(_tower.beam>_tower.shot_fx_duration*0.5) {
        var ray_direction=point_direction(muzzle[0],muzzle[1],tx,ty);
        var length=(special ? 16 : 10)*intensity*obj_camera.zoom;
        draw_set_colour(colour);
        draw_triangle(muzzle[0]+lengthdir_x(3,ray_direction+90),muzzle[1]+lengthdir_y(3,ray_direction+90),
            muzzle[0]+lengthdir_x(length,ray_direction),muzzle[1]+lengthdir_y(length,ray_direction),
            muzzle[0]+lengthdir_x(3,ray_direction-90),muzzle[1]+lengthdir_y(3,ray_direction-90),false);
    }
    draw_set_alpha(1);
}
function tower_draw_charge_fx(_tower) {
    if(_tower.definition.key=="wanderer") { wanderer_draw_charge_fx(_tower); return; }
    if(_tower.charge_mode!=TowerChargeState.Charging) return;
    var progress=tower_charge_progress(_tower);
    var focus=_tower.definition.muzzle(_tower.x,tower_visual_y(_tower),_tower.facing,
        _tower.idle_time,_tower.recoil,_tower.aim_blend,_tower.charge_pose,_tower.recovery_left/0.5,obj_camera.zoom);
    var count=6;
    for(var i=0;i<count;++i) {
        var phase=frac(_tower.idle_time*1.8+i/count);
        var angle=i*60+_tower.idle_time*35;
        var distance=(1-phase)*(15+progress*10)*obj_camera.zoom;
        var px=focus[0]+dcos(angle)*distance;
        var py=focus[1]+dsin(angle)*distance*0.65;
        draw_set_alpha(sin(phase*pi)*(0.3+progress*0.6));
        draw_set_colour(_tower.definition.key=="wanderer" ? make_colour_rgb(69,226,235) : make_colour_rgb(102,223,237));
        draw_line_width(px,py,px+dcos(angle)*3*obj_camera.zoom,py+dsin(angle)*2*obj_camera.zoom,1.5*obj_camera.zoom);
    }
    draw_set_alpha(progress*0.7);
    diamond(focus[0],focus[1],(2+progress*2)*obj_camera.zoom,(1.5+progress)*obj_camera.zoom,c_white);
    draw_set_alpha(1);
}

// Confirmed relocation becomes a short phase dash. It uses the tower's own
// model for fading echoes plus neutral fragments that remain readable over any map.
function tower_draw_move_fx(_tower) {
    if(!_tower.move_active) return;
    if(_tower.definition.key=="wanderer") { wanderer_draw_move_fx(_tower); return; }
    var count=array_length(_tower.move_trail_x);
    gpu_set_blendmode(bm_add);
    for(var trail=count-1;trail>=1;--trail) {
        var fade=(1-trail/count)*0.11;
        if(fade<=0) continue;
        var ghost_x=project_x(_tower.move_trail_x[trail],_tower.move_trail_y[trail]);
        var ghost_y=project_y(_tower.move_trail_x[trail],_tower.move_trail_y[trail]);
        draw_set_alpha(fade);
        _tower.definition.draw_model(ghost_x,ghost_y,_tower.facing,_tower.idle_time-trail*0.025,
            0,_tower.aim_blend,0,0,obj_camera.zoom);
        draw_set_alpha(fade*2.2);
        diamond(ghost_x,ghost_y+2*obj_camera.zoom,(4+trail)*obj_camera.zoom,
            (1.5+trail*0.28)*obj_camera.zoom,make_colour_rgb(211,216,220));
    }
    var progress=tower_move_progress(_tower);
    for(var particle=0;particle<8;++particle) {
        var phase=frac(progress*2.4+particle/8);
        var wx=lerp(_tower.move_from_x,_tower.world_x,phase);
        var wy=lerp(_tower.move_from_y,_tower.world_y,phase);
        var particle_x=project_x(wx,wy)+sin(particle*4.1+progress*19)*5*obj_camera.zoom;
        var particle_y=project_y(wx,wy)+cos(particle*3.7+progress*17)*3*obj_camera.zoom;
        draw_set_alpha(sin(phase*pi)*0.55);
        diamond(particle_x,particle_y,(1.6+particle mod 3)*obj_camera.zoom,
            (0.8+(particle mod 2)*0.5)*obj_camera.zoom,make_colour_rgb(225,228,231));
    }
    draw_set_alpha(1);
    gpu_set_blendmode(bm_normal);
}

// WANDERER has its own deterministic effects. No Vestral particles or impact
// instances are emitted; all motion uses paused gameplay clocks and world anchors.
function wanderer_leaf(_x,_y,_angle,_size,_alpha) {
    draw_set_alpha(_alpha);
    draw_set_colour(make_colour_rgb(183,240,66));
    var dx=dcos(_angle)*_size;var dy=dsin(_angle)*_size;
    draw_triangle(_x-dx,_y-dy,_x+dx,_y+dy,_x-dy*0.32,_y+dx*0.32,false);
    draw_set_colour(make_colour_rgb(237,255,180));
    draw_triangle(_x-dx,_y-dy,_x+dx,_y+dy,_x+dy*0.16,_y-dx*0.16,false);
}

function wanderer_draw_charge_fx(_tower) {
    if(_tower.charge_mode!=TowerChargeState.Charging) return;
    var p=tower_charge_progress(_tower);var z=obj_camera.zoom;
    var focus=_tower.definition.muzzle(_tower.x,tower_visual_y(_tower),_tower.facing,
        _tower.idle_time,_tower.recoil,_tower.aim_blend,_tower.charge_pose,0,z);
    gpu_set_blendmode(bm_add);
    // Two counter-winding streams accelerate and collapse into the barrel.
    for(var i=0;i<38;++i) {
        var phase=frac(p*(1.2+p*1.4)+i/38);
        var spin=i*137.5+p*450*(i mod 2==0 ? 1 : -1);
        var radius=(1-phase)*(34+p*24)*z;
        var px=focus[0]+dcos(spin)*radius;
        var py=focus[1]+dsin(spin)*radius*0.6+(1-phase)*16*z;
        wanderer_leaf(px,py,spin+phase*100,(1.3+phase*2.5+p)*z,sin(phase*pi)*(0.2+p*0.75));
    }
    // Broken expanding ground seal and rising specks sell the gathering force.
    for(var i=0;i<12;++i) {
        var a=i*30+p*80;var radius=(15+p*12)*z;
        var gx=_tower.x+dcos(a)*radius;var gy=_tower.y+dsin(a)*radius*0.45;
        draw_set_colour(make_colour_rgb(135,186,46));draw_set_alpha(p*0.6);
        draw_line_width(gx,gy,_tower.x+dcos(a+13)*radius,_tower.y+dsin(a+13)*radius*0.45,z);
        var lift=frac(p*2+i/12);
        wanderer_leaf(gx,gy-lift*36*z,a+90,(1-lift)*2*z,p*(1-lift)*0.65);
    }
    var flare=power(p,4);var pulse=0.8+sin(p*90)*0.2;
    draw_set_colour(make_colour_rgb(224,255,151));draw_set_alpha(flare*pulse);
    draw_line_width(focus[0]-(6+flare*22)*z,focus[1],focus[0]+(6+flare*22)*z,focus[1],1.5*z);
    draw_line_width(focus[0],focus[1]-9*flare*z,focus[0],focus[1]+9*flare*z,z);
    draw_set_alpha(1);gpu_set_blendmode(bm_normal);
}

function wanderer_draw_shot_fx(_tower) {
    if(_tower.finisher_flash<=0) return;
    var age=0.65-_tower.finisher_flash;var t=clamp(age/0.65,0,1);var fade=1-t;
    var z=obj_camera.zoom;
    var muzzle=_tower.definition.muzzle(_tower.x,tower_visual_y(_tower),_tower.facing,
        _tower.idle_time,_tower.recoil,_tower.aim_blend,_tower.charge_pose,0,z);
    var tx=project_x(_tower.beam_world_x,_tower.beam_world_y);
    var ty=project_y(_tower.beam_world_x,_tower.beam_world_y)-20*z;
    var angle=-point_direction(muzzle[0],muzzle[1],tx,ty);
    gpu_set_blendmode(bm_add);
    // One piercing shot with a broad initial flash, then a thin fading afterimage.
    if(age<0.22) {
        var flash=1-age/0.22;
        draw_set_colour(make_colour_rgb(170,235,57));draw_set_alpha(flash*0.55);
        draw_line_width(muzzle[0],muzzle[1],tx,ty,(2+flash*10)*z);
        draw_set_colour(make_colour_rgb(245,255,209));draw_set_alpha(flash);
        draw_line_width(muzzle[0],muzzle[1],tx,ty,1.6*z);
        var length=(12+flash*34)*z;
        draw_triangle(muzzle[0]+dcos(angle+90)*6*flash*z,muzzle[1]+dsin(angle+90)*6*flash*z,
            muzzle[0]+dcos(angle)*length,muzzle[1]+dsin(angle)*length,
            muzzle[0]+dcos(angle-90)*6*flash*z,muzzle[1]+dsin(angle-90)*6*flash*z,false);
    }
    // Asymmetric muzzle splinters and a large target-centered burst persist after kills.
    for(var i=0;i<44;++i) {
        var impact=i>=18;var dir=impact ? i*137.5 : angle+(i-9)*6;
        var travel=(1-power(1-t,3))*(impact ? 14+(i mod 7)*6 : 10+(i mod 5)*6)*z;
        var px=(impact ? tx : muzzle[0])+dcos(direction)*travel;
        var py=(impact ? ty : muzzle[1])+dsin(direction)*travel+t*t*15*z;
        wanderer_leaf(px,py,dir+t*180,(2+(i mod 4))*fade*z,fade*fade*(impact ? 0.9 : 0.65));
    }
    // Impact fracture: four long slashes open outward, distinct from shock rings.
    for(var i=0;i<4;++i) {
        var a=45+i*90;var radius=(4+t*28)*z;
        draw_set_colour(make_colour_rgb(220,255,135));draw_set_alpha(fade*fade);
        draw_line_width(tx+dcos(a)*radius,ty+dsin(a)*radius,
            tx+dcos(a)*(radius+12*fade*z),ty+dsin(a)*(radius+12*fade*z),2*fade*z);
    }
    draw_set_alpha(1);gpu_set_blendmode(bm_normal);
}

function wanderer_draw_move_fx(_tower) {
    var p=tower_move_progress(_tower);var z=obj_camera.zoom;
    gpu_set_blendmode(bm_add);
    for(var i=0;i<24;++i) {
        var phase=frac(p+i/24);
        var wx=lerp(_tower.move_from_x,_tower.world_x,phase);
        var wy=lerp(_tower.move_from_y,_tower.world_y,phase);
        wanderer_leaf(project_x(wx,wy)+sin(i*2.4+p*9)*8*z,
            project_y(wx,wy)-sin(phase*pi)*20*z,i*137+p*240,(1+phase*2)*z,sin(phase*pi)*0.6);
    }
    draw_set_alpha(1);gpu_set_blendmode(bm_normal);
}


