draw_set_alpha(1);
draw_set_halign(fa_left); draw_set_valign(fa_top);
draw_set_colour(make_colour_rgb(157,175,189));
if(instance_exists(obj_placement)) {
    var moving=instance_exists(obj_placement.moving_tower);
    draw_text(30,118,moving ? "Choose open ground / Right-click or ESC to cancel" : "Click open ground to place Vestral");
}
if(obj_game.paused) { draw_set_colour(c_white); draw_text(30,30,"PAUSED"); }

var spawn_inset=press_control==7 ? press_pulse*1.5 : 0;
draw_set_colour(merge_colour(make_colour_rgb(14,22,31),make_colour_rgb(29,63,74),button_hover[7]));
draw_rectangle(spawn_left+spawn_inset,spawn_top+spawn_inset,spawn_left+spawn_width-spawn_inset,spawn_top+spawn_height-spawn_inset,false);
draw_set_colour(obj_game.paused ? make_colour_rgb(111,130,143) : make_colour_rgb(132,220,234));
draw_rectangle(spawn_left+spawn_inset,spawn_top+spawn_inset,spawn_left+3,spawn_top+spawn_height-spawn_inset,false);
draw_set_colour(obj_game.paused ? make_colour_rgb(144,166,181) : c_white);
draw_text(spawn_left+14,spawn_top+8,"SPAWN HEAVY");
draw_set_colour(make_colour_rgb(125,146,159));
draw_set_halign(fa_right); draw_text(spawn_left+spawn_width-12,spawn_top+8,"300 HP"); draw_set_halign(fa_left);

if(!instance_exists(obj_game.selected_tower)) exit;
var tower=obj_game.selected_tower;
var px=panel_left; var py=ui_panel_y();
var accent=make_colour_rgb(47,69,82);
var muted=make_colour_rgb(123,145,159);
var card=make_colour_rgb(14,22,31);
var border=make_colour_rgb(47,69,82);
var copy=make_colour_rgb(201,214,220);

// The identity card, vertical skill stack and optional detail card are separate
// modules. No invisible outer panel forces unrelated information together.
draw_set_alpha(panel_blend*0.96);
draw_set_colour(card);
draw_rectangle(px,py,px+360,py+198,false);
draw_set_alpha(panel_blend);
draw_set_colour(border);
draw_rectangle(px,py,px+360,py+198,true);
draw_set_colour(accent);
draw_rectangle(px,py,px+74+sin(ui_time*2.4)*12,py+2,false);

draw_set_colour(c_white);
draw_text_transformed(px+14,py+12,"VESTRAL",1.22,1.22,0);
draw_set_colour(accent);
draw_set_halign(fa_right); draw_text(px+346,py+15,tower_status(tower)); draw_set_halign(fa_left);

// Underlined glossary term: great powers.
var quote_x=px+14; var quote_y=py+45;
var quote_prefix="“A survivor of "; var quote_term="great powers";
var quote_term_x=quote_x+string_width(quote_prefix);
draw_set_colour(make_colour_rgb(218,226,229));
draw_text(quote_x,quote_y,quote_prefix);
draw_text(quote_term_x,quote_y,quote_term);
draw_text(quote_term_x+string_width(quote_term),quote_y,"”");
draw_set_colour(accent);
draw_rectangle(quote_term_x,quote_y+22,quote_term_x+string_width(quote_term),quote_y+24, false);

draw_set_colour(muted);
draw_text(px+14,py+72,"CC/Sub-DPS");
draw_set_colour(make_colour_rgb(37,53,64));
draw_line(px+14,py+101,px+346,py+101);
var labels=["ATK","RATE","RANGE","CHARGE"];
var values=[string(tower.damage),string_format(1/tower.attack_interval,1,2),string_format(tower.attack_range,1,2),string_format(tower.charge_duration,1,1)+"s"];
for(var stat=0;stat<4;++stat) {
    var sx=px+14+stat*84;
    draw_set_colour(muted); draw_text(sx,py+116,labels[stat]);
    draw_set_colour(c_white); draw_text(sx,py+137,values[stat]);
}
var progress=tower_charge_progress(tower);
if(tower.charge_mode=="ready" && tower.charge_lockout>0) progress=1-tower.charge_lockout/tower.charge_reuse_delay;
draw_set_colour(make_colour_rgb(34,50,62));
draw_rectangle(px+14,py+178,px+346,py+182,false);
if(progress>0) { draw_set_colour(accent); draw_rectangle(px+14,py+178,px+14+332*progress,py+182,false); }

var modes=["FIRST","STRONGEST","NEAREST"];
ui_draw_button(0,"TARGET  "+modes[tower.target_mode],true);
var ready=tower_can_charge(tower);
ui_draw_button(1,ready ? "CHARGE" : (tower.charge_mode=="charging" ? "BANKING" : "WAIT"),ready,tower.charge_mode!="ready");
if(tower.reject_pulse>0) {
    draw_set_alpha(panel_blend*tower.reject_pulse);
    draw_set_colour(make_colour_rgb(219,118,109));
    draw_rectangle(px+200,py+212,px+360,py+246,true);
    draw_set_alpha(panel_blend);
}
ui_draw_button(2,tower.relocating ? "CANCEL MOVE" : "MOVE TOWER",tower.relocating || (!obj_game.paused && tower.charge_mode=="ready"));

// Skills form a vertical index. A detail card appears only after a click.
var tabs=["DOUBLE TAP","SHOCK BOLTS","OVERLOADED"];
for(var tab=0;tab<3;++tab)
    ui_draw_button(tab+3,tabs[tab],true,tower.ability_detail_open && tower.ability_tab==tab);

if(tower.ability_detail_open) {
    draw_set_alpha(panel_blend*detail_blend*0.96);
    draw_set_colour(card);
    draw_rectangle(px+604,py,px+1044,py+198,false);
    draw_set_colour(border);
    draw_rectangle(px+604,py,px+1044,py+198,true);
    draw_set_colour(accent);
    draw_rectangle(px+604,py,px+662+sin(ui_time*1.8+1)*10,py+2,false);
    draw_set_alpha(panel_blend*detail_blend);
    switch(tower.ability_tab) {
        case 0:
            draw_set_colour(accent); draw_text(px+620,py+16,"Passive: Double Tap");
            draw_set_colour(copy); draw_text_ext(px+620,py+62,"Basic Attacks fire twice, each dealing 50% ATK.",18,408);
            break;
        case 1:
            draw_set_colour(accent); draw_text(px+620,py+16,"Passive: Shock Bolts");
            draw_set_colour(copy);
            draw_text_ext(px+620,py+48,"Basic Attacks slow enemies for 5%, lasting for 0.4s.",17,408);
            draw_text_ext(px+620,py+72,"This effect will refresh if reapplied and can stack (40% max, caps at 8 stacks).",17,408);
            var lock_prefix="Upon reaching maximum stacks, the enemy is inflicted with ";
            var lock_x=px+620+string_width(lock_prefix);
            draw_text(px+620,py+116,lock_prefix);
            draw_text(lock_x,py+116,"Lock");
            draw_text(lock_x+string_width("Lock"),py+116," for 0.8s.");
            draw_set_colour(accent); draw_line(lock_x,py+132,lock_x+string_width("Lock"),py+132);
            draw_set_colour(copy);
            draw_text(px+620,py+144,"Lock");
            draw_text(px+620+string_width("Lock"),py+144,": Roots the victim in place.");
            draw_set_colour(accent); draw_line(px+620,py+160,px+620+string_width("Lock"),py+160);
            break;
        case 2:
            draw_set_colour(accent); draw_text(px+620,py+16,"Charge Skill: Overloaded");
            draw_set_colour(copy);
            var charge_prefix="For every attack that would have been performed during ";
            var charge_x=px+620+string_width(charge_prefix);
            draw_text(px+620,py+56,charge_prefix);
            draw_text(charge_x,py+56,"Charge");
            draw_text(charge_x+string_width("Charge"),py+56,",");
            draw_set_colour(accent); draw_line(charge_x,py+72,charge_x+string_width("Charge"),py+72);
            draw_set_colour(copy);
            draw_text_ext(px+620,py+82,"instead, release it at the end of charge with a low delay between shots.",18,408);
            break;
    }
}
draw_set_alpha(panel_blend);

if(hovered_term>=0 && tooltip_blend>0.01) {
    var tooltip_text=""; var tooltip_title="";
    switch(hovered_term) {
        case 0:
            tooltip_title="GREAT POWERS";
            tooltip_text="Forces beyond ordinary human limits. Vestral survived their influence.";
            break;
        case 1:
            tooltip_title="CHARGE";
            tooltip_text="The 3.2-second wind-up before Overloaded releases its stored attacks.";
            break;
        case 2:
            tooltip_title="LOCK";
            tooltip_text="Roots the victim in place for 0.8 seconds. The victim cannot move.";
            break;
    }
    var tip_x=px+374; var tip_y=py-60;
    draw_set_alpha(panel_blend*tooltip_blend*0.97);
    draw_set_colour(make_colour_rgb(7,12,18));
    draw_rectangle(tip_x,tip_y,tip_x+670,tip_y+48,false);
    draw_set_colour(accent); draw_rectangle(tip_x,tip_y,tip_x+4,tip_y+48,false);
    draw_set_colour(make_colour_rgb(91,122,136)); draw_rectangle(tip_x,tip_y,tip_x+670,tip_y+48,true);
    draw_set_colour(accent); draw_text(tip_x+15,tip_y+8,tooltip_title);
    draw_set_colour(copy); draw_text_ext(tip_x+132,tip_y+8,tooltip_text,16,520);
}
draw_set_alpha(1);
