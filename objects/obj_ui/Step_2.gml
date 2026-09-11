var dt=min(delta_time/1000000,0.05);
ui_time+=dt;
loadout_tick(dt);
if(!instance_exists(obj_game.selected_tower)) obj_game.selected_tower=noone;
panel_blend=lerp(panel_blend,instance_exists(obj_game.selected_tower) ? 1 : 0,1-exp(-14*dt));
var open_goal=instance_exists(obj_game.selected_tower) ? 1 : 0;
// Damped panel motion and eased hover feedback, inspired by Overshot v.2 dossiers.
panel_velocity+=(open_goal-panel_open)*180*dt;
panel_velocity*=exp(-22*dt);
panel_open+=panel_velocity*dt;
detail_blend=lerp(detail_blend,1,1-exp(-18*dt));
hovered_term=ui_term_at_pointer();
tooltip_blend=lerp(tooltip_blend,hovered_term>=0 ? 1 : 0,1-exp(-18*dt));
press_pulse=max(0,press_pulse-dt*6);
var hovered_control=ui_action_at_pointer();
for(var control=0;control<UiAction.Count;++control) button_hover[control]=lerp(button_hover[control],hovered_control==control ? 1 : 0,1-exp(-16*dt));
with(obj_tower) {
    hover_amount=lerp(hover_amount,obj_input.hovered_tower==id ? 1 : 0,1-exp(-10*dt));
    selection_amount=lerp(selection_amount,obj_game.selected_tower==id ? 1 : 0,1-exp(-12*dt));
    select_pulse=max(0,select_pulse-dt*3);
    reject_pulse=max(0,reject_pulse-dt*3);
}

var next_cursor=(ui_action_at_pointer()>=0 || hovered_term>=0 || loadout_pointer_blocked() || instance_exists(obj_input.hovered_tower)) ? cr_handpoint : cr_default;
if(next_cursor!=active_cursor) { window_set_cursor(next_cursor); active_cursor=next_cursor; }



