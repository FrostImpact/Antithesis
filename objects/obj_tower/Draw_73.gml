if(!relocating || move_active) {
    tower_draw_attack_fx(id);
    tower_draw_charge_fx(id);
}
// Charge fills over time, then drains by remaining rounds / original burst size.
var progress=tower_charge_progress(id);
if(charge_mode==TowerChargeState.Ready) progress=charge_lockout>0 ? 1-charge_lockout/charge_reuse_delay : charge_ready_blend;
var bx=x-18; var by=y-59*obj_camera.zoom;
draw_set_alpha(1);
draw_set_colour(obj_game.ui_theme.surface);
draw_rectangle(bx-1,by-1,bx+37,by+6,false);
draw_set_colour(obj_game.ui_theme.bar_back);
draw_rectangle(bx,by,bx+36,by+5,false);
if(progress>0) {
    draw_set_colour(obj_game.ui_theme.bar_fill);
    draw_rectangle(bx,by,bx+36*clamp(progress,0,1),by+5,false);
}
draw_set_alpha(1);
// Health remains visible at full health, while moving, and without selection.
{
    var hp_y=by-8;
    draw_set_colour(obj_game.ui_theme.surface);
    draw_rectangle(bx-1,hp_y-1,bx+37,hp_y+4,false);
    draw_set_colour(obj_game.ui_theme.bar_back);draw_rectangle(bx,hp_y,bx+36,hp_y+3,false);
    draw_set_colour(ui_health_colour(display_hit_points/max_hit_points));
    draw_rectangle(bx,hp_y,bx+36*clamp(display_hit_points/max_hit_points,0,1),hp_y+3,false);
}

draw_set_alpha(1);

if(shield_hp>0) {
    draw_set_colour(make_colour_rgb(208,229,235));
    draw_rectangle(bx,by-11,bx+36*clamp(shield_hp/max_hit_points,0,1),by-10,false);
}
