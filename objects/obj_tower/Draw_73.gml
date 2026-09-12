if(definition.key=="singularity" && summon_left>0) exit;
if(!relocating || move_active) {
    tower_draw_attack_fx(id);
    tower_draw_charge_fx(id);
}
// A compact shared frame: thin charge above health, shield appended inside HP.
var progress=tower_charge_progress(id);
if(charge_mode==TowerChargeState.Ready) progress=charge_lockout>0 ? 1-charge_lockout/charge_reuse_delay : charge_ready_blend;
var bar_scale=clamp(obj_camera.zoom,0.85,1.2);
var width=36*bar_scale;var hp_height=4*bar_scale;
var head_height=definition.key=="wanderer" ? lerp(46,55,aim_blend) : (definition.key=="triage" ? 52 : 47);
if(definition.key=="singularity") head_height=pulse_left>0 ? 72 : 54;
var bx=x-width*0.5;var hp_y=tower_visual_y(id)-head_height*obj_camera.zoom;
var charge_y=hp_y-4*bar_scale;
var shield=max(0,shield_hp);
var capacity=max_hit_points+shield;
var hp_width=width*clamp(hit_points,0,max_hit_points)/capacity;
var shield_width=width*shield/capacity;
draw_set_alpha(0.9);
draw_set_colour(make_colour_rgb(25,32,35));
draw_rectangle(bx-bar_scale,charge_y-bar_scale,bx+width+bar_scale,hp_y+hp_height+bar_scale,false);
draw_set_alpha(1);
draw_set_colour(make_colour_rgb(52,62,62));
draw_rectangle(bx,charge_y,bx+width,charge_y+2*bar_scale,false);
draw_rectangle(bx,hp_y,bx+width,hp_y+hp_height,false);
if(progress>0) {
    draw_set_colour(make_colour_rgb(179,161,112));
    draw_rectangle(bx,charge_y,bx+width*clamp(progress,0,1),charge_y+2*bar_scale,false);
}
// Damage trails sit behind live health and its appended shield segment.
var trail_width=width*(clamp(max(display_hit_points,hit_points),0,max_hit_points)+shield)/capacity;
if(display_hit_points>hit_points) {
    draw_set_colour(make_colour_rgb(133,143,142));
    draw_rectangle(bx,hp_y,bx+trail_width,hp_y+hp_height,false);
}
if(hp_width>0) {
    draw_set_colour(ui_health_colour(hit_points/max_hit_points));
    draw_rectangle(bx,hp_y,bx+hp_width,hp_y+hp_height,false);
}
if(shield_width>0) {
    draw_set_colour(make_colour_rgb(91,162,218));
    draw_rectangle(bx+hp_width,hp_y,bx+hp_width+shield_width,hp_y+hp_height,false);
}
draw_set_alpha(1);
triage_draw_shield(id);

if(definition.key=="singularity") singularity_draw_charge(id);
if(stun_left>0) {
    draw_set_colour(make_colour_rgb(224,191,255));draw_set_alpha(0.8);
    draw_ellipse(x-12,y-73*obj_camera.zoom,x+12,y-67*obj_camera.zoom,true);draw_set_alpha(1);
}
