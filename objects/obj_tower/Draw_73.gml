if(relocating) exit;
tower_draw_attack_fx(id);
tower_draw_charge_fx(id);
// Charge fills over time, then drains by remaining rounds / original burst size.
var progress=tower_charge_progress(id);
var bx=x-18; var by=y-47;
draw_set_alpha(charge_mode=="ready" ? 0.55 : 1);
draw_set_colour(make_colour_rgb(28,35,44));
draw_rectangle(bx-1,by-1,bx+37,by+6,false);
draw_set_colour(make_colour_rgb(92,112,125));
draw_rectangle(bx,by,bx+36,by+5,false);
if(progress>0) {
    draw_set_colour(make_colour_rgb(114,228,239));
    draw_rectangle(bx,by,bx+36*clamp(progress,0,1),by+5,false);
}
draw_set_alpha(1);
