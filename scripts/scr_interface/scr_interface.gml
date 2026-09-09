// Drawing and input share the animated panel origin and control rectangles.
function ui_panel_y() { return obj_ui.panel_top+(1-clamp(obj_ui.panel_open,0,1))*16; }
function ui_control_rect(_control) {
    switch(_control) {
        case 0: return [14,212,190,246];
        case 1: return [200,212,360,246];
        case 2: return [14,256,360,290];
        case 3: return [380,0,590,34];
        case 4: return [380,44,590,78];
        case 5: return [380,88,590,122];
    }
    return [0,0,0,0];
}
function ui_spawn_hovered() {
    if(!instance_exists(obj_ui)) return false;
    return point_in_rectangle(device_mouse_x_to_gui(0),device_mouse_y_to_gui(0),
        obj_ui.spawn_left,obj_ui.spawn_top,obj_ui.spawn_left+obj_ui.spawn_width,obj_ui.spawn_top+obj_ui.spawn_height);
}
function ui_pointer_blocked() {
    if(!instance_exists(obj_ui)) return false;
    if(ui_spawn_hovered()) return true;
    if(!instance_exists(obj_game.selected_tower)) return false;
    var mx=device_mouse_x_to_gui(0); var my=device_mouse_y_to_gui(0);
    return point_in_rectangle(mx,my,obj_ui.panel_left,ui_panel_y(),
        obj_ui.panel_left+obj_ui.panel_width,ui_panel_y()+obj_ui.panel_height);
}
function ui_action_at_pointer() {
    if(ui_spawn_hovered()) return 7;
    if(!instance_exists(obj_game.selected_tower)) return -1;
    var mx=device_mouse_x_to_gui(0)-obj_ui.panel_left;
    var my=device_mouse_y_to_gui(0)-ui_panel_y();
    for(var control=0;control<6;++control) {
        var bounds=ui_control_rect(control);
        if(point_in_rectangle(mx,my,bounds[0],bounds[1],bounds[2],bounds[3])) return control;
    }
    return -1;
}
// Starred terms have explicit hit regions so their glossary cards never depend
// on approximate automatic wrapping.
function ui_term_at_pointer() {
    if(!instance_exists(obj_ui) || !instance_exists(obj_game.selected_tower)) return -1;
    var mx=device_mouse_x_to_gui(0)-obj_ui.panel_left;
    var my=device_mouse_y_to_gui(0)-ui_panel_y();
    var quote_term_x=14+string_width("“A survivor of ");
    if(point_in_rectangle(mx,my,quote_term_x,40,quote_term_x+string_width("great powers"),65)) return 0;
    var tab=obj_game.selected_tower.ability_tab;
    if(!obj_game.selected_tower.ability_detail_open) return -1;
    var lock_term_x=620+string_width("Upon reaching maximum stacks, the enemy is inflicted with ");
    if(tab==1 && (point_in_rectangle(mx,my,lock_term_x,110,lock_term_x+string_width("Lock"),135) ||
        point_in_rectangle(mx,my,620,138,620+string_width("Lock"),163))) return 2;
    var charge_term_x=620+string_width("For every attack that would have been performed during ");
    if(tab==2 && point_in_rectangle(mx,my,charge_term_x,50,charge_term_x+string_width("Charge"),75)) return 1;
    return -1;
}
function ui_handle_input() {
    if(!mouse_check_button_pressed(mb_left)) return;
    var action=ui_action_at_pointer();
    if(action<0) return;
    obj_ui.press_control=action; obj_ui.press_pulse=1;
    if(action==7) {
        if(!obj_game.paused) instance_create_depth(0,0,0,obj_enemy,{enemy_type:"heavy"});
        return;
    }
    var tower=obj_game.selected_tower;
    if(action>=3 && action<=5) {
        var requested_tab=action-3;
        if(tower.ability_detail_open && tower.ability_tab==requested_tab) {
            tower.ability_detail_open=false;
        } else {
            tower.ability_tab=requested_tab;
            tower.ability_detail_open=true;
        }
        obj_ui.detail_blend=0;
        return;
    }
    if(action==0) { tower.target_mode=(tower.target_mode+1) mod 3; tower.select_pulse=0.5; }
    if(action==1) tower_request_charge(tower);
    if(action==2) {
        if(tower.relocating) tower_cancel_move();
        else tower_request_move(tower);
    }
}
function ui_draw_button(_control,_label,_enabled,_active=false) {
    var r=ui_control_rect(_control);
    var px=obj_ui.panel_left; var py=ui_panel_y();
    var hover=obj_ui.button_hover[_control];
    var press=obj_ui.press_control==_control ? obj_ui.press_pulse : 0;
    var inset=press*1.5;
    var accent=make_colour_rgb(132,220,234);
    var base=merge_colour(make_colour_rgb(15,23,32),make_colour_rgb(28,61,72),_active ? 1 : hover*0.7);
    draw_set_colour(base);
    draw_rectangle(px+r[0]+inset,py+r[1]+inset,px+r[2]-inset,py+r[3]-inset,false);
    draw_set_colour(merge_colour(make_colour_rgb(57,79,91),accent,hover*0.6+(_active ? 0.4 : 0)));
    draw_rectangle(px+r[0]+inset,py+r[1]+inset,px+r[2]-inset,py+r[3]-inset,true);
    draw_set_colour(_enabled ? (_active ? accent : c_white) : make_colour_rgb(117,137,150));
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_text(px+(r[0]+r[2])/2,py+(r[1]+r[3])/2+press,_label);
    draw_set_halign(fa_left); draw_set_valign(fa_top);
}
function ui_draw_stat(_x,_y,_label,_value) {
    draw_set_colour(make_colour_rgb(137,155,167));
    draw_text(_x,_y,_label);
    draw_set_colour(make_colour_rgb(235,244,247));
    draw_text_transformed(_x,_y+20,_value,1.25,1.25,0);
}
function ui_draw_world_feedback() {
    with(obj_tower) {
        // Hover previews range; an open tower panel keeps the full range visible.
        var visibility=max(hover_amount,selection_amount);
        if(visibility>=0.01) {
            var radius=attack_range*(0.82+0.18*visibility);
            var accent=make_colour_rgb(139,216,232);
            draw_set_alpha(visibility*0.035);
            draw_set_colour(accent);
            draw_primitive_begin(pr_trianglefan);
            draw_vertex(x,y);
            for(var i=0;i<=96;++i) {
                var a=i/96*360;
                draw_vertex(project_x(world_x+dcos(a)*radius,world_y+dsin(a)*radius),
                    project_y(world_x+dcos(a)*radius,world_y+dsin(a)*radius));
            }
            draw_primitive_end();
            draw_set_alpha(visibility*0.8);
            draw_range(world_x,world_y,radius);
        }
        // Selection uses small corner brackets, not an attack-range circle.
        if(selection_amount>0.01) {
            draw_set_alpha(selection_amount);
            draw_set_colour(c_white);
            var span=15+select_pulse*5;
            for(var side=-1;side<=1;side+=2) {
                draw_line_width(x+side*span,y+4,x+side*span,y-2,1.5);
                draw_line_width(x+side*span,y+4,x+side*(span-5),y+4,1.5);
            }
        }
    }
    draw_set_alpha(1);
}
