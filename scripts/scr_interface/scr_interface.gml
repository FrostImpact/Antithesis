// UI drawing and input share the same module bounds. Nothing outside a drawn
// module consumes world clicks.
function ui_panel_y() {
    return obj_ui.panel_top+(1-clamp(obj_ui.panel_open,0,1))*16;
}

// One continuous lime / amber / red ramp for every health display.
function ui_health_colour(_ratio) {
    var ratio=clamp(_ratio,0,1);
    var red=make_colour_rgb(236,82,78);
    var amber=make_colour_rgb(235,189,78);
    var lime=make_colour_rgb(186,235,83);
    return ratio<0.5 ? merge_colour(red,amber,ratio*2) : merge_colour(amber,lime,(ratio-0.5)*2);
}

function ui_control_rect(_control) {
    switch(_control) {
        case UiAction.Target: return [0,212,190,246];
        case UiAction.Charge: return [200,212,360,246];
        case UiAction.Move: return [0,256,360,290];
        case UiAction.AbilityDoubleTap: return [380,0,590,34];
        case UiAction.AbilityShockBolts: return [380,44,590,78];
        case UiAction.AbilityOverloaded: return [380,88,590,122];
        case UiAction.AbilityMove: return [380,132,590,166];
    }
    return [0,0,0,0];
}

function ui_point_in_local_rect(_mx,_my,_rect) {
    return point_in_rectangle(_mx,_my,_rect[0],_rect[1],_rect[2],_rect[3]);
}

function ui_spawn_hovered() {
    if(!instance_exists(obj_ui)) return false;
    return point_in_rectangle(device_mouse_x_to_gui(0),device_mouse_y_to_gui(0),
        obj_ui.spawn_left,obj_ui.spawn_top,obj_ui.spawn_left+obj_ui.spawn_width,obj_ui.spawn_top+obj_ui.spawn_height);
}

function ui_pointer_blocked() {
    if(!instance_exists(obj_ui)) return false;
    if(loadout_pointer_blocked()) return true;
    if(ui_spawn_hovered()) return true;
    var pointer_x=device_mouse_x_to_gui(0); var pointer_y=device_mouse_y_to_gui(0);
    if(obj_ui.tooltip_rect[2]>obj_ui.tooltip_rect[0] && ui_point_in_local_rect(pointer_x,pointer_y,obj_ui.tooltip_rect)) return true;
    if(!instance_exists(obj_game.selected_tower)) return false;
    var mx=pointer_x-obj_ui.panel_left;
    var my=pointer_y-ui_panel_y();
    if(point_in_rectangle(mx,my,0,0,360,198)) return true;
    if(obj_game.selected_tower.definition.key=="wanderer" && point_in_rectangle(mx,my,0,-54,44,-10)) return true;
    for(var action=UiAction.Target;action<=UiAction.AbilityDoubleTap+array_length(obj_game.selected_tower.definition.abilities)-1;++action) {
        if(ui_point_in_local_rect(mx,my,ui_control_rect(action))) return true;
    }
    if(obj_game.selected_tower.ability_detail_open && point_in_rectangle(mx,my,604,0,1044,198)) return true;
    return false;
}

function ui_action_at_pointer() {
    if(ui_spawn_hovered()) return UiAction.Spawn;
    if(!instance_exists(obj_game.selected_tower)) return UiAction.None;
    var mx=device_mouse_x_to_gui(0)-obj_ui.panel_left;
    var my=device_mouse_y_to_gui(0)-ui_panel_y();
    for(var action=UiAction.Target;action<=UiAction.AbilityDoubleTap+array_length(obj_game.selected_tower.definition.abilities)-1;++action) {
        if(ui_point_in_local_rect(mx,my,ui_control_rect(action))) return action;
    }
    return UiAction.None;
}

function ui_register_term(_term,_left,_top,_right,_bottom) {
    if(_term==GlossaryTerm.None || !instance_exists(obj_ui)) return;
    array_push(obj_ui.term_regions,{term:_term,left:_left,top:_top,right:_right,bottom:_bottom});
}

function ui_term_at_pointer() {
    if(!instance_exists(obj_ui) || !instance_exists(obj_game.selected_tower)) return GlossaryTerm.None;
    var mx=device_mouse_x_to_gui(0); var my=device_mouse_y_to_gui(0);
    for(var i=0;i<array_length(obj_ui.term_regions);++i) {
        var region=obj_ui.term_regions[i];
        if(point_in_rectangle(mx,my,region.left,region.top,region.right,region.bottom)) return region.term;
    }
    return GlossaryTerm.None;
}

function ui_term_anchor(_term) {
    var mx=device_mouse_x_to_gui(0); var my=device_mouse_y_to_gui(0);
    var fallback=undefined;
    for(var i=0;i<array_length(obj_ui.term_regions);++i) {
        var region=obj_ui.term_regions[i];
        if(region.term!=_term) continue;
        if(is_undefined(fallback)) fallback=region;
        if(point_in_rectangle(mx,my,region.left,region.top,region.right,region.bottom)) return region;
    }
    return fallback;
}

// One wrapping algorithm serves every title card. Tagged glossary segments are
// underlined and receive exact hover bounds automatically.
function ui_draw_rich_text(_x,_y,_width,_paragraphs,_line_height,_colour) {
    var theme=obj_game.ui_theme;
    var cursor_y=_y;
    for(var paragraph_index=0;paragraph_index<array_length(_paragraphs);++paragraph_index) {
        if(paragraph_index>0) cursor_y+=5;
        var cursor_x=_x;
        var pending_space=false;
        var paragraph=_paragraphs[paragraph_index];
        for(var segment_index=0;segment_index<array_length(paragraph);++segment_index) {
            var segment=paragraph[segment_index];
            // Keep a glossary phrase together, including its spaces and underline.
            if(segment.term!=GlossaryTerm.None && string_width(segment.text)<=_width) {
                var gap=pending_space ? string_width(" ") : 0;
                var span=string_width(segment.text);
                if(cursor_x>_x && cursor_x+gap+span>_x+_width) { cursor_x=_x;cursor_y+=_line_height;gap=0; }
                cursor_x+=gap;
                draw_set_colour(_colour);draw_text(cursor_x,cursor_y,segment.text);
                var baseline=cursor_y+string_height(segment.text)+1;
                draw_set_colour(theme.underline);draw_line(cursor_x,baseline,cursor_x+span,baseline);
                ui_register_term(segment.term,cursor_x,cursor_y,cursor_x+span,baseline+2);
                cursor_x+=span;pending_space=false;
                continue;
            }
            var word="";
            var length=string_length(segment.text);
            for(var character_index=1;character_index<=length+1;++character_index) {
                var at_end=character_index>length;
                var character=at_end ? "" : string_char_at(segment.text,character_index);
                if(at_end || character==" ") {
                    if(string_length(word)>0) {
                        var space_width=pending_space ? string_width(" ") : 0;
                        var word_width=string_width(word);
                        if(cursor_x>_x && cursor_x+space_width+word_width>_x+_width) {
                            cursor_x=_x;
                            cursor_y+=_line_height;
                            space_width=0;
                        }
                        cursor_x+=space_width;
                        draw_set_colour(_colour);
                        draw_text(cursor_x,cursor_y,word);
                        if(segment.term!=GlossaryTerm.None) {
                            var text_height=string_height(word);
                            draw_set_colour(theme.underline);
                            draw_line(cursor_x,cursor_y+text_height+1,cursor_x+word_width,cursor_y+text_height+1);
                            ui_register_term(segment.term,cursor_x,cursor_y,cursor_x+word_width,cursor_y+text_height+3);
                        }
                        cursor_x+=word_width;
                        word="";
                    }
                    if(!at_end) pending_space=true;
                } else {
                    word+=character;
                }
            }
        }
        cursor_y+=_line_height;
    }
    return cursor_y;
}

function ui_stat_breakdown(_tower,_stat) {
    var d=_tower.definition;
    if(_stat==0) {
        var bonus=0;var body="Base ATK: "+string(d.damage);
        if(d.key=="wanderer") {
            var first=min(_tower.vigil_earned,d.vigil_breakpoint);
            var later=max(0,_tower.vigil_earned-d.vigil_breakpoint);
            bonus=first*d.vigil_attack+later*d.vigil_attack_reduced;
            body+="\nVigil: "+string(first)+" x "+string(d.vigil_attack)+" = +"+string(first*d.vigil_attack);
            body+="\nAfter 12: "+string(later)+" x "+string(d.vigil_attack_reduced)+" = +"+string(later*d.vigil_attack_reduced);
        }
        body+="\nOther adjustments: "+string(_tower.damage-d.damage-bonus);
        body+="\nTotal ATK: "+string(_tower.damage);
        if(d.key=="vestral") body+="\nDouble Tap: 2 hits x 50% = "+string(_tower.damage*0.5)+" per hit.";
        return {title:"ATTACK DAMAGE",body:body};
    }
    if(_stat==1) return {title:"ATTACK RATE",body:"Base: "+string_format(1/d.attack_interval,1,2)+" attacks/s\nSpeed adjustment: "+string_format((d.attack_interval/_tower.attack_interval-1)*100,1,1)+"%\nTotal: 1 / "+string_format(_tower.attack_interval,1,2)+"s = "+string_format(1/_tower.attack_interval,1,2)+" attacks/s"+(d.key=="wanderer" ? "\nVigil disables automatic attacks. Skills fire once." : (d.key=="triage" ? "\nOne dart per attack." : "\nDowntime starts after the second hit."))};
    if(_stat==2) return {title:"ATTACK RANGE",body:"Base: "+string(d.attack_range)+"\nAdjustments: "+string(_tower.attack_range-d.attack_range)+"\nTotal: "+string(_tower.attack_range)+(d.key=="wanderer" ? "\nExecution ignores range." : "")};
    if(_stat==4) return {title:"MOVEMENT SPEED",body:"Base: "+string(d.move_speed)+" tiles/s\nAdjustments: "+string(_tower.move_speed-d.move_speed)+" tiles/s\nTotal: "+string(_tower.move_speed)+" tiles/s\nTravel time = distance / MVE SPD.\nAverage speed across the eased dash.\nCombat timers pause until arrival."};
    return {title:"CHARGE TIME",body:"Base: "+string(d.charge_duration)+"s\nAdjustments: "+string(_tower.charge_duration-d.charge_duration)+"s\nTotal: "+string(_tower.charge_duration)+"s\nSkill cooldown: "+string(d.charge_reuse_delay)+"s base + "+string(_tower.charge_reuse_delay-d.charge_reuse_delay)+"s adjustment = "+string(_tower.charge_reuse_delay)+"s"};
}

function ui_handle_input() {
    if(loadout_handle_input()) return;
    if(!mouse_check_button_pressed(mb_left)) return;
    var action=ui_action_at_pointer();
    if(action==UiAction.None) return;
    obj_ui.press_control=action; obj_ui.press_pulse=1;
    if(action==UiAction.Spawn) {
        encounter_start_round();
        return;
    }
    var tower=obj_game.selected_tower;
    if(action>=UiAction.AbilityDoubleTap && action<=UiAction.AbilityDoubleTap+array_length(obj_game.selected_tower.definition.abilities)-1) {
        var requested_tab=action-UiAction.AbilityDoubleTap;
        if(tower.ability_detail_open && tower.ability_tab==requested_tab) tower.ability_detail_open=false;
        else {
            tower.ability_tab=requested_tab;
            tower.ability_detail_open=true;
        }
        obj_ui.detail_blend=0;
        return;
    }
    if(action==UiAction.Target) {
        tower.target_mode=(tower.target_mode+1) mod TowerTargetMode.Count;
        tower.select_pulse=0.5;
    }
    if(action==UiAction.Charge) tower_request_charge(tower);
    if(action==UiAction.Move) {
        if(tower.move_active) tower.reject_pulse=1;
        else if(tower.relocating) tower_cancel_move();
        else tower_request_move(tower);
    }
}

function ui_draw_button(_control,_label,_enabled,_active=false) {
    var theme=obj_game.ui_theme;
    var r=ui_control_rect(_control);
    var px=obj_ui.panel_left; var py=ui_panel_y();
    var hover=obj_ui.button_hover[_control];
    var press=obj_ui.press_control==_control ? obj_ui.press_pulse : 0;
    var inset=press*1.5;
    var base=merge_colour(theme.surface,theme.surface_hover,hover*0.8);
    if(_active) base=merge_colour(base,theme.surface_active,0.8);
    draw_set_colour(base);
    draw_rectangle(px+r[0]+inset,py+r[1]+inset,px+r[2]-inset,py+r[3]-inset,false);
    draw_set_colour(_active ? theme.accent : merge_colour(theme.border,theme.muted,hover*0.28));
    draw_rectangle(px+r[0]+inset,py+r[1]+inset,px+r[2]-inset,py+r[3]-inset,true);
    draw_set_colour(_enabled ? theme.title : theme.disabled);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_text(px+(r[0]+r[2])/2,py+(r[1]+r[3])/2+press,_label);
    draw_set_halign(fa_left); draw_set_valign(fa_top);
}

function ui_draw_surface(_left,_top,_right,_bottom) {
    var theme=obj_game.ui_theme;
    draw_set_colour(theme.shadow);
    draw_rectangle(_left+2,_top+3,_right+2,_bottom+3,false);
    draw_set_colour(theme.surface);
    draw_rectangle(_left,_top,_right,_bottom,false);
    draw_set_colour(theme.border);
    draw_rectangle(_left,_top,_right,_bottom,true);
}

function ui_draw_world_feedback() {
    with(obj_tower) {
        var visibility=max(hover_amount,selection_amount);
        if(visibility>=0.01) {
            var radius=attack_range*(0.82+0.18*visibility);
            var range_colour=make_colour_rgb(196,202,207);
            draw_set_alpha(visibility*0.035);
            draw_set_colour(range_colour);
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
        if(selection_amount>0.01) {
            draw_set_alpha(selection_amount);
            draw_set_colour(make_colour_rgb(235,237,239));
            var span=15+select_pulse*5;
            for(var side=-1;side<=1;side+=2) {
                draw_line_width(x+side*span,y+4,x+side*span,y-2,1.5);
                draw_line_width(x+side*span,y+4,x+side*(span-5),y+4,1.5);
            }
        }
    }
    draw_set_alpha(1);
}
