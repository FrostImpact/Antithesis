// A short settling bounce gives placement weight without moving the footprint.
draw_set_alpha(relocating ? 0.25 : 1);
definition.draw_model(x,tower_visual_y(id),facing,idle_time,recoil,aim_blend,charge_pose,recovery_left/0.5,obj_camera.zoom);
draw_set_alpha(1);
if(hover_amount>0.01 && !relocating) {
    gpu_set_blendmode(bm_add);
    draw_set_alpha(hover_amount*0.16);
    definition.draw_model(x,tower_visual_y(id),facing,idle_time,recoil,aim_blend,charge_pose,recovery_left/0.5,obj_camera.zoom);
    draw_set_alpha(1); gpu_set_blendmode(bm_normal);
}
if (settle>0) {
    draw_set_colour(make_colour_rgb(110,117,111));
    draw_set_alpha(settle*0.45);
    var radius=(1-settle)*15+9;
    draw_ellipse(x-radius,y-radius*0.45,x+radius,y+radius*0.45,true);
    draw_set_alpha(1);
}





