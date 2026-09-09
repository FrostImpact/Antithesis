if (obj_game.paused || !instance_exists(obj_tower)) exit;
// One enemy at a time, automatically repeated after a short quiet interval.
if (instance_exists(obj_enemy)) { countdown=obj_game.encounter_settings.spawn_delay; exit; }
countdown-=min(delta_time/1000000,0.05);
if (countdown<=0) {
    instance_create_depth(0,0,0,obj_enemy);
    countdown=obj_game.encounter_settings.spawn_delay;
}


