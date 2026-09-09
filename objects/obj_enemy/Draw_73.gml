// Draw End keeps the health indicator above other world geometry.
var left=x-16; var top=y-44;
draw_set_alpha(1);
draw_set_colour(make_colour_rgb(28,35,44));
draw_rectangle(left-1,top-1,left+33,top+5,false);
draw_set_colour(make_colour_rgb(90,104,112));
draw_rectangle(left,top,left+32,top+4,false);
draw_set_colour(make_colour_rgb(132,220,234));
draw_rectangle(left,top,left+32*clamp(display_hit_points/max_hit_points,0,1),top+4,false);
draw_set_colour(make_colour_rgb(231,238,233));
draw_rectangle(left,top,left+32*clamp(hit_points/max_hit_points,0,1),top+4,false);
