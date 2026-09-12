// 48 baked hover frames per void fragment; no walking rig or facing rows.
// A single shared sprite draw includes the fixed ground shadow.
function blank_initialize_catalog() {
    obj_game.enemy_catalog.intrusion.atlas=spr_blank_husk;
    obj_game.enemy_catalog.fast.atlas=spr_blank_wisp;
    obj_game.enemy_catalog.heavy.atlas=spr_blank_hulk;
}

function blank_draw_model(_e) {
    if(_e.enemy_definition.model=="lancer") { blank_draw_lancer(_e); return; }
    var frame=floor(_e.drift_phase*48/(pi*2)) mod 48;
    var column=frame mod 12;
    var row=floor(frame/12);
    var scale=obj_camera.zoom*_e.enemy_definition.visual_scale/1.25;
    var presence=clamp(1-_e.spawn_left/_e.enemy_definition.spawn_duration,0,1);
    var emerge=1-power(1-presence,3);
    var impact=sin(clamp(_e.hit_flash/0.15,0,1)*pi)*0.055;
    var sx=scale*(0.45+emerge*0.55)*(1+impact);
    var sy=scale*(0.12+emerge*0.88)*(1-impact);
    var left=_e.x-40*sx;
    var top=_e.y-104*sy;
    draw_sprite_part_ext(_e.enemy_definition.atlas,0,column*80,row*120,80,120,
        left,top,sx,sy,c_white,emerge);
    // Only a struck enemy needs a second submission. Additive tint preserves
    // the same silhouette and does not require a second set of baked assets.
    if(_e.hit_flash>0) {
        gpu_set_blendmode(bm_add);
        draw_sprite_part_ext(_e.enemy_definition.atlas,0,column*80,row*120,80,120,
            left,top,sx,sy,c_white,clamp(_e.hit_flash/0.15,0,1)*0.5*emerge);
        gpu_set_blendmode(bm_normal);
    }
}

// Four suspended blades frame a coral lens; no additional atlas is needed.
function blank_draw_lancer(_e) {
    var z=obj_camera.zoom*_e.enemy_definition.visual_scale;
    var presence=clamp(1-_e.spawn_left/_e.enemy_definition.spawn_duration,0,1);
    var cy=_e.y-(30+sin(_e.drift_phase)*3)*z;
    var opening=_e.laser_state=="aiming" ? 1-_e.laser_clock/_e.enemy_definition.laser_windup : 0;
    var spread=(7+opening*5)*z;
    var coral=make_colour_rgb(242,126,116);
    draw_set_alpha(presence*0.24);draw_set_colour(c_black);
    draw_ellipse(_e.x-16*z,_e.y-5*z,_e.x+16*z,_e.y+5*z,false);
    draw_set_alpha(presence);
    diamond(_e.x,cy,9*z,14*z,make_colour_rgb(22,28,34));
    for(var side=-1;side<=1;side+=2) {
        draw_set_colour(make_colour_rgb(191,194,189));
        draw_triangle(_e.x+side*spread,cy-3*z,_e.x+side*5*z,cy-28*z,_e.x+side*18*z,cy-10*z,false);
        draw_set_colour(make_colour_rgb(112,124,127));
        draw_triangle(_e.x+side*spread,cy+3*z,_e.x+side*4*z,cy+22*z,_e.x+side*15*z,cy+9*z,false);
    }
    diamond(_e.x,cy,4*z,7*z,_e.hit_flash>0 ? c_white : coral);
    draw_set_colour(coral);
    draw_ellipse(_e.x-12*z,cy-12*z,_e.x+12*z,cy+12*z,true);
    draw_set_alpha(1);
}

function blank_draw_laser(_e) {
    if(_e.enemy_definition.model!="lancer" || _e.laser_state=="walking" || _e.spawn_left>0) return;
    var z=obj_camera.zoom;
    var sx=_e.x; var sy=_e.y-(30+sin(_e.drift_phase)*3)*z*_e.enemy_definition.visual_scale;
    var tx=project_x(_e.laser_world_x,_e.laser_world_y);
    var ty=project_y(_e.laser_world_x,_e.laser_world_y);
    var coral=make_colour_rgb(242,126,116);
    if(_e.laser_state=="aiming") {
        var p=clamp(1-_e.laser_clock/_e.enemy_definition.laser_windup,0,1);
        draw_set_alpha(0.35+p*0.55);draw_set_colour(coral);
        for(var dash=0;dash<12;++dash) {
            var t=dash/12;
            draw_line_width(lerp(sx,tx,t),lerp(sy,ty-20*z,t),lerp(sx,tx,t+0.04),lerp(sy,ty-20*z,t+0.04),z);
        }
        var radius=(24-10*p)*z;
        draw_ellipse(tx-radius,ty-radius*0.5,tx+radius,ty+radius*0.5,true);
        draw_line_width(tx-5*z,ty,tx+5*z,ty,z);
        draw_line_width(tx,ty-3*z,tx,ty+3*z,z);
    } else {
        var fade=clamp(_e.laser_clock/_e.enemy_definition.laser_duration,0,1);
        draw_set_alpha(fade*0.24);draw_set_colour(coral);
        draw_line_width(sx,sy,tx,ty-20*z,10*z);
        draw_set_alpha(fade);draw_line_width(sx,sy,tx,ty-20*z,3*z);
        draw_set_colour(c_white);draw_line_width(sx,sy,tx,ty-20*z,z);
        diamond(tx,ty-20*z,7*z*fade,12*z*fade,coral);
    }
    draw_set_alpha(1);
}

function blank_draw_spawn_fx(_e) {
    if(_e.spawn_left<=0) return;
    var p=clamp(1-_e.spawn_left/_e.enemy_definition.spawn_duration,0,1);
    var z=obj_camera.zoom;
    var radius=(8+sin(p*pi)*17)*z;
    draw_set_alpha(sin(p*pi)*0.8);
    draw_set_colour(make_colour_rgb(160,222,217));
    draw_ellipse(_e.x-radius,_e.y-radius*0.36,_e.x+radius,_e.y+radius*0.36,true);
    // Shards converge upward from a small ground breach into the emerging body.
    for(var shard=0;shard<6;++shard) {
        var a=shard*60+p*120;
        var spread=(1-p)*24*z;
        var px=_e.x+dcos(a)*spread;
        var py=_e.y+dsin(a)*spread*0.4-p*28*z;
        diamond(px,py,(1-p)*3*z,(1-p)*5*z,make_colour_rgb(214,237,224));
    }
    draw_set_alpha(1);
}

function blank_draw_shock_fx(_e) {
    if(_e.shock_left<=0 || _e.shock_stacks<=0 || _e.spawn_left>0) return;
    var z=obj_camera.zoom*_e.enemy_definition.visual_scale;
    var pulse=floor(_e.elapsed*24);
    var strength=0.45+0.55*_e.shock_stacks/8;
    var fade=min(1,_e.shock_left/0.08);
    // Two brief, rapidly changing zigzags hug the shell, distinct from Lock chains.
    for(var arc=0;arc<2;++arc) {
        var side=arc==0 ? -1 : 1;
        var cx=_e.x+side*(5+sin(pulse*2.3+arc)*3)*z;
        var cy=_e.y-(24+sin(pulse*1.7+arc*2)*9)*z;
        for(var stroke=0;stroke<2;++stroke) {
            draw_set_alpha(fade*strength*(stroke==0 ? 0.3 : 0.95));
            draw_set_colour(stroke==0 ? make_colour_rgb(44,155,207) : make_colour_rgb(171,243,255));
            var width=(stroke==0 ? 3 : 1)*obj_camera.zoom;
            for(var link=0;link<4;++link) {
                var ax=cx+sin(pulse*3+link*2.4+arc)*5*z;
                var ay=cy+(link-2)*4*z;
                var bx=cx+sin(pulse*3+(link+1)*2.4+arc)*5*z;
                draw_line_width(ax,ay,bx,ay+4*z,width);
            }
        }
    }
    draw_set_alpha(1);
}
