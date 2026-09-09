function build_game_config() {
    return {charge_key:ord("C"),pause_key:ord("P"),restart_key:ord("R"),
        drag_threshold:6,zoom_step:0.1,zoom_min:0.72,zoom_max:1.28,
        gui_width:1366,gui_height:768};
}
function build_tower_catalog() {
    return {vestral:{key:"vestral",name:"VESTRAL",role:"A survivor of great powers",
        description:"A survivor of great powers",
        damage:20,attack_range:2.65,attack_interval:0.8,charge_duration:3.2,
        burst_interval:0.09,charge_reuse_delay:6,
        hits_per_attack:2,hit_multiplier:0.5,
        shock_per_stack:0.05,shock_max_stacks:8,shock_duration:0.4,lock_duration:0.8,
        draw_model:draw_defender,muzzle:defender_muzzle
    }};
}
function tower_definition(_key) {
    if(!variable_struct_exists(obj_game.tower_catalog,_key)) show_error("Unknown tower definition: "+_key,true);
    return variable_struct_get(obj_game.tower_catalog,_key);
}
function game_select_tower(_tower) {
    var selection_changed=obj_game.selected_tower!=_tower;
    if(selection_changed && instance_exists(obj_ui)) {
        obj_ui.panel_open=0; obj_ui.panel_velocity=0; obj_ui.detail_blend=0; obj_ui.tooltip_blend=0;
    }
    obj_game.selected_tower=_tower;
    if(instance_exists(_tower)) {
        _tower.select_pulse=1;
        if(selection_changed) _tower.ability_detail_open=false;
    }
}


function build_enemy_catalog() {
    return {intrusion:{max_hit_points:100,move_speed:0.8},
        heavy:{max_hit_points:300,move_speed:0.4}};
}


