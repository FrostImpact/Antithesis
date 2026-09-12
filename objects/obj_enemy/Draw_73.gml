// Draw End keeps the health indicator above other world geometry.
blank_draw_laser(id);
var bar_scale=clamp(obj_camera.zoom,0.85,1.2);var width=32*bar_scale;
var left=x-width*0.5; var top=y-(enemy_definition.visual_height*enemy_definition.visual_scale+7)*obj_camera.zoom;
draw_set_alpha(1);
draw_set_colour(make_colour_rgb(25,32,35));
draw_rectangle(left-bar_scale,top-bar_scale,left+width+bar_scale,top+5*bar_scale,false);
draw_set_colour(make_colour_rgb(52,62,62));
draw_rectangle(left,top,left+width,top+4*bar_scale,false);
if(display_hit_points>hit_points) {
    draw_set_colour(make_colour_rgb(133,143,142));
    draw_rectangle(left,top,left+width*clamp(display_hit_points/max_hit_points,0,1),top+4*bar_scale,false);
}
draw_set_colour(ui_health_colour(hit_points/max_hit_points));
draw_rectangle(left,top,left+width*clamp(hit_points/max_hit_points,0,1),top+4*bar_scale,false);
draw_set_alpha(1);

if(tourniquet_heal>0) triage_draw_tourniquet(id);
