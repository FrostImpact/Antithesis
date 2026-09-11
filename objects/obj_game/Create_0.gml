config=build_game_config();
ui_theme=build_ui_theme();
glossary_catalog=build_glossary_catalog();
tower_catalog=build_tower_catalog();
selected_tower=noone;
paused=false;
display_set_gui_size(config.gui_width,config.gui_height);

build_tower_type="vestral";
enemy_catalog=build_enemy_catalog();
blank_initialize_catalog();
encounter_settings={wave_break:4};
loadout_initialize();

