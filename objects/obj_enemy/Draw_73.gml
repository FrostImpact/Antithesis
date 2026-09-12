// Draw End keeps the health indicator above other world geometry.
blank_draw_laser(id);
var left=x-16; var top=y-(enemy_definition.visual_height*enemy_definition.visual_scale+10)*obj_camera.zoom;
draw_set_alpha(1);
draw_set_colour(make_colour_rgb(28,35,44));
draw_rectangle(left-1,top-1,left+33,top+5,false);
draw_set_colour(make_colour_rgb(90,104,112));
draw_rectangle(left,top,left+32,top+4,false);
draw_set_colour(ui_health_colour(display_hit_points/max_hit_points));
draw_rectangle(left,top,left+32*clamp(display_hit_points/max_hit_points,0,1),top+4,false);
draw_set_alpha(1);

if(tourniquet_heal>0) {
    draw_set_colour(make_colour_rgb(113,207,212));
    draw_circle(x-23*obj_camera.zoom,y-32*obj_camera.zoom,3*obj_camera.zoom,true);
}
