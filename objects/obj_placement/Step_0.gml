var ground=unproject(mouse_x,mouse_y);
world_x=ground[0]; world_y=ground[1];
x=project_x(world_x,world_y); y=project_y(world_x,world_y); depth=-y;
reject_flash=max(0,reject_flash-min(delta_time/1000000,0.05)*4);
valid=placement_is_valid(world_x,world_y,moving_tower) && !ui_pointer_blocked();
if(obj_input.clicked_ground && !ui_pointer_blocked() && !obj_game.paused) {
    if(!valid) { reject_flash=1; exit; }
    if(instance_exists(moving_tower)) {
        if(tower_commit_move(moving_tower,world_x,world_y)) instance_destroy();
    } else {
        var placed=instance_create_depth(x,y,-y,obj_tower,{world_x:world_x,world_y:world_y,tower_type:obj_game.build_tower_type});
        game_select_tower(placed);
        obj_encounter.countdown=1;
        instance_destroy();
    }
}
