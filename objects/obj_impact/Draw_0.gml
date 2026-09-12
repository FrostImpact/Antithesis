if(effect_kind=="singularity") { singularity_draw_event(id); exit; }
if(effect_kind=="heal_arc") { draw_heal_arc(id); exit; }
if(effect_kind=="triage") { triage_draw_event(id); exit; }
if(effect_kind=="vigil") {
    var t=clamp(age/lifetime,0,1);
    var z=obj_camera.zoom;
    var lift=(1-power(1-t,3))*22+sin(t*pi)*12;
    var px=project_x(world_x,world_y);
    var py=project_y(world_x,world_y)-max(60,58*z)-lift*z;
    var pop=0.7+0.3*min(1,t/0.12)+sin(min(1,t/0.35)*pi)*0.22;
    draw_set_alpha(1-power(clamp((t-0.4)/0.6,0,1),2));
    draw_vigil_icon(px-5*z,py,9*z*pop);
    draw_set_colour(make_colour_rgb(225,249,176));
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_text_transformed(px+7*z,py,"+"+string(popup_stacks),0.8*z*pop,0.8*z*pop,0);
    draw_set_alpha(1); draw_set_valign(fa_top);
    exit;
}
if(effect_kind=="text") {
    var t=clamp(age/lifetime,0,1);
    var lift=(1-power(1-t,3))*17+sin(t*pi)*7;
    var px=project_x(world_x,world_y)+(popup_status ? 0 : (popup_lane-1)*9);
    var py=project_y(world_x,world_y)-44-(popup_status ? 20 : 8)-lift;
    draw_set_halign(fa_center); draw_set_valign(fa_bottom);
    draw_set_alpha(1-clamp((t-0.3)/0.7,0,1));
    draw_set_colour(c_black);draw_text(px+1,py+1,popup_text);
    draw_set_colour(popup_status ? make_colour_rgb(205,226,176) : make_colour_rgb(242,243,232));
    draw_text(px,py,popup_text);
    draw_set_alpha(1);draw_set_halign(fa_left);draw_set_valign(fa_top);
    exit;
}
x=project_x(world_x,world_y); y=project_y(world_x,world_y)-20*obj_camera.zoom;
var t=clamp(age/lifetime,0,1);
var fade=(1-t)*(1-t);
var special=effect_kind=="finisher";
var accent=special ? make_colour_rgb(227,205,149) : make_colour_rgb(103,209,227);
// Brief contact flash, followed by a ring and directional debris.
if(age<0.075) {
    draw_set_alpha(1-age/0.075);
    diamond(x,y,(special ? 15 : 8)*obj_camera.zoom,(special ? 10 : 5)*obj_camera.zoom,c_white);
}
if(effect_kind!="hit") {
    draw_set_alpha(fade*0.8);
    draw_set_colour(accent);
    var radius=(1-power(1-t,3))*(special ? 38 : 24)*obj_camera.zoom;
    draw_ellipse(x-radius,y-radius*0.55,x+radius,y+radius*0.55,true);
}
for(var i=0;i<array_length(particles);++i) {
    var p=particles[i];
    var px=project_x(p.wx,p.wy); var py=project_y(p.wx,p.wy)-p.z*obj_camera.zoom;
    draw_set_alpha(fade);
    if(effect_kind=="hit" || i mod 3==0) {
        var tx=project_x(p.wx-p.vx*0.04,p.wy-p.vy*0.04);
        var ty=project_y(p.wx-p.vx*0.04,p.wy-p.vy*0.04)-p.z*obj_camera.zoom+p.vz*0.04*obj_camera.zoom;
        draw_set_colour(make_colour_rgb(47,81,97));
        draw_line_width(tx,ty,px,py,2.5);
        draw_set_colour(accent);
        draw_line_width(tx,ty,px,py,1.2);
    } else {
        var size=p.size*(1-t*0.6)*obj_camera.zoom;
        draw_set_colour(i mod 2==0 ? accent : make_colour_rgb(76,96,109));
        draw_triangle(px+dcos(p.rotation)*size,py+dsin(p.rotation)*size,
            px+dcos(p.rotation+125)*size,py+dsin(p.rotation+125)*size,
            px+dcos(p.rotation+235)*size,py+dsin(p.rotation+235)*size,false);
    }
}
draw_set_alpha(1);
