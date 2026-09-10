function tower_initialize() {
definition=tower_definition(tower_type);
attack_range=definition.attack_range;
damage=definition.damage;
vigil=0;
vigil_earned=0;
hits_landed=0;
ability_tab=0;
ability_detail_open=false;
relocating=false;
move_active=false;
move_elapsed=0;
move_duration=0.32;
move_from_x=world_x; move_from_y=world_y;
move_target_x=world_x; move_target_y=world_y;
move_trail_x=array_create(7,world_x);
move_trail_y=array_create(7,world_y);
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
shot_interval=definition.shot_interval;
shot_fx_duration=min(0.06,shot_interval*0.6);
attack_shots_left=0;
attack_shot_clock=0;
attack_overloaded=false;
charge_duration=definition.charge_duration;
burst_interval=definition.burst_interval;
charge_reuse_delay=definition.charge_reuse_delay;
charge_mode=TowerChargeState.Ready;
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


target_mode=TowerTargetMode.First;
kills=0; damage_dealt=0; shots_fired=0;
hover_amount=0; selection_amount=0; select_pulse=0; reject_pulse=0;

}


function tower_tick() {
var dt=min(delta_time/1000000,0.05);
if(obj_game.paused) return;
if(move_active) { tower_tick_move(id,dt); return; }
if(relocating) return;
idle_time+=dt;
beam=max(0,beam-dt);
recoil*=exp(-14*dt);
settle=max(0,settle-dt*2);
finisher_flash=max(0,finisher_flash-dt);
charge_lockout=max(0,charge_lockout-dt);

// Overloaded retargets and keeps its remaining attacks if no enemy is in range.
var target=tower_find_target(id,definition.key=="wanderer" && charge_mode==TowerChargeState.Charging);
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
var charging=charge_mode==TowerChargeState.Charging;
charge_pose=lerp(charge_pose,charging ? 1 : 0,1-exp(-9*dt));
// Keep tracking during Charge so a banked burst can begin immediately when a
// target was already present. Targetless charges still acquire normally later.
var aim_goal=tracking && charge_mode!=TowerChargeState.Recovery ? 1 : 0;
if(definition.key=="wanderer") aim_goal=charging || finisher_flash>0 ? 1 : 0;
aim_blend=lerp(aim_blend,aim_goal,1-exp(-7*dt));

if(charging) {
    if(definition.key=="wanderer") {
        charge_left=max(0,charge_left-dt);
        if(charge_left<=0) {
            charge_mode=TowerChargeState.Ready;
            charge_lockout=charge_reuse_delay;
            wanderer_skill_attack(id,true);
        }
        return;
    }
    // Banking follows Vestral's attack clock, not target availability. A quiet
    // lane therefore stores the same number of Double Taps as a busy one.
    var charge_dt=min(dt,charge_left);
    cooldown-=charge_dt;
    // Strictly exclude an attack whose start lands on the exact Charge end.
    while(cooldown< -0.000001 && charge_left>0) {
        stored_shots+=1;
        cooldown+=attack_interval;
    }
    charge_left=max(0,charge_left-charge_dt);
    if(charge_left<=0) {
        burst_total=stored_shots;
        burst_target=target;
        charge_mode=stored_shots>0 ? TowerChargeState.Burst : TowerChargeState.Recovery;
        if(charge_mode==TowerChargeState.Recovery) stored_shots=0;
        burst_clock=0;
        recovery_left=0.5;
    }
    return;
}
if(charge_mode==TowerChargeState.Burst) {
    burst_clock=max(0,burst_clock-dt);
    if(attack_shots_left>0) {
        tower_tick_attack_sequence(id,dt,target,tracking);
    } else if(tracking && aligned && aim_blend>0.95 && burst_clock<=0 && stored_shots>0) {
        tower_begin_attack(id,true);
        tower_tick_attack_sequence(id,0,target,true);
    }
    return;
}
if(charge_mode==TowerChargeState.Recovery) {
    recovery_left=max(0,recovery_left-dt);
    if(recovery_left<=0) {
        charge_mode=TowerChargeState.Ready;
        charge_lockout=charge_reuse_delay;
    }
    return;
}
if(attack_shots_left>0) {
    tower_tick_attack_sequence(id,dt,target,tracking);
    return;
}
cooldown=max(0,cooldown-dt);
if(definition.key=="wanderer") return;
if(tracking && aligned && aim_blend>0.95 && cooldown<=0) {
    tower_begin_attack(id,false);
    tower_tick_attack_sequence(id,0,target,true);
}


}


function tower_find_target(_tower,_unlimited=false) {
    var best=noone; var best_score=-1000000000;
    for(var i=0;i<instance_number(obj_enemy);++i) {
        var enemy=instance_find(obj_enemy,i);
        var distance=point_distance(_tower.world_x,_tower.world_y,enemy.world_x,enemy.world_y);
        if((!_unlimited && distance>_tower.attack_range) || enemy.hit_points<=0) continue;
        var value=enemy.progress;
        if(_tower.target_mode==TowerTargetMode.Strongest) value=enemy.hit_points;
        if(_tower.target_mode==TowerTargetMode.Nearest) value=-distance;
        if(value>best_score) { best=enemy; best_score=value; }
    }
    return best;
}
function tower_can_charge(_tower) {
    return instance_exists(_tower) && !obj_game.paused && !_tower.relocating &&
        _tower.attack_shots_left<=0 && _tower.charge_mode==TowerChargeState.Ready &&
        _tower.charge_lockout<=0 && _tower.settle<=0;
}
function tower_request_charge(_tower) {
    if(!instance_exists(_tower)) return false;
    if(!tower_can_charge(_tower)) { _tower.reject_pulse=1; return false; }
    _tower.charge_mode=TowerChargeState.Charging;
    _tower.charge_left=_tower.charge_duration;
    _tower.stored_shots=0;
    _tower.select_pulse=1;
    return true;
}
function tower_begin_attack(_tower,_overloaded) {
    if(_tower.attack_shots_left>0) return false;
    _tower.shots_fired+=1;
    _tower.attack_shots_left=_tower.definition.hits_per_attack;
    _tower.attack_shot_clock=0;
    _tower.attack_overloaded=_overloaded;
    return true;
}

function tower_tick_attack_sequence(_tower,_dt,_target,_can_fire) {
    if(_tower.attack_shots_left<=0) return false;
    _tower.attack_shot_clock=max(0,_tower.attack_shot_clock-_dt);
    if(_tower.attack_shot_clock>0) return false;
    if(!_can_fire || !instance_exists(_target)) {
        // Charged attacks are inventory and must survive an empty lane. A normal
        // Double Tap ends cleanly if its target disappears and nobody can inherit it.
        if(!_tower.attack_overloaded) tower_finish_attack_sequence(_tower);
        return false;
    }
    tower_fire_hit(_tower,_target);
    _tower.attack_shots_left-=1;
    if(_tower.attack_shots_left>0) _tower.attack_shot_clock=_tower.shot_interval;
    else tower_finish_attack_sequence(_tower);
    return true;
}

function tower_finish_attack_sequence(_tower) {
    _tower.attack_shots_left=0;
    _tower.attack_shot_clock=0;
    if(_tower.attack_overloaded) {
        _tower.stored_shots=max(0,_tower.stored_shots-1);
        _tower.burst_clock=_tower.burst_interval;
        if(_tower.stored_shots<=0) {
            _tower.stored_shots=0;
            _tower.charge_mode=TowerChargeState.Recovery;
            _tower.recovery_left=0.5;
            _tower.cooldown=_tower.attack_interval;
        }
    } else {
        // ATK SPD downtime starts after the second bolt, never after the first.
        _tower.cooldown=_tower.attack_interval;
    }
    _tower.attack_overloaded=false;
}

function tower_fire_hit(_tower,_target) {
    if(!instance_exists(_target)) return false;
    // End the tracer before the next bolt so Double Tap reads as two shots.
    _tower.beam=_tower.shot_fx_duration;
    _tower.beam_world_x=_target.world_x; _tower.beam_world_y=_target.world_y;
    _tower.beam_x=_target.x; _tower.beam_y=_target.y-20;
    _tower.recoil=_tower.definition.key=="wanderer" ? 19 : 11;
    if(_tower.definition.key=="wanderer") _tower.finisher_flash=0.65;
    var dealt=_tower.damage*_tower.definition.hit_multiplier;
    if(_tower.definition.key=="wanderer" && _target.hit_points*200<_target.max_hit_points*7) dealt=_target.hit_points;
    dealt=min(_target.hit_points,dealt);
    _tower.hits_landed+=1;
    _tower.damage_dealt+=min(_target.hit_points,dealt);
    _target.hit_points-=dealt;
    _target.hit_flash=0.15;
    if(_tower.definition.key=="wanderer") {
        if(_target.hit_points>0 && _target.hit_points*200<_target.max_hit_points*7) {
            dealt+=_target.hit_points;
            _tower.damage_dealt+=_target.hit_points;
            _target.hit_points=0;
        }
    } else enemy_apply_shock(_target,_tower.definition);
    if(_tower.definition.key!="wanderer") instance_create_depth(_target.x,_target.y-20,-10000,obj_impact,{effect_kind:_target.hit_points<=0 ? "kill" : "hit",burst:_target.hit_points<=0,world_x:_target.world_x,world_y:_target.world_y});
    if(_target.hit_points<=0) {
        _tower.kills+=1;
        if(_tower.definition.key=="wanderer") {
            var stacks=clamp(ceil(dealt/_tower.definition.vigil_damage_step),1,4);
            var full=min(stacks,max(0,_tower.definition.vigil_breakpoint-_tower.vigil_earned));
            _tower.vigil+=stacks;
            _tower.vigil_earned+=stacks;
            _tower.damage+=full*_tower.definition.vigil_attack+(stacks-full)*_tower.definition.vigil_attack_reduced;
            _tower.charge_lockout=0;
        }
        instance_destroy(_target);
    }
    return true;
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
    if(_tower.charge_mode==TowerChargeState.Charging) return clamp(1-_tower.charge_left/_tower.charge_duration,0,1);
    if(_tower.charge_mode==TowerChargeState.Burst && _tower.burst_total>0) return _tower.stored_shots/_tower.burst_total;
    return 0;
}
function tower_status(_tower) {
    if(_tower.relocating) return "RELOCATING";
    switch(_tower.charge_mode) {
        case TowerChargeState.Charging: return "CHARGING";
        case TowerChargeState.Burst: return "BURST";
        case TowerChargeState.Recovery: return "RECOVERING";
    }
    if(_tower.charge_lockout>0) return "RECHARGING";
    return "READY";
}

function tower_visual_y(_tower) {
    var move_lift=_tower.move_active ? sin(tower_move_progress(_tower)*pi)*18 : 0;
    return _tower.y-(sin(_tower.settle*pi)*3+sin(_tower.select_pulse*pi)*1.5+move_lift)*obj_camera.zoom;
}

function tower_move_progress(_tower) {
    if(!_tower.move_active) return 0;
    return clamp(_tower.move_elapsed/_tower.move_duration,0,1);
}

function tower_tick_move(_tower,_dt) {
    for(var trail=array_length(_tower.move_trail_x)-1;trail>0;--trail) {
        _tower.move_trail_x[trail]=_tower.move_trail_x[trail-1];
        _tower.move_trail_y[trail]=_tower.move_trail_y[trail-1];
    }
    _tower.move_trail_x[0]=_tower.world_x;
    _tower.move_trail_y[0]=_tower.world_y;
    _tower.move_elapsed=min(_tower.move_elapsed+_dt,_tower.move_duration);
    var progress=tower_move_progress(_tower);
    var eased=1-power(1-progress,3);
    _tower.world_x=lerp(_tower.move_from_x,_tower.move_target_x,eased);
    _tower.world_y=lerp(_tower.move_from_y,_tower.move_target_y,eased);
    _tower.x=project_x(_tower.world_x,_tower.world_y);
    _tower.y=project_y(_tower.world_x,_tower.world_y);
    _tower.depth=-_tower.y;
    if(progress>=1) {
        _tower.world_x=_tower.move_target_x; _tower.world_y=_tower.move_target_y;
        _tower.x=project_x(_tower.world_x,_tower.world_y);
        _tower.y=project_y(_tower.world_x,_tower.world_y);
        _tower.depth=-_tower.y;
        _tower.move_active=false;
        _tower.relocating=false;
        _tower.settle=0.55;
        _tower.select_pulse=1;
        if(_tower.definition.key=="wanderer") wanderer_skill_attack(_tower,false);
    }
}

function wanderer_skill_attack(_tower,_unlimited) {
    _tower.vigil=max(0,_tower.vigil-1);
    var target=tower_find_target(_tower,_unlimited);
    if(!instance_exists(target)) return false;
    _tower.facing=point_direction(0,0,target.x-_tower.x,(target.y-_tower.y)*2);
    _tower.turn_velocity=0;
    _tower.aim_blend=1;
    _tower.charge_pose=0;
    _tower.finisher_flash=0.2;
    _tower.shots_fired+=1;
    return tower_fire_hit(_tower,target);
}



// Shared footprint validation for initial placement and relocation.
function placement_is_valid(_wx,_wy,_ignore=noone) {
    if(!map_point_on_surface(_wx,_wy,0.34)) return false;
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
        var occupied_x=tower.move_active ? tower.move_target_x : tower.world_x;
        var occupied_y=tower.move_active ? tower.move_target_y : tower.world_y;
        if(tower!=_ignore && point_distance(_wx,_wy,occupied_x,occupied_y)<0.7) return false;
    }
    return true;
}
function tower_request_move(_tower) {
    if(!instance_exists(_tower)) return false;
    if(obj_game.paused || instance_exists(obj_placement) || _tower.relocating ||
        _tower.attack_shots_left>0 || _tower.charge_mode!=TowerChargeState.Ready) {
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
    _tower.move_from_x=_tower.world_x; _tower.move_from_y=_tower.world_y;
    _tower.move_target_x=_wx; _tower.move_target_y=_wy;
    _tower.move_elapsed=0;
    _tower.move_active=true;
    for(var trail=0;trail<array_length(_tower.move_trail_x);++trail) {
        _tower.move_trail_x[trail]=_tower.world_x;
        _tower.move_trail_y[trail]=_tower.world_y;
    }
    return true;
}
