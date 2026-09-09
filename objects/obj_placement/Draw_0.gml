if(ui_pointer_blocked()) exit;
var colour=valid ? make_colour_rgb(114,228,239) : make_colour_rgb(219,118,109);
draw_set_alpha(0.75);
draw_set_colour(colour);
var span=(16+reject_flash*5)*obj_camera.zoom;
draw_ellipse(x-span,y-span*0.45,x+span,y+span*0.45,true);
draw_set_alpha(valid ? 0.6 : 0.25);
var definition=instance_exists(moving_tower) ? moving_tower.definition : tower_definition(obj_game.build_tower_type);
definition.draw_model(x,y,300,0,0,0,0,0,obj_camera.zoom);
draw_set_alpha(1);
if(!valid) {
    draw_set_colour(colour);
    draw_line(x-7,y-4,x+7,y+4);
    draw_line(x+7,y-4,x-7,y+4);
}
