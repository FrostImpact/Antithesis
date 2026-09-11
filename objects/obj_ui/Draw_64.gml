term_regions=[];
tooltip_rect=[0,0,0,0];
draw_set_alpha(1);
draw_set_halign(fa_left); draw_set_valign(fa_top);
var theme=obj_game.ui_theme;

draw_set_colour(theme.muted);

if(obj_game.paused) { draw_set_colour(theme.title); draw_text(30,30,"PAUSED"); }

var spawn_inset=press_control==UiAction.Spawn ? press_pulse*1.5 : 0;
draw_set_colour(merge_colour(theme.surface,theme.surface_hover,button_hover[UiAction.Spawn]));
draw_rectangle(spawn_left+spawn_inset,spawn_top+spawn_inset,spawn_left+spawn_width-spawn_inset,spawn_top+spawn_height-spawn_inset,false);
var round_waiting=obj_encounter.phase=="preparation" || obj_encounter.phase=="intermission";
var round_ready=!obj_game.paused && instance_exists(obj_tower) && round_waiting;
draw_set_colour(round_ready ? theme.border : theme.disabled);
draw_rectangle(spawn_left+spawn_inset,spawn_top+spawn_inset,spawn_left+3,spawn_top+spawn_height-spawn_inset,false);
draw_set_colour(round_ready ? theme.title : theme.disabled);
draw_text(spawn_left+14,spawn_top+8,round_waiting ? "START ROUND" : "ROUND ACTIVE");
draw_set_colour(theme.muted);
draw_set_halign(fa_right); draw_text(spawn_left+spawn_width-12,spawn_top+8,string(obj_encounter.round_number+(round_waiting ? 1 : 0))); draw_set_halign(fa_left);
draw_set_colour(theme.copy);

if(!instance_exists(obj_game.selected_tower)) { loadout_draw(); exit; }
var tower=obj_game.selected_tower;
var definition=tower.definition;
var px=panel_left; var py=ui_panel_y();

// Identity, controls, skill index and details are separate visible modules.
draw_set_alpha(panel_blend*0.97);
draw_set_colour(theme.surface);
draw_rectangle(px,py,px+360,py+198,false);
draw_set_alpha(panel_blend);
draw_set_colour(theme.border);
draw_rectangle(px,py,px+360,py+198,true);
draw_set_colour(theme.bar_fill);
draw_rectangle(px,py,px+74+sin(ui_time*2.4)*12,py+2,false);

draw_set_colour(theme.title);
draw_text_transformed(px+14,py+12,definition.name,1.22,1.22,0);
draw_set_colour(theme.copy);
draw_set_halign(fa_right); draw_text(px+346,py+15,tower_status(tower)); draw_set_halign(fa_left);

ui_draw_rich_text(px+14,py+45,332,definition.role_copy,18,theme.copy);

draw_set_colour(theme.muted);
draw_text(px+14,py+72,definition.key=="wanderer" ? "EXECUTION / SNIPER" : "CC / SUB-DPS");
if(definition.key=="wanderer") {
    draw_set_colour(theme.surface);draw_rectangle(px,py-54,px+44,py-10,false);
    draw_set_colour(make_colour_rgb(159,193,99));draw_rectangle(px,py-54,px+44,py-10,true);
    draw_vigil_icon(px+22,py-40,12);
    draw_set_colour(theme.title);draw_set_halign(fa_center);
    var count_text=string(tower.vigil);
    var count_scale=min(0.85,36/max(1,string_width(count_text)));
    draw_text_transformed(px+22,py-27,count_text,count_scale,count_scale,0);
    draw_set_halign(fa_left);
}
draw_set_colour(theme.divider);
draw_line(px+14,py+101,px+346,py+101);
var labels=["ATK","RATE","RANGE","CHARGE"];
var values=[string(tower.damage),string_format(1/tower.attack_interval,1,2),string_format(tower.attack_range,1,2),string_format(tower.charge_duration,1,1)+"s"];
if(definition.key=="wanderer") values[1]="SKILLS";
for(var stat=0;stat<4;++stat) {
    var sx=px+14+stat*84;
    draw_set_colour(theme.muted); draw_text(sx,py+116,labels[stat]);
    draw_set_colour(theme.title); draw_text(sx,py+137,values[stat]);
}
var progress=tower_charge_progress(tower);
if(tower.charge_mode==TowerChargeState.Ready && tower.charge_lockout>0) progress=1-tower.charge_lockout/tower.charge_reuse_delay;
draw_set_colour(theme.bar_back);
draw_rectangle(px+14,py+178,px+346,py+182,false);
if(progress>0) {
    draw_set_colour(theme.bar_fill);
    draw_rectangle(px+14,py+178,px+14+332*clamp(progress,0,1),py+182,false);
}

var modes=["FIRST","STRONGEST","NEAREST"];
ui_draw_button(UiAction.Target,"TARGET  "+modes[tower.target_mode],true);
var ready=tower_can_charge(tower);
var charge_label=ready ? "CHARGE" : (tower.charge_mode==TowerChargeState.Charging ? "CHARGING" : "ON COOLDOWN");
ui_draw_button(UiAction.Charge,charge_label,ready,tower.charge_mode!=TowerChargeState.Ready);
if(tower.reject_pulse>0) {
    draw_set_alpha(panel_blend*tower.reject_pulse);
    draw_set_colour(theme.danger);
    var reject_rect=ui_control_rect(UiAction.Charge);
    draw_rectangle(px+reject_rect[0],py+reject_rect[1],px+reject_rect[2],py+reject_rect[3],true);
    draw_set_alpha(panel_blend);
}
var move_label=tower.move_active ? "MOVING" : (tower.relocating ? "CANCEL MOVE" : "MOVE TOWER");
var move_enabled=!tower.move_active && (tower.relocating || (!obj_game.paused && tower.charge_mode==TowerChargeState.Ready));
ui_draw_button(UiAction.Move,move_label,move_enabled,tower.relocating);

for(var tab=0;tab<array_length(definition.abilities);++tab) {
    var ability=definition.abilities[tab];
    ui_draw_button(UiAction.AbilityDoubleTap+tab,ability.label,true,tower.ability_detail_open && tower.ability_tab==tab);
}

if(tower.ability_detail_open) {
    var ability=definition.abilities[tower.ability_tab];
    draw_set_alpha(panel_blend*detail_blend*0.97);
    draw_set_colour(theme.surface);
    draw_rectangle(px+604,py,px+1044,py+198,false);
    draw_set_colour(theme.border);
    draw_rectangle(px+604,py,px+1044,py+198,true);
    draw_set_colour(theme.bar_fill);
    draw_rectangle(px+604,py,px+662+sin(ui_time*1.8+1)*10,py+2,false);
    draw_set_alpha(panel_blend*detail_blend);
    draw_set_colour(theme.title);
    draw_text(px+620,py+16,ability.kind+": "+ability.title);
    ui_draw_rich_text(px+620,py+49,408,ability.paragraphs,18,theme.copy);
}
draw_set_alpha(panel_blend);

if(hovered_term!=GlossaryTerm.None && tooltip_blend>0.01) {
    var anchor=ui_term_anchor(hovered_term);
    if(!is_undefined(anchor)) {
        var glossary=obj_game.glossary_catalog[hovered_term];
        var tip_w=338; var tip_h=45+string_height_ext(glossary.body,16,tip_w-28);
        var tip_x=clamp((anchor.left+anchor.right-tip_w)*0.5,8,obj_game.config.gui_width-tip_w-8);
        var tip_y=max(8,anchor.top-tip_h-8);
        tooltip_rect=[tip_x,tip_y,tip_x+tip_w,tip_y+tip_h];
        draw_set_alpha(panel_blend*tooltip_blend*0.98);
        draw_set_colour(theme.surface);
        draw_rectangle(tip_x,tip_y,tip_x+tip_w,tip_y+tip_h,false);
        draw_set_colour(theme.bar_fill);
        draw_rectangle(tip_x,tip_y,tip_x+4,tip_y+tip_h,false);
        draw_set_colour(theme.border);
        draw_rectangle(tip_x,tip_y,tip_x+tip_w,tip_y+tip_h,true);
        draw_set_colour(theme.title); draw_text(tip_x+14,tip_y+9,glossary.title);
        draw_set_colour(theme.copy); draw_text_ext(tip_x+14,tip_y+31,glossary.body,16,tip_w-28);
    }
}
// Live stat calculations use the same values that combat reads.
var stat_mx=device_mouse_x_to_gui(0)-px;var stat_my=device_mouse_y_to_gui(0)-py;
if(point_in_rectangle(stat_mx,stat_my,14,110,346,164)) {
    var stat_index=clamp(floor((stat_mx-14)/84),0,3);
    var detail=ui_stat_breakdown(tower,stat_index);
    var width=340;var height=45+string_height_ext(detail.body,18,width-28);
    var sx=clamp(px+14+stat_index*84,8,obj_game.config.gui_width-width-8);
    var sy=max(8,py-height-12);
    draw_set_alpha(panel_blend*0.98);draw_set_colour(theme.surface);
    draw_rectangle(sx,sy,sx+width,sy+height,false);
    draw_set_colour(theme.border);draw_rectangle(sx,sy,sx+width,sy+height,true);
    draw_set_colour(theme.title);draw_text(sx+14,sy+9,detail.title);
    draw_set_colour(theme.copy);draw_text_ext(sx+14,sy+31,detail.body,18,width-28);
}
draw_set_alpha(1);
loadout_draw();
