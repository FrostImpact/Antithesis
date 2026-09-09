// Short-lived combat effects are distinct from the static map and its range overlays.
function tower_draw_attack_fx(_tower) {
    if(_tower.beam<=0) return;
    var muzzle=_tower.definition.muzzle(_tower.x,tower_visual_y(_tower),_tower.facing,
        _tower.idle_time,_tower.recoil,_tower.aim_blend,_tower.charge_pose,_tower.recovery_left/0.5,obj_camera.zoom);
    _tower.shot_x=muzzle[0]; _tower.shot_y=muzzle[1];
    var tx=project_x(_tower.beam_world_x,_tower.beam_world_y);
    var ty=project_y(_tower.beam_world_x,_tower.beam_world_y)-20*obj_camera.zoom;
    var intensity=clamp(_tower.beam/0.12,0,1);
    var special=_tower.finisher_flash>0;
    var colour=special ? make_colour_rgb(242,216,148) : make_colour_rgb(111,218,239);
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
    if(_tower.beam>0.065) {
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
    if(_tower.charge_mode!="charging") return;
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
        draw_set_colour(make_colour_rgb(102,223,237));
        draw_line_width(px,py,px+dcos(angle)*3*obj_camera.zoom,py+dsin(angle)*2*obj_camera.zoom,1.5*obj_camera.zoom);
    }
    draw_set_alpha(progress*0.7);
    diamond(focus[0],focus[1],(2+progress*2)*obj_camera.zoom,(1.5+progress)*obj_camera.zoom,c_white);
    draw_set_alpha(1);
}


