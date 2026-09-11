// Resolve clicks before placement/combat Step events. Pointer movement never orbits.
clicked_tower=noone;
clicked_ground=false;
if(mouse_check_button_pressed(mb_left) && !ui_pointer_blocked()) {
    pointer_down=true; dragging=false;
    press_x=mouse_x; press_y=mouse_y; last_drag_x=mouse_x;
    pressed_tower=noone;
    var closest=-100000;
    for(var i=0;i<instance_number(obj_tower);++i) {
        var tower=instance_find(obj_tower,i);
        if(mouse_x>=tower.x-20 && mouse_x<=tower.x+20 && mouse_y>=tower.y-40 && mouse_y<=tower.y+5 && tower.y>closest) {
            pressed_tower=tower; closest=tower.y;
        }
    }
}
if(pointer_down && mouse_check_button(mb_left)) {
    if(point_distance(mouse_x,mouse_y,press_x,press_y)>obj_game.config.drag_threshold) dragging=true;
    last_drag_x=mouse_x;
}
if(pointer_down && mouse_check_button_released(mb_left)) {
    if(point_distance(mouse_x,mouse_y,press_x,press_y)>obj_game.config.drag_threshold) dragging=true;
    if(!dragging) {
        if(instance_exists(pressed_tower)) {
            if(mouse_x>=pressed_tower.x-20 && mouse_x<=pressed_tower.x+20 && mouse_y>=pressed_tower.y-40 && mouse_y<=pressed_tower.y+5) clicked_tower=pressed_tower;
        } else clicked_ground=true;
    }
    pointer_down=false; dragging=false;
}


camera_sync_actors();
if(mouse_wheel_up()) obj_camera.target_zoom=min(obj_game.config.zoom_max,obj_camera.target_zoom+obj_game.config.zoom_step);
if(mouse_wheel_down()) obj_camera.target_zoom=max(obj_game.config.zoom_min,obj_camera.target_zoom-obj_game.config.zoom_step);
hovered_tower=noone;
if(!dragging && !ui_pointer_blocked()) {
    var closest=-100000;
    for(var i=0;i<instance_number(obj_tower);++i) {
        var tower=instance_find(obj_tower,i);
        if(mouse_x>=tower.x-20 && mouse_x<=tower.x+20 && mouse_y>=tower.y-43 && mouse_y<=tower.y+5 && tower.y>closest) {
            hovered_tower=tower; closest=tower.y;
        }
    }
}
if(instance_exists(obj_placement) && instance_exists(obj_placement.moving_tower)) {
    if(instance_exists(clicked_tower)) { clicked_ground=true; clicked_tower=noone; }
}
if(instance_exists(clicked_tower)) game_select_tower(clicked_tower);
else if(clicked_ground && !instance_exists(obj_placement)) game_select_tower(noone);
if(keyboard_check_pressed(vk_escape)) { obj_game.loadout.selected=-1; if(!tower_cancel_move()) game_select_tower(noone); }
if(mouse_check_button_pressed(mb_right)) tower_cancel_move();
if(keyboard_check_pressed(obj_game.config.restart_key)) { room_restart(); exit; }
if(keyboard_check_pressed(obj_game.config.pause_key)) obj_game.paused=!obj_game.paused;
if(keyboard_check_pressed(obj_game.config.charge_key)) tower_request_charge(obj_game.selected_tower);
ui_handle_input();


// Only equipped, owned copies can start a placement preview.
for(var slot=0;slot<5;++slot) if(keyboard_check_pressed(ord("1")+slot)) loadout_select(slot);
