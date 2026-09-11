// Round state is owned by the encounter manager. Completing its last wave
// deposits randomized cards and Bits into the independent loadout inventory.
function encounter_initialize() {
    phase="preparation";
    round_number=0;
    wave_index=0;
    waves=[];
    spawn_index=0;
    spawn_left=0;
    break_left=0;
    round_escaped=0;
    total_escaped=0;
    round_spawned=0;
    round_total=0;
}

function encounter_build_round(_round) {
    var result=[];
    // Each round introduces pressure through composition before raw stats.
    for(var wave=0;wave<3;++wave) {
        var roster=[];
        var count=5+wave*2+min(15,(_round-1)*2);
        for(var slot=0;slot<count;++slot) {
            var kind="intrusion";
            if(wave==1) kind=slot mod 3==0 ? "intrusion" : "fast";
            if(wave==2) kind=slot mod 4==0 ? "heavy" : (slot mod 2==0 ? "fast" : "intrusion");
            if(_round>=3 && wave==0 && slot mod 5==4) kind="heavy";
            array_push(roster,kind);
        }
        array_push(result,{enemies:roster,interval:max(0.45,1.3-wave*0.15-min(0.5,(_round-1)*0.04)),
            health_scale:1+(_round-1)*0.16});
    }
    return result;
}

function encounter_start_round() {
    if(obj_game.paused || !instance_exists(obj_tower)) return false;
    if(obj_encounter.phase!="preparation" && obj_encounter.phase!="intermission") return false;
    obj_encounter.round_number+=1;
    obj_encounter.waves=encounter_build_round(obj_encounter.round_number);
    obj_encounter.wave_index=0;
    obj_encounter.spawn_index=0;
    obj_encounter.spawn_left=0;
    obj_encounter.round_escaped=0;
    obj_encounter.round_spawned=0;
    obj_encounter.round_total=0;
    for(var i=0;i<array_length(obj_encounter.waves);++i)
        obj_encounter.round_total+=array_length(obj_encounter.waves[i].enemies);
    obj_encounter.phase="wave";
    return true;
}

function encounter_tick(_dt) {
    if(obj_game.paused) return;
    if(phase=="wave_break") {
        break_left=max(0,break_left-_dt);
        if(break_left>0) return;
        wave_index+=1;
        spawn_index=0;
        spawn_left=0;
        phase="wave";
    }
    if(phase!="wave") return;
    var wave=waves[wave_index];
    spawn_left-=_dt;
    while(spawn_index<array_length(wave.enemies) && spawn_left<=0) {
        instance_create_depth(0,0,0,obj_enemy,{enemy_type:wave.enemies[spawn_index],health_scale:wave.health_scale});
        spawn_index+=1;
        round_spawned+=1;
        spawn_left+=wave.interval;
    }
    // An empty lane between spawn times is not a completed wave.
    if(spawn_index<array_length(wave.enemies) || instance_exists(obj_enemy)) return;
    if(wave_index+1<array_length(waves)) {
        phase="wave_break";
        break_left=obj_game.encounter_settings.wave_break;
    } else {
        phase="intermission";
        loadout_round_reward(round_number);
    }
}

function encounter_record_escape() {
    obj_encounter.round_escaped+=1;
    obj_encounter.total_escaped+=1;
}
