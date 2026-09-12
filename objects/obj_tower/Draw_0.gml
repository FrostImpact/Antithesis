if(definition.key=="singularity" && summon_left>0) singularity_draw_portal(id,false);
if(definition.key=="singularity") singularity_draw_orbit(id,false);
// A short settling bounce gives placement weight without moving the footprint.
tower_draw_move_fx(id);
draw_set_alpha(relocating ? 0.25 : 1);
if(definition.key=="triage") draw_triage(x,tower_visual_y(id),facing,idle_time+(move_active ? move_elapsed : 0),recoil,aim_blend,charge_pose,recovery_left/0.5,obj_camera.zoom,move_active ? sin(tower_move_progress(id)*pi) : 0);
else if(definition.key=="singularity") singularity_draw_actor(id);
else definition.draw_model(x,tower_visual_y(id),facing,idle_time,recoil,aim_blend,charge_pose,recovery_left/0.5,obj_camera.zoom);
draw_set_alpha(1);
if(hover_amount>0.01 && !relocating) {
    gpu_set_blendmode(bm_add);
    draw_set_alpha(hover_amount*0.16);
    if(definition.key=="triage") draw_triage(x,tower_visual_y(id),facing,idle_time+(move_active ? move_elapsed : 0),recoil,aim_blend,charge_pose,recovery_left/0.5,obj_camera.zoom,move_active ? sin(tower_move_progress(id)*pi) : 0);
else if(definition.key=="singularity") singularity_draw_actor(id);
else definition.draw_model(x,tower_visual_y(id),facing,idle_time,recoil,aim_blend,charge_pose,recovery_left/0.5,obj_camera.zoom);
    draw_set_alpha(1); gpu_set_blendmode(bm_normal);
}
if (settle>0 && definition.key!="singularity") {
    draw_set_colour(definition.key=="triage" ? make_colour_rgb(246,143,191) : make_colour_rgb(110,117,111));
    draw_set_alpha(settle*0.45);
    var radius=(1-settle)*15+9;
    draw_ellipse(x-radius,y-radius*0.45,x+radius,y+radius*0.45,true);
    draw_set_alpha(1);
}






if(definition.key=="singularity") singularity_draw_orbit(id,true);

if(definition.key=="singularity" && summon_left>0) singularity_draw_portal(id,true);
