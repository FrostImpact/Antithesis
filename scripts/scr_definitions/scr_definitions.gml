function build_game_config() {
    return {charge_key:ord("C"),pause_key:ord("P"),restart_key:ord("R"),
        drag_threshold:6,zoom_step:0.1,zoom_min:0.72,zoom_max:1.28,
        gui_width:1366,gui_height:768,
        map_editor_origin_x:128,map_editor_origin_y:96,map_editor_grid:64};
}

function ui_segment(_text,_term=GlossaryTerm.None) {
    return {text:_text,term:_term};
}

function build_ui_theme() {
    return {
        surface:make_colour_rgb(27,30,34),
        surface_hover:make_colour_rgb(43,47,52),
        surface_active:make_colour_rgb(57,62,68),
        border:make_colour_rgb(105,112,120),
        divider:make_colour_rgb(70,75,81),
        title:make_colour_rgb(238,240,242),
        copy:make_colour_rgb(211,215,219),
        muted:make_colour_rgb(157,164,171),
        disabled:make_colour_rgb(112,118,124),
        underline:make_colour_rgb(184,190,196),
        danger:make_colour_rgb(203,132,124),
        bar_back:make_colour_rgb(54,59,64),
        bar_fill:make_colour_rgb(177,183,189)
    };
}

function build_glossary_catalog() {
    var catalog=array_create(GlossaryTerm.Count);
    catalog[GlossaryTerm.GreatPowers]={title:"GREAT POWERS",body:"Forces beyond ordinary human limits. Vestral survived their influence."};
    catalog[GlossaryTerm.Charge]={title:"CHARGE",body:"A windup mechanic that every tower can interact with uniquely."};
    catalog[GlossaryTerm.Lock]={title:"LOCK",body:"Roots the victim in place."};
    return catalog;
}

function build_tower_catalog() {
    return {vestral:{key:"vestral",name:"VESTRAL",role:"A survivor of great powers",
        description:"A survivor of great powers",
        damage:20,attack_range:2.65,attack_interval:0.8,charge_duration:3.2,
        burst_interval:0.09,charge_reuse_delay:6,
        hits_per_attack:2,shot_interval:0.09,hit_multiplier:0.5,
        shock_per_stack:0.05,shock_max_stacks:8,shock_duration:0.4,lock_duration:0.8,
        role_copy:[[ui_segment("“A survivor of "),ui_segment("great powers",GlossaryTerm.GreatPowers),ui_segment("”")]],
        abilities:[
            {id:TowerAbility.DoubleTap,label:"DOUBLE TAP",kind:"PASSIVE",title:"Double Tap",paragraphs:[
                [ui_segment("Basic Attacks fire twice, each dealing 50% of ATK.")]
            ]},
            {id:TowerAbility.ShockBolts,label:"SHOCK BOLTS",kind:"PASSIVE",title:"Shock Bolts",paragraphs:[
                [ui_segment("Basic Attacks slow enemies for 5%, lasting for 0.4s.")],
                [ui_segment("This effect will refresh if reapplied and can stack (40% max, caps at 8 stacks).")],
                [ui_segment("Upon reaching maximum stacks, the enemy is inflicted with "),ui_segment("Lock",GlossaryTerm.Lock),ui_segment(" for 0.8s.")]
            ]},
            {id:TowerAbility.Overloaded,label:"OVERLOADED",kind:"CHARGE SKILL",title:"Overloaded",paragraphs:[
                [ui_segment("For every attack that would have been performed during "),ui_segment("Charge",GlossaryTerm.Charge),ui_segment(", instead, release it at the end of charge with a low delay between shots.")]
            ]}
        ],
        draw_model:draw_defender,muzzle:defender_muzzle
    },wanderer:{key:"wanderer",name:"WANDERER",role:"The patient hunter",
        description:"The patient hunter",damage:60,attack_range:3.4,attack_interval:1,
        charge_duration:1.5,charge_reuse_delay:8,burst_interval:0.09,
        hits_per_attack:1,shot_interval:0.2,hit_multiplier:1,
        vigil_damage_step:25,vigil_attack:2,vigil_attack_reduced:0.5,vigil_breakpoint:12,
        role_copy:[[ui_segment("“The patient hunter”")]],
        abilities:[
            {id:0,label:"VIGIL",kind:"PASSIVE",title:"Vigil",paragraphs:[[ui_segment("WANDERER does not attack normally.")]]},
            {id:1,label:"MARK OF THE HUNTER",kind:"PASSIVE",title:"Mark of the Hunter",paragraphs:[
                [ui_segment("Basic Attacks execute enemies below 3.5% HP, before or after the hit.")],
                [ui_segment("Kills grant 1 Vigil per 25 damage dealt (rounded up, 1–4). Each grants permanent +2 ATK; after 12 earned, +0.5 ATK instead.")]]},
            {id:2,label:"EXECUTION",kind:"CHARGE SKILL",title:"Execution",paragraphs:[
                [ui_segment("Charge for 1.5s, then fire at any range using targeting priority. Kills reset its 8s cooldown.")],
                [ui_segment("Spends 1 available Vigil. Usable at zero; permanent ATK is retained.")]]},
            {id:3,label:"SKILLED SNIPER",kind:"MOVE SKILL",title:"Skilled Sniper",paragraphs:[
                [ui_segment("After moving, instantly perform a Basic Attack at a target in range.")],
                [ui_segment("Spends 1 available Vigil on arrival, even without a target. Usable at zero; permanent ATK is retained.")]]}
        ],draw_model:draw_wanderer,muzzle:wanderer_muzzle
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

