if(relocating && !move_active) exit;
tower_draw_attack_fx(id);
tower_draw_charge_fx(id);
// Charge fills over time, then drains by remaining rounds / original burst size.
var progress=tower_charge_progress(id);
var bx=x-18; var by=y-47;
draw_set_alpha(charge_mode==TowerChargeState.Ready ? 0.55 : 1);
draw_set_colour(obj_game.ui_theme.surface);
draw_rectangle(bx-1,by-1,bx+37,by+6,false);
draw_set_colour(obj_game.ui_theme.bar_back);
draw_rectangle(bx,by,bx+36,by+5,false);
if(progress>0) {
    draw_set_colour(obj_game.ui_theme.bar_fill);
    draw_rectangle(bx,by,bx+36*clamp(progress,0,1),by+5,false);
}
draw_set_alpha(1);
