// Short-lived combat effects are distinct from the static map and its range overlays.
// A shared insignia: a hooded hunter, split leaf wings and a luminous sight slit.
// Vector geometry keeps the small badge and the floating reward equally crisp.
function draw_vigil_icon(_x,_y,_size) {
    var pale=make_colour_rgb(228,237,203);
    var lime=make_colour_rgb(187,244,72);
    var dark=make_colour_rgb(34,42,32);
    draw_set_colour(pale);
    draw_triangle(_x,_y-_size,_x-_size*0.57,_y+_size*0.46,_x+_size*0.57,_y+_size*0.46,false);
    draw_set_colour(dark);
    draw_triangle(_x,_y-_size*0.45,_x-_size*0.32,_y+_size*0.26,_x+_size*0.32,_y+_size*0.26,false);
    draw_set_colour(lime);
    draw_triangle(_x-_size,_y-_size*0.32,_x-_size*0.38,_y+_size*0.12,_x-_size*0.28,_y+_size*0.76,false);
    draw_triangle(_x+_size,_y-_size*0.32,_x+_size*0.38,_y+_size*0.12,_x+_size*0.28,_y+_size*0.76,false);
    draw_line_width(_x,_y-_size*0.18,_x,_y+_size*0.2,max(1,_size*0.12));
    diamond(_x,_y+_size*0.65,_size*0.15,_size*0.2,pale);
}

function tower_draw_shadow(_tower) {
    var z=obj_camera.zoom;
    var lift=_tower.move_active ? sin(tower_move_progress(_tower)*pi) : 0;
    var fade=(_tower.relocating && !_tower.move_active ? 0.25 : 1)*(1-lift*0.55);
    var radius=(_tower.definition.key=="wanderer" ? 17 : 15)*z*(1+lift*0.22);
    var sx=project_x(_tower.world_x,_tower.world_y);
    var sy=project_y(_tower.world_x,_tower.world_y)+2*z;
    draw_set_colour(make_colour_rgb(22,28,29));
    for(var shadow_ring=0;shadow_ring<8;++shadow_ring) {
        var r=radius*(1-shadow_ring*0.09);
        draw_set_alpha(fade*(0.016+shadow_ring*0.005));
        draw_ellipse(sx-r,sy-r*0.32,sx+r,sy+r*0.32,false);
    }
    draw_set_alpha(1);
}

function tower_draw_attack_fx(_tower) {
    if(_tower.definition.key=="singularity") return;
    if(_tower.definition.key=="triage") { triage_draw_dart(_tower); return; }
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
    if(_tower.definition.key=="singularity") return;
    if(_tower.definition.key=="triage") { triage_draw_charge(_tower); return; }
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
    if(_tower.definition.key=="triage") { triage_draw_move(_tower); return; }
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
        var px=(impact ? tx : muzzle[0])+dcos(dir)*travel;
        var py=(impact ? ty : muzzle[1])+dsin(dir)*travel+t*t*15*z;
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

function triage_cross(_x,_y,_size,_alpha) {
    draw_set_alpha(clamp(_alpha,0,1));draw_set_colour(make_colour_rgb(255,159,204));
    draw_rectangle(_x-_size*0.28,_y-_size,_x+_size*0.28,_y+_size,false);
    draw_rectangle(_x-_size,_y-_size*0.28,_x+_size,_y+_size*0.28,false);
}
function triage_draw_field(_wx,_wy,_radius,_alpha,_clock=0,_lift=0) {
    draw_set_colour(make_colour_rgb(250,133,190));draw_set_alpha(clamp(_alpha,0,1));
    var px=project_x(_wx+_radius,_wy);var py=project_y(_wx+_radius,_wy)-_lift*obj_camera.zoom;
    for(var i=1;i<=64;++i) {
        var a=i*360/64;var nx=project_x(_wx+dcos(a)*_radius,_wy+dsin(a)*_radius);var ny=project_y(_wx+dcos(a)*_radius,_wy+dsin(a)*_radius)-_lift*obj_camera.zoom;
        draw_line_width(px,py,nx,ny,1.25*obj_camera.zoom);px=nx;py=ny;
    }
    draw_set_alpha(1);
}
function triage_draw_support(_tower) {
    if(_tower.definition.key!="triage") return;
    var clock=obj_world.elapsed;var z=obj_camera.zoom;
    if(_tower.charge_mode==TowerChargeState.Charging) {
        var p=tower_charge_progress(_tower);var r=_tower.attack_range;
        triage_draw_field(_tower.world_x,_tower.world_y,r,0.7);
        triage_draw_field(_tower.world_x,_tower.world_y,r*(0.25+frac(clock*0.7)*0.75),0.22*(1-frac(clock*0.7)));
        for(var i=0;i<12;++i) {
            var a=i*30+clock*12;var wx=_tower.world_x+dcos(a)*r;var wy=_tower.world_y+dsin(a)*r;
            var lift=frac(clock*0.45+i/12);
            triage_cross(project_x(wx,wy),project_y(wx,wy)-(4+lift*27)*z,(1.5+p)*z,sin(lift*pi)*0.6);
        }
    }
    if(_tower.kit_left>0) {
        var fade=min(1,_tower.kit_left);var age=_tower.definition.kit_duration-_tower.kit_left;
        var pop=1+sin(min(1,age/0.35)*pi)*0.25;
        triage_draw_field(_tower.kit_x,_tower.kit_y,_tower.definition.kit_radius,0.2*fade);
        var px=project_x(_tower.kit_x,_tower.kit_y);var py=project_y(_tower.kit_x,_tower.kit_y)-sin(min(1,age/0.35)*pi)*5*z;
        var k=z*pop;draw_set_alpha(fade);draw_set_colour(make_colour_rgb(109,65,91));
        draw_rectangle(px-8*k,py-6*k,px+8*k,py+2*k,false);
        draw_set_colour(make_colour_rgb(223,159,188));draw_triangle(px-8*k,py-6*k,px,py-10*k,px+8*k,py-6*k,false);
        draw_set_colour(make_colour_rgb(250,219,233));draw_rectangle(px-8*k,py-6*k,px+8*k,py-4*k,false);
        draw_rectangle(px-3*k,py-12*k,px+3*k,py-10*k,true);
        triage_cross(px,py-1.5*k,3*k,fade);
        // Remaining lifetime shrinks along the case seam; a beacon rises above it.
        draw_set_alpha(fade);draw_set_colour(make_colour_rgb(255,202,226));
        draw_line_width(px-7*k,py+4*k,px-7*k+14*k*_tower.kit_left/_tower.definition.kit_duration,py+4*k,k);
        var phase=frac(clock*0.8);triage_cross(px,py-(16+phase*9)*z,2.5*z,sin(phase*pi)*0.7*fade);
    }
    draw_set_alpha(1);
}
function triage_draw_charge(_tower) {
    if(_tower.charge_mode!=TowerChargeState.Charging) return;
    var z=obj_camera.zoom;var p=tower_charge_progress(_tower);var clock=_tower.idle_time;
    var pose=triage_pose(clock,_tower.recoil,_tower.aim_blend,_tower.charge_pose);
    var palm=wanderer_point(_tower.x,tower_visual_y(_tower),pose.support[0],pose.support[1],pose.support[2],_tower.facing,z);
    for(var i=0;i<14;++i) {
        var t=frac(clock*0.85+i/14);var a=i*137.5+clock*80;var r=(1-t)*(18+p*10)*z;
        triage_cross(palm[0]+dcos(a)*r,palm[1]+dsin(a)*r*0.55,(1+t*1.8)*z,sin(t*pi)*0.65);
    }
    draw_set_colour(make_colour_rgb(255,221,237));draw_set_alpha(0.4+p*0.5);
    var r=(3+p*4+sin(clock*8))*z;
    draw_ellipse(palm[0]-r,palm[1]-r,palm[0]+r,palm[1]+r,true);
    triage_cross(palm[0],palm[1],(2+p*2)*z,0.9);draw_set_alpha(1);
}
function triage_draw_dart(_tower) {
    if(_tower.beam<=0) return;
    var z=obj_camera.zoom;var t=clamp(1-_tower.beam/_tower.shot_fx_duration,0,1);
    var muzzle=triage_muzzle(_tower.x,tower_visual_y(_tower),_tower.facing,_tower.idle_time,_tower.recoil,_tower.aim_blend,_tower.charge_pose,0,z);
    var tx=project_x(_tower.beam_world_x,_tower.beam_world_y);var ty=project_y(_tower.beam_world_x,_tower.beam_world_y)-20*z;
    var p=min(1,t*2.5);var tail=max(0,p-0.13);var px=lerp(muzzle[0],tx,p);var py=lerp(muzzle[1],ty,p);
    draw_set_alpha(1-t);draw_set_colour(make_colour_rgb(251,123,185));
    draw_line_width(lerp(muzzle[0],tx,max(0,p-0.4)),lerp(muzzle[1],ty,max(0,p-0.4)),px,py,2.5*z);
    draw_set_colour(make_colour_rgb(255,227,239));draw_line_width(lerp(muzzle[0],tx,tail),lerp(muzzle[1],ty,tail),px,py,1.2*z);
    if(t<0.4) triage_cross(muzzle[0],muzzle[1],(1-t/0.4)*4*z,1-t/0.4);
    draw_set_alpha(1);
}
function triage_draw_tourniquet(_enemy) {
    var z=obj_camera.zoom;var clock=obj_world.elapsed;var px=project_x(_enemy.world_x,_enemy.world_y);var py=project_y(_enemy.world_x,_enemy.world_y)-20*z;
    // Two counter-winding bandages with a pulsing medical seal.
    for(var band=0;band<2;++band) {
        draw_set_colour(band==0 ? make_colour_rgb(249,137,192) : make_colour_rgb(255,207,229));draw_set_alpha(0.65);
        for(var i=0;i<18;++i) {
            var a=i*20+clock*(band==0 ? 65 : -55);var b=a+16;
            draw_line_width(px+dcos(a)*12*z,py+dsin(a)*4*z+(band*8-4)*z,px+dcos(b)*12*z,py+dsin(b)*4*z+(band*8-4)*z,1.3*z);
        }
    }
    triage_cross(px-16*z,py-10*z,(2.6+sin(clock*5)*0.4)*z,0.85);draw_set_alpha(1);
}
function triage_draw_shield(_tower) {
    if(_tower.shield_hp<=0) return;
    var z=obj_camera.zoom;var p=clamp(_tower.shield_hp/(_tower.max_hit_points*0.3),0,1);
    var px=_tower.x;var py=tower_visual_y(_tower)-22*z;
    draw_set_alpha(p*0.5);draw_set_colour(make_colour_rgb(255,166,210));
    var points=[[-19,-13],[0,-24],[19,-13],[16,14],[0,24],[-16,14]];
    for(var i=0;i<6;++i) {var a=points[i];var b=points[(i+1) mod 6];
        draw_line_width(px+a[0]*z,py+a[1]*z,px+b[0]*z,py+b[1]*z,1.3*z);}
    draw_set_alpha(1);
}
function triage_draw_move(_tower) {
    var z=obj_camera.zoom;var p=tower_move_progress(_tower);
    for(var i=0;i<16;++i) {
        var t=i/16;var wx=lerp(_tower.move_from_x,_tower.world_x,t);var wy=lerp(_tower.move_from_y,_tower.world_y,t);
        var px=project_x(wx,wy);var py=project_y(wx,wy)-sin(t*pi)*15*z;
        var flutter=sin(i*1.7+p*12)*4*z;
        if(i mod 3==0) triage_cross(px,py+flutter,(1+t*2)*z,t*(1-p)*0.7);
        else {draw_set_colour(make_colour_rgb(239,151,194));draw_set_alpha(t*(1-p)*0.5);
            draw_line_width(px,py+flutter,px-8*z,py+flutter+2*z,2*z);}
    }
    draw_set_alpha(1);
}
// Source is captured before a marked enemy disappears; destination follows its tower.
function draw_heal_arc(_effect) {
    var t=clamp(_effect.age/_effect.lifetime,0,1);var z=obj_camera.zoom;
    var tx=_effect.target_x;var ty=_effect.target_y;
    var end_height=22;
    if(instance_exists(_effect.fx_owner)) {
        tx=_effect.fx_owner.world_x;ty=_effect.fx_owner.world_y;
        end_height+=(project_y(tx,ty)-tower_visual_y(_effect.fx_owner))/z;
    }
    var sx=project_x(_effect.world_x,_effect.world_y);
    var sy=project_y(_effect.world_x,_effect.world_y)-_effect.source_height*z;
    var ex=project_x(tx,ty);var ey=project_y(tx,ty)-end_height*z;
    var lift=clamp(sqrt((ex-sx)*(ex-sx)+(ey-sy)*(ey-sy))*0.3,24*z,70*z);
    // Staggered motes follow a lifted parabola, with short luminous trails.
    for(var i=0;i<12;++i) {
        var p=t*1.5-i*0.04;
        if(p<0 || p>1) continue;
        var tail=max(0,p-0.055);
        var flutter=sin(p*pi)*dsin(i*137)*3*z;
        var px=lerp(sx,ex,p)+flutter;var py=lerp(sy,ey,p)-4*lift*p*(1-p);
        var qx=lerp(sx,ex,tail);var qy=lerp(sy,ey,tail)-4*lift*tail*(1-tail);
        draw_set_alpha(min(1,(1-p)*6)*0.85);
        draw_set_colour(make_colour_rgb(65,224,119));
        draw_line_width(qx,qy,px,py,1.5*z);
        draw_set_colour(make_colour_rgb(173,255,193));
        var r=(i mod 3==0 ? 1.8 : 1.1)*z;
        draw_ellipse(px-r,py-r,px+r,py+r,false);
    }
    draw_set_alpha(1);
}
function triage_draw_event(_effect) {
    var t=clamp(_effect.age/_effect.lifetime,0,1);var fade=1-t;var z=obj_camera.zoom;var style=_effect.fx_style;
    var wx=_effect.world_x;var wy=_effect.world_y;
    if(instance_exists(_effect.fx_owner)) {wx=_effect.fx_owner.world_x;wy=_effect.fx_owner.world_y;}
    var px=project_x(wx,wy);var py=project_y(wx,wy);
    if(style=="release" || style=="kit" || style=="land" || style=="expire") {
        var r=_effect.fx_radius*(style=="release" ? (1-power(1-t,3)) : 0.35+t*0.45);
        triage_draw_field(wx,wy,r,fade*0.85);
        if(style=="release") triage_draw_field(wx,wy,r*0.94,fade*0.5,0,t*25);
        for(var i=0;i<8;++i) {var a=i*45;var ex=project_x(wx+dcos(a)*r,wy+dsin(a)*r);var ey=project_y(wx+dcos(a)*r,wy+dsin(a)*r);
            triage_cross(ex,ey-t*15*z,(1.5+fade)*z,fade*0.65);}
    } else if(style=="heal" || style=="shield" || style=="protect" || style=="absorb" || style=="break") {
        var count=style=="heal" ? 7 : 10;
        for(var i=0;i<count;++i) {
            var a=i*360/count+t*100;var r=(style=="break" ? 15+t*20 : 12+sin(t*pi)*5)*z;
            var ex=px+dcos(a)*r;var ey=py-(12+t*30)*z+dsin(a)*r*0.4;
            if(style=="heal") {
                draw_set_colour(make_colour_rgb(100,245,148));draw_set_alpha(fade);
                var size=(2+sin(t*pi))*z;
                draw_line_width(ex-size,ey,ex+size,ey,z);
                draw_line_width(ex,ey-size,ex,ey+size,z);
            }
            else {draw_set_colour(make_colour_rgb(255,182,217));draw_set_alpha(fade);
                draw_line_width(ex,ey,ex+dcos(a)*6*z,ey+dsin(a)*6*z,1.5*z);}
        }
        if(style=="protect") triage_cross(px,py-40*z,7*z,fade);
    } else {
        py-=20*z;
        var consume=style=="consume";var r=(consume ? 20*fade : 2+t*(style=="kill" ? 30 : 14))*z;
        draw_set_colour(make_colour_rgb(255,155,202));draw_set_alpha(fade);
        draw_ellipse(px-r,py-r*0.6,px+r,py+r*0.6,true);
        for(var i=0;i<8;++i) {var a=i*45+t*45;var ex=px+dcos(a)*r;var ey=py+dsin(a)*r*0.7;
            if(style=="mark" || consume) triage_cross(ex,ey,2*z,fade);
            else {draw_set_alpha(fade);draw_set_colour(make_colour_rgb(255,195,223));draw_line_width(ex,ey,ex+dcos(a)*4*fade*z,ey+dsin(a)*4*fade*z,z);}}
    }
    draw_set_alpha(1);
}
function singularity_ring(_wx,_wy,_radius,_alpha,_height=0) {
    draw_set_colour(make_colour_rgb(182,125,249));draw_set_alpha(clamp(_alpha,0,1));
    for(var i=0;i<64;++i) {
        var a=i*360/64;var b=(i+1)*360/64;
        draw_line_width(project_x(_wx+dcos(a)*_radius,_wy+dsin(a)*_radius),project_y(_wx+dcos(a)*_radius,_wy+dsin(a)*_radius)-_height*obj_camera.zoom,
            project_x(_wx+dcos(b)*_radius,_wy+dsin(b)*_radius),project_y(_wx+dcos(b)*_radius,_wy+dsin(b)*_radius)-_height*obj_camera.zoom,1.5*obj_camera.zoom);
    }
    draw_set_alpha(1);
}
function singularity_draw_orbit(_tower,_front) {
    var z=obj_camera.zoom;var r=_tower.definition.debris_radius;
    for(var i=0;i<array_length(_tower.debris);++i) {
        var piece=_tower.debris[i];var wx=_tower.world_x+dcos(piece.angle)*r;var wy=_tower.world_y+dsin(piece.angle)*r;
        var px=project_x(wx,wy);var py=project_y(wx,wy)-20*z;
        if((py>=_tower.y-20*z)!=_front) continue;
        var fade=min(1,piece.left*2);var faces=[];
        for(var tail=1;tail<=5;++tail) {
            var a=piece.angle-tail*5;
            var tx=project_x(_tower.world_x+dcos(a)*r,_tower.world_y+dsin(a)*r);
            var ty=project_y(_tower.world_x+dcos(a)*r,_tower.world_y+dsin(a)*r)-20*z;
            draw_set_colour(make_colour_rgb(163,98,234));draw_set_alpha(fade*(1-tail/6)*0.3);
            draw_line_width(tx,ty,px,py,2*z);
        }
        draw_set_alpha(fade);
        singularity_shard(faces,0,0,-16,7,10,make_colour_rgb(174,128,219),px,py,piece.angle*2,z);
        array_sort(faces,function(_a,_b){return sign(_a.sort_depth-_b.sort_depth);});
        for(var f=0;f<array_length(faces);++f) {var face=faces[f];draw_set_colour(face.colour);draw_primitive_begin(pr_trianglefan);
            for(var k=0;k<array_length(face.points);++k) draw_vertex(face.points[k][0],face.points[k][1]);draw_primitive_end();}
    }
    draw_set_alpha(1);
}
function singularity_draw_charge(_tower) {
    var charging=_tower.charge_mode==TowerChargeState.Charging;var windup=_tower.pulse_left>0;
    if(!charging && !windup && _tower.density<=0 && _tower.skill_release<=0) return;
    var z=obj_camera.zoom;var clock=_tower.idle_time;
    var p=windup ? 1-_tower.pulse_left/_tower.definition.pulse_windup : 0;
    var skill=charging ? tower_charge_progress(_tower) : 0;
    var pose=singularity_pose(clock,p,_tower.pulse_fx/_tower.definition.pulse_recovery,skill,_tower.skill_release/0.8);
    var centre=singularity_muzzle(_tower.x,tower_visual_y(_tower),_tower.facing,clock,0,0,0,0,z);
    if(windup) {
        var hand=pose.right;var hole=wanderer_point(_tower.x,tower_visual_y(_tower),hand[0],hand[1],hand[2]+14*(1-pose.slam),_tower.facing,z);
        var size=(3+pose.lift*9)*(1-pose.slam*0.25)*z;
        for(var i=0;i<12;++i) {
            var phase=frac(clock*1.2+i/12);var a=i*137.5+clock*35;var radius=(1-phase)*27*z;
            draw_set_colour(make_colour_rgb(190,137,244));draw_set_alpha(sin(phase*pi)*0.45);
            draw_line_width(hole[0]+dcos(a)*radius,hole[1]+dsin(a)*radius,hole[0]+dcos(a)*radius*0.82,hole[1]+dsin(a)*radius*0.82,z);
        }
        singularity_draw_hole(hole[0],hole[1],size,clock);
        if(pose.slam>0) {
            draw_set_alpha(pose.slam*0.5);draw_set_colour(make_colour_rgb(183,130,247));
            draw_line_width(hole[0],hole[1]-22*z,hole[0],hole[1],4*z);
        }
    }
    if(charging || _tower.skill_release>0) {
        // Event Horizon is a two-handed compression ritual, distinct from the overhead slam.
        var gather=charging ? skill : 1;var release=_tower.skill_release/0.8;
        var centre=wanderer_point(_tower.x,tower_visual_y(_tower),0,23,80+pose.bob,_tower.facing,z);
        var hole_size=charging ? 8*tower_pose_ease(skill/0.35) : 8*(1-tower_pose_ease((1-release)/0.4));
        if(hole_size>0.01) singularity_draw_hole(centre[0],centre[1],hole_size*z,clock,true);
        for(var i=0;i<18;++i) {
            var phase=frac(clock*0.8+i/18);var a=i*20+clock*70;var r=(14+(1-phase)*(28-gather*13))*z;
            draw_set_alpha(sin(phase*pi)*0.7*pose.ritual);diamond(centre[0]+dcos(a)*r,centre[1]+dsin(a)*r,1.5*z,3*z,make_colour_rgb(205,174,253));
        }
        singularity_ring(_tower.world_x,_tower.world_y,_tower.attack_range*(1-gather*0.82),(0.4+gather*0.3)*pose.ritual);
    }
    for(var i=0;i<min(6,_tower.density);++i) {
        var a=clock*35+i*60;draw_set_alpha(0.8);
        diamond(centre[0]+dcos(a)*15*z,centre[1]+dsin(a)*9*z,2*z,3*z,make_colour_rgb(230,202,255));
    }
    draw_set_alpha(1);
}
function singularity_draw_event(_effect) {
    var t=clamp(_effect.age/_effect.lifetime,0,1);var fade=1-t;var z=obj_camera.zoom;
    var horizon=_effect.fx_style=="horizon";var pulse=_effect.fx_style=="pulse";
    var radius=_effect.fx_radius*(horizon ? fade : 1-power(1-t,3));
    singularity_ring(_effect.world_x,_effect.world_y,radius,fade*0.9,pulse ? 2 : 0);
    if(pulse || horizon) singularity_ring(_effect.world_x,_effect.world_y,radius*0.9,fade*0.55,6*fade);
    var px=project_x(_effect.world_x,_effect.world_y);var py=project_y(_effect.world_x,_effect.world_y);
    if(pulse) {
        // Brief contact flash, expanding ground cracks, then heavy falling mineral chips.
        if(t<0.16) {draw_set_alpha((1-t/0.16)*0.85);draw_set_colour(make_colour_rgb(228,207,255));
            draw_ellipse(px-20*z,py-7*z,px+20*z,py+7*z,false);}
        for(var i=0;i<16;++i) {
            var a=i*137.5;var r=_effect.fx_radius*(0.16+t*0.62);
            var ex=project_x(_effect.world_x+dcos(a)*r,_effect.world_y+dsin(a)*r);
            var ey=project_y(_effect.world_x+dcos(a)*r,_effect.world_y+dsin(a)*r);
            draw_set_colour(make_colour_rgb(136,95,180));draw_set_alpha(fade*0.75);
            draw_line_width(px+(ex-px)*0.4,py+(ey-py)*0.4,ex,ey,1.3*z);
            var lift=sin(t*pi)*(7+(i mod 4)*5)*z;
            diamond(ex,ey-lift,(2+i mod 3)*fade*z,(3+i mod 2)*fade*z,make_colour_rgb(150,114,186));
        }
    } else {
        for(var i=0;i<12;++i) {
            var a=i*30+t*90;var r=(horizon ? fade*32 : t*22)*z;
            draw_set_alpha(fade*0.7);draw_set_colour(make_colour_rgb(203,168,254));
            draw_line_width(px+dcos(a)*r,py-25*z+dsin(a)*r,px+dcos(a)*(r+5*z),py-25*z+dsin(a)*(r+5*z),z);
        }
    }
    draw_set_alpha(1);
}
function draw_singularity_icon(_x,_y,_size,_kind) {
    var purple=make_colour_rgb(193,151,250);var light=make_colour_rgb(233,213,255);
    if(_kind==0) {
        diamond(_x-_size*0.6,_y+_size*0.1,_size*0.28,_size*0.6,purple);
        diamond(_x+_size*0.4,_y-_size*0.25,_size*0.4,_size*0.72,light);
        diamond(_x+_size*0.65,_y+_size*0.55,_size*0.25,_size*0.28,purple);
    } else {
        draw_set_colour(purple);draw_ellipse(_x-_size,_y-_size*0.5,_x+_size,_y+_size*0.5,true);
        draw_set_colour(make_colour_rgb(12,8,20));draw_ellipse(_x-_size*0.47,_y-_size*0.47,_x+_size*0.47,_y+_size*0.47,false);
        draw_set_colour(light);draw_ellipse(_x-_size*0.47,_y-_size*0.47,_x+_size*0.47,_y+_size*0.47,true);
    }
}
function singularity_draw_hole(_x,_y,_radius,_time,_vertical=false) {
    draw_set_alpha(0.14);draw_set_colour(make_colour_rgb(144,70,223));
    draw_ellipse(_x-_radius*1.45,_y-_radius*1.45,_x+_radius*1.45,_y+_radius*1.45,false);
    draw_set_alpha(1);draw_set_colour(make_colour_rgb(5,3,10));
    draw_ellipse(_x-_radius,_y-_radius,_x+_radius,_y+_radius,false);
    draw_set_colour(make_colour_rgb(202,159,255));
    for(var i=0;i<28;++i) {
        var a=i*360/28+_time*95;var b=a+9;
        var ax=dcos(a)*_radius*1.3;var ay=dsin(a)*_radius*0.32;
        var bx=dcos(b)*_radius*1.3;var by=dsin(b)*_radius*0.32;
        draw_line_width(_x+(_vertical ? ay : ax),_y+(_vertical ? ax : ay),_x+(_vertical ? by : bx),_y+(_vertical ? bx : by),max(1,_radius*0.09));
    }
    draw_set_alpha(1);
}
function singularity_draw_portal(_tower,_front) {
    var p=1-_tower.summon_left/_tower.definition.summon_duration;var z=obj_camera.zoom;
    var opening=clamp(p/0.16,0,1)*(1-clamp((p-0.86)/0.14,0,1));var radius=(27+sin(p*pi)*5)*z*opening;
    var px=_tower.x;var py=_tower.y;
    if(!_front) {
        draw_set_alpha(0.9);draw_set_colour(make_colour_rgb(5,3,12));draw_ellipse(px-radius,py-radius*0.43,px+radius,py+radius*0.43,false);
        draw_set_alpha(0.2);draw_set_colour(make_colour_rgb(168,92,243));draw_ellipse(px-radius*1.2,py-radius*0.55,px+radius*1.2,py+radius*0.55,false);
    }
    draw_set_colour(make_colour_rgb(194,131,255));draw_set_alpha(opening*0.85);
    for(var i=0;i<32;++i) {
        var a=i*360/32;var b=a+9;
        if((dsin(a)>=0)!=_front) continue;
        draw_line_width(px+dcos(a)*radius,py+dsin(a)*radius*0.43,px+dcos(b)*radius,py+dsin(b)*radius*0.43,2*z);
    }
    if(_front) for(var i=0;i<9;++i) {
        var a=i*137.5+_tower.idle_time*40;var phase=frac(p*2+i/9);var r=(20+phase*12)*z*opening;
        draw_set_alpha(sin(phase*pi)*opening*0.6);diamond(px+dcos(a)*r,py+dsin(a)*r*0.4-phase*18*z,2*z,3*z,make_colour_rgb(174,127,218));
    }
    draw_set_alpha(1);
}
