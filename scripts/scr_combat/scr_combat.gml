function tower_initialize() {
definition=tower_definition(tower_type);
attack_range=definition.attack_range;
damage=definition.damage;
hits_landed=0;
ability_tab=0;
ability_detail_open=false;
relocating=false;
cooldown=0;
beam=0;
beam_x=x;
beam_y=y;
recoil=0;
settle=1;
idle_time=0;
facing=300;
turn_velocity=0;
aim_blend=0;
shot_x=x;
shot_y=y;
// Per-instance charge state and reserved attacks.
attack_interval=definition.attack_interval;
charge_duration=definition.charge_duration;
burst_interval=definition.burst_interval;
charge_reuse_delay=definition.charge_reuse_delay;
charge_mode="ready";
charge_left=0;
charge_lockout=0;
stored_shots=0;
burst_clock=0;
recovery_left=0;
charge_pose=0;
finisher_flash=0;
burst_total=0;
burst_target=noone;
beam_world_x=world_x; beam_world_y=world_y;


target_mode=0;
kills=0; damage_dealt=0; shots_fired=0;
hover_amount=0; selection_amount=0; select_pulse=0; reject_pulse=0;

}


function tower_tick() {
if (obj_game.paused || relocating) return;
var dt=min(delta_time/1000000,0.05);
idle_time+=dt;
beam=max(0,beam-dt);
recoil*=exp(-14*dt);
settle=max(0,settle-dt*2);
finisher_flash=max(0,finisher_flash-dt);
charge_lockout=max(0,charge_lockout-dt);

// Overloaded retargets and keeps its remaining attacks if no enemy is in range.
var target=tower_find_target(id);
var tracking=instance_exists(target);
var aligned=false;
if(tracking) {
    var desired=point_direction(0,0,target.x-x,(target.y-y)*2);
    // A damped angular spring removes the start/stop snap of fixed-speed turning.
    var turn_error=angle_difference(desired,facing);
    turn_velocity+=turn_error*34*dt;
    turn_velocity*=exp(-9*dt);
    turn_velocity=clamp(turn_velocity,-300,300);
    facing=(facing+turn_velocity*dt+360) mod 360;
    aligned=abs(angle_difference(desired,facing))<7;
} else {
    turn_velocity*=exp(-10*dt);
}
var charging=charge_mode=="charging";
charge_pose=lerp(charge_pose,charging ? 1 : 0,1-exp(-9*dt));
var aim_goal=tracking && !charging && charge_mode!="recovery" ? 1 : 0;
aim_blend=lerp(aim_blend,aim_goal,1-exp(-7*dt));

if(charging) {
    // Preserve the pre-charge cooldown. Only eligible attacks are banked;
    // empty space never generates free shots. The duration still expires normally.
    var charge_dt=min(dt,charge_left);
    cooldown=max(0,cooldown-charge_dt);
    if(tracking && aligned && cooldown<=0 && charge_left>0) {
        stored_shots+=1;
        cooldown=attack_interval;
    }
    charge_left=max(0,charge_left-charge_dt);
    if(charge_left<=0) {
        burst_total=stored_shots;
        burst_target=target;
        charge_mode=stored_shots>0 ? "burst" : "recovery";
        if(charge_mode=="recovery") stored_shots=0;
        burst_clock=0;
        recovery_left=0.5;
    }
    return;
}
if(charge_mode=="burst") {
    burst_clock=max(0,burst_clock-dt);
    if(tracking && aligned && aim_blend>0.95 && burst_clock<=0) {
        tower_fire(id,target);
        stored_shots-=1;
        burst_clock=burst_interval;
        if(stored_shots==0) {
            stored_shots=0;
            charge_mode="recovery";
            recovery_left=0.5;
            cooldown=attack_interval;
        }
    }
    return;
}
if(charge_mode=="recovery") {
    recovery_left=max(0,recovery_left-dt);
    if(recovery_left<=0) {
        charge_mode="ready";
        charge_lockout=charge_reuse_delay;
    }
    return;
}
cooldown=max(0,cooldown-dt);
if(tracking && aligned && aim_blend>0.95 && cooldown<=0) {
    tower_fire(id,target);
    cooldown=attack_interval;
}


}


function tower_find_target(_tower) {
    var best=noone; var best_score=-1000000000;
    for(var i=0;i<instance_number(obj_enemy);++i) {
        var enemy=instance_find(obj_enemy,i);
        var distance=point_distance(_tower.world_x,_tower.world_y,enemy.world_x,enemy.world_y);
        if(distance>_tower.attack_range || enemy.hit_points<=0) continue;
        var value=enemy.progress;
        if(_tower.target_mode==1) value=enemy.hit_points;
        if(_tower.target_mode==2) value=-distance;
        if(value>best_score) { best=enemy; best_score=value; }
    }
    return best;
}
function tower_can_charge(_tower) {
    return instance_exists(_tower) && !obj_game.paused && !_tower.relocating && _tower.charge_mode=="ready" && _tower.charge_lockout<=0 && _tower.settle<=0;
}
function tower_request_charge(_tower) {
    if(!instance_exists(_tower)) return false;
    if(!tower_can_charge(_tower)) { _tower.reject_pulse=1; return false; }
    _tower.charge_mode="charging";
    _tower.charge_left=_tower.charge_duration;
    _tower.stored_shots=0;
    _tower.select_pulse=1;
    return true;
}
function tower_fire(_tower,_target) {
    if(!instance_exists(_target)) return;
    _tower.shots_fired+=1;
    _tower.beam=0.12;
    _tower.beam_world_x=_target.world_x; _tower.beam_world_y=_target.world_y;
    _tower.beam_x=_target.x; _tower.beam_y=_target.y-20;
    _tower.recoil=11;
    for(var hit=0;hit<_tower.definition.hits_per_attack;++hit) {
        if(!instance_exists(_target)) break;
        var dealt=_tower.damage*_tower.definition.hit_multiplier;
        _tower.hits_landed+=1;
        _tower.damage_dealt+=min(_target.hit_points,dealt);
        _target.hit_points-=dealt;
        _target.hit_flash=0.15;
        enemy_apply_shock(_target,_tower.definition);
        instance_create_depth(_target.x,_target.y-20,-10000,obj_impact,{effect_kind:_target.hit_points<=0 ? "kill" : "hit",burst:_target.hit_points<=0,world_x:_target.world_x,world_y:_target.world_y});
        if(_target.hit_points<=0) { _tower.kills+=1; instance_destroy(_target); break; }
    }
}
function enemy_apply_shock(_enemy,_definition) {
    var previous=_enemy.shock_stacks;
    _enemy.shock_stacks=min(previous+1,_definition.shock_max_stacks);
    _enemy.shock_left=_definition.shock_duration;
    _enemy.shock_slow=min(0.4,_enemy.shock_stacks*_definition.shock_per_stack);
    // Lock triggers on reaching the cap, not on every refresh at the cap.
    if(previous<_definition.shock_max_stacks && _enemy.shock_stacks==_definition.shock_max_stacks)
        _enemy.lock_left=max(_enemy.lock_left,_definition.lock_duration);
}
function enemy_movement_time(_enemy,_dt) {
    var locked=min(_dt,_enemy.lock_left);
    var slowed=max(0,min(_dt,_enemy.shock_left)-locked);
    var movement=(_dt-locked)-slowed*_enemy.shock_slow;
    _enemy.lock_left=max(0,_enemy.lock_left-_dt);
    _enemy.shock_left=max(0,_enemy.shock_left-_dt);
    if(_enemy.shock_left<=0) { _enemy.shock_stacks=0; _enemy.shock_slow=0; }
    return movement;
}
function tower_charge_progress(_tower) {
    if(_tower.charge_mode=="charging") return clamp(1-_tower.charge_left/_tower.charge_duration,0,1);
    if(_tower.charge_mode=="burst" && _tower.burst_total>0) return _tower.stored_shots/_tower.burst_total;
    return 0;
}
function tower_status(_tower) {
    if(_tower.relocating) return "RELOCATING";
    switch(_tower.charge_mode) {
        case "charging": return "CHARGING";
        case "burst": return "BURST";
        case "recovery": return "RECOVERING";
    }
    if(_tower.charge_lockout>0) return "RECHARGING";
    return "READY";
}

function tower_visual_y(_tower) {
    return _tower.y-(sin(_tower.settle*pi)*3+sin(_tower.select_pulse*pi)*1.5)*obj_camera.zoom;
}



// Shared footprint validation for initial placement and relocation.
function placement_is_valid(_wx,_wy,_ignore=noone) {
    if(_wx< -0.15 || _wx>8.15 || _wy< -0.15 || _wy>6.15) return false;
    if(variable_instance_exists(obj_world,"void_regions")) {
        var voids=obj_world.void_regions;
        for(var i=0;i<array_length(voids);++i) {
            var region=voids[i];
            var padding=0.34;
            if(_wx>region[0]-padding && _wx<region[2]+padding &&
                _wy>region[1]-padding && _wy<region[3]+padding) return false;
        }
    }
    var route=obj_world.route;
    for(var i=0;i<array_length(route);++i) {
        var dx=max(abs(_wx-route[i][0])-0.5,0);
        var dy=max(abs(_wy-route[i][1])-0.5,0);
        if(dx*dx+dy*dy<0.35*0.35) return false;
    }
    for(var i=0;i<instance_number(obj_terrain);++i) {
        var rock=instance_find(obj_terrain,i);
        if(point_distance(_wx,_wy,rock.world_x,rock.world_y)<rock.radius+0.45) return false;
    }
    for(var i=0;i<instance_number(obj_tower);++i) {
        var tower=instance_find(obj_tower,i);
        if(tower!=_ignore && point_distance(_wx,_wy,tower.world_x,tower.world_y)<0.7) return false;
    }
    return true;
}
function tower_request_move(_tower) {
    if(!instance_exists(_tower)) return false;
    if(obj_game.paused || instance_exists(obj_placement) || _tower.charge_mode!="ready") {
        _tower.reject_pulse=1;
        return false;
    }
    _tower.relocating=true;
    instance_create_depth(_tower.x,_tower.y,-_tower.y,obj_placement,{moving_tower:_tower});
    return true;
}
function tower_cancel_move() {
    if(!instance_exists(obj_placement) || !instance_exists(obj_placement.moving_tower)) return false;
    obj_placement.moving_tower.relocating=false;
    instance_destroy(obj_placement);
    return true;
}
function tower_commit_move(_tower,_wx,_wy) {
    if(!instance_exists(_tower) || !_tower.relocating || obj_game.paused || !placement_is_valid(_wx,_wy,_tower)) return false;
    _tower.world_x=_wx; _tower.world_y=_wy;
    _tower.x=project_x(_wx,_wy); _tower.y=project_y(_wx,_wy); _tower.depth=-_tower.y;
    _tower.relocating=false;
    _tower.settle=1;
    _tower.select_pulse=1;
    return true;
}
