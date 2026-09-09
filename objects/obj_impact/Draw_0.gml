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
