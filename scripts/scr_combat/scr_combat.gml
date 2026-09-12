function tower_heal(_tower,_amount,_source_x=undefined,_source_y=undefined,_source_height=6) {
    if(!instance_exists(_tower) || _tower.hit_points<=0) return;
    var healed=min(_amount,_tower.max_hit_points-_tower.hit_points);
    _tower.hit_points+=healed;
    if(healed>0) {
        combat_text(_tower,"+"+string_format(healed,1,1),true);
        triage_emit("heal",_tower.world_x,_tower.world_y,_tower);
        if(_source_x!=undefined && _source_y!=undefined) {
            instance_create_depth(0,0,-10020,obj_impact,{effect_kind:"heal_arc",burst:false,
                world_x:_source_x,world_y:_source_y,source_height:_source_height,
                target_x:_tower.world_x,target_y:_tower.world_y,fx_owner:_tower});
        }
    }
}
function triage_resuscitate(_tower) {
    triage_emit("release",_tower.world_x,_tower.world_y,noone,_tower.attack_range);
    for(var i=0;i<instance_number(obj_enemy);++i) {
        var enemy=instance_find(obj_enemy,i);
        if(point_distance(_tower.world_x,_tower.world_y,enemy.world_x,enemy.world_y)<=_tower.attack_range) {
            if(enemy.tourniquet_heal>0) triage_emit("consume",enemy.world_x,enemy.world_y);
            enemy.tourniquet_heal=0;
        }
    }
    for(var i=0;i<instance_number(obj_tower);++i) {
        var ally=instance_find(obj_tower,i);
        ally.shield_hp=max(ally.shield_hp,ally.max_hit_points*0.3);
        triage_emit("shield",ally.world_x,ally.world_y,ally);
    }
}
function triage_tick_support(_dt) {
    if(obj_game.paused || _dt<=0) return;
    for(var i=0;i<instance_number(obj_tower);++i) {
        var tower=instance_find(obj_tower,i);
        tower.shield_hp=max(0,tower.shield_hp-tower.max_hit_points*0.1*_dt);
        if(tower.definition.key!="triage" || tower.kit_left<=0) continue;
        for(var j=0;j<instance_number(obj_tower);++j) {
            var ally=instance_find(obj_tower,j);
            if(point_distance(tower.kit_x,tower.kit_y,ally.world_x,ally.world_y)>tower.definition.kit_radius) continue;
            var healed=false;
            for(var k=0;k<array_length(tower.kit_healed);++k) if(tower.kit_healed[k]==ally) healed=true;
            if(!healed) { tower_heal(ally,tower.damage*1.2,tower.kit_x,tower.kit_y); array_push(tower.kit_healed,ally); }
        }
        tower.kit_left=max(0,tower.kit_left-_dt);
        if(tower.kit_left<=0) triage_emit("expire",tower.kit_x,tower.kit_y);
    }
}

function tower_initialize() {
definition=tower_definition(tower_type);
attack_range=definition.attack_range;
damage=definition.damage;
max_hit_points=definition.max_hit_points;
hit_points=max_hit_points;
shield_hp=0;
stun_left=0;
debris=[];
debris_serial=0;
density=0;
pending_density=0;
pulse_left=0;
pulse_fx=0;
skill_release=0;
summon_left=definition.key=="singularity" ? definition.summon_duration : 0;
orbit_clock=0;
orbit_x=world_x;
orbit_y=world_y;
kit_left=0;
kit_healed=[];
kit_x=world_x;
kit_y=world_y;
display_hit_points=hit_points;
charge_ready_blend=0;
charge_ready_pulse=0;
charge_was_ready=false;
hit_flash=0;
move_speed=definition.move_speed;
vigil=0;
vigil_earned=0;
hits_landed=0;
ability_tab=0;
ability_detail_open=false;
relocating=false;
move_active=false;
move_elapsed=0;
move_duration=0;
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
shot_fx_duration=definition.key=="triage" ? 0.22 : min(0.06,shot_interval*0.6);
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
hit_flash=max(0,hit_flash-dt);
// Live HP drops immediately; the gray trail holds briefly, then catches up.
if(display_hit_points<hit_points) display_hit_points=hit_points;
else if(hit_flash<=0) display_hit_points=lerp(display_hit_points,hit_points,1-exp(-8*dt));
if(abs(display_hit_points-hit_points)<0.01) display_hit_points=hit_points;
var skill_ready=tower_can_charge(id);
charge_ready_blend=lerp(charge_ready_blend,skill_ready ? 1 : 0,1-exp(-10*dt));
charge_ready_pulse=max(0,charge_ready_pulse-dt*1.5);
if(skill_ready && !charge_was_ready) charge_ready_pulse=1;
charge_was_ready=skill_ready;
if(definition.key=="singularity") singularity_tick_orbit(id,dt);
if(stun_left>0) {
    var stunned=min(dt,stun_left);stun_left=max(0,stun_left-dt);dt-=stunned;
    if(dt<=0.000001) return;
}
if(summon_left>0) {
    idle_time+=dt;summon_left=max(0,summon_left-dt);
    if(summon_left<=0.000001) summon_left=0;
    return;
}
if(move_active) { tower_tick_move(id,dt); return; }
if(relocating) return;
idle_time+=dt;
beam=max(0,beam-dt);
recoil*=exp(-(definition.key=="wanderer" ? 8 : (definition.key=="triage" ? 9 : 14))*dt);
settle=max(0,settle-dt*2);
finisher_flash=max(0,finisher_flash-dt);
charge_lockout=max(0,charge_lockout-dt);

if(definition.key=="singularity") { singularity_tick_attack(id,dt); return; }

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
charge_pose=lerp(charge_pose,charging ? 1 : 0,1-exp(-(definition.key=="triage" ? 5 : 9)*dt));
// Keep tracking during Charge so a banked burst can begin immediately when a
// target was already present. Targetless charges still acquire normally later.
var aim_goal=tracking && charge_mode!=TowerChargeState.Recovery ? 1 : 0;
if(definition.key=="wanderer") aim_goal=charging || finisher_flash>0 ? 1 : 0;
aim_blend=lerp(aim_blend,aim_goal,1-exp(-(definition.key=="wanderer" ? (aim_goal>0 ? 3.5 : 2.8) : 7)*dt));

if(charging) {
    if(definition.key=="triage") {
        charge_left=max(0,charge_left-dt);
        if(charge_left<=0) { triage_resuscitate(id); charge_mode=TowerChargeState.Ready; charge_lockout=charge_reuse_delay; }
        return;
    }
    if(definition.key=="wanderer") {
        charge_left=max(0,charge_left-dt);
        if(charge_left<=0) {
            charge_mode=TowerChargeState.Ready;
            charge_lockout=charge_reuse_delay;
            wanderer_skill_attack(id);
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
        if(enemy.spawn_left>0 || (!_unlimited && distance>_tower.attack_range) || enemy.hit_points<=0) continue;
        var value=enemy.progress;
        if(_tower.target_mode==TowerTargetMode.Strongest) value=enemy.hit_points;
        if(_tower.target_mode==TowerTargetMode.Nearest) value=-distance;
        if(value>best_score) { best=enemy; best_score=value; }
    }
    return best;
}
function tower_can_charge(_tower) {
    return instance_exists(_tower) && !obj_game.paused && !_tower.relocating && _tower.stun_left<=0 &&
        (_tower.definition.key!="singularity" || (_tower.pulse_left<=0 && _tower.summon_left<=0 && _tower.pulse_fx<=0 && _tower.skill_release<=0)) &&
        _tower.attack_shots_left<=0 && _tower.charge_mode==TowerChargeState.Ready &&
        _tower.charge_lockout<=0 && _tower.settle<=0;
}
function tower_request_charge(_tower) {
    if(!instance_exists(_tower)) return false;
    if(!tower_can_charge(_tower)) { _tower.reject_pulse=1; return false; }
    if(_tower.definition.key=="singularity") {
        _tower.pending_density=array_length(_tower.debris);
        _tower.debris=[];
        singularity_emit("horizon",_tower.world_x,_tower.world_y,_tower.attack_range);
    }
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
    _tower.recoil=_tower.definition.key=="wanderer" ? 29 : 11;
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
    } else if(_tower.definition.key=="vestral") enemy_apply_shock(_target,_tower.definition);
    else if(_tower.definition.key=="triage" && _tower.hits_landed mod 3==0) {
        _target.tourniquet_heal=_tower.damage*0.8;
        combat_text(_target,"Tourniquet",true);
        triage_emit("mark",_target.world_x,_target.world_y);
    }
    if(_tower.definition.key=="triage") triage_emit(_target.hit_points<=0 ? "kill" : "dart",_target.world_x,_target.world_y);
    if(_tower.definition.key=="vestral") instance_create_depth(_target.x,_target.y-20,-10000,obj_impact,{effect_kind:_target.hit_points<=0 ? "kill" : "hit",burst:_target.hit_points<=0,world_x:_target.world_x,world_y:_target.world_y});
    combat_text(_target,string_format(dealt,1,dealt==floor(dealt) ? 0 : 1),false,_tower.hits_landed mod 3);
    tower_resolve_kill(_tower,_target,dealt);
    return true;
}
// Independent text instances survive a lethal hit; status labels share this path.
function combat_text(_enemy,_text,_status,_lane=0) {
    instance_create_depth(_enemy.x,_enemy.y,-10001,obj_impact,{effect_kind:"text",burst:false,
        world_x:_enemy.world_x,world_y:_enemy.world_y,popup_text:_text,popup_status:_status,popup_lane:_lane});
}
function enemy_apply_shock(_enemy,_definition) {
    var previous=_enemy.shock_stacks;
    if(previous==0) combat_text(_enemy,"Slow",true,0);
    _enemy.shock_stacks=min(previous+1,_definition.shock_max_stacks);
    _enemy.shock_left=_definition.shock_duration;
    _enemy.shock_slow=min(0.4,_enemy.shock_stacks*_definition.shock_per_stack);
    // Lock triggers on reaching the cap, not on every refresh at the cap.
    if(previous<_definition.shock_max_stacks && _enemy.shock_stacks==_definition.shock_max_stacks) {
        _enemy.lock_left=max(_enemy.lock_left,_definition.lock_duration);
        combat_text(_enemy,"Lock",true,0);
    }
}
function enemy_movement_time(_enemy,_dt) {
    var locked=min(_dt,_enemy.lock_left);
    var slowed=max(0,min(_dt,_enemy.shock_left)-locked);
    var movement=(_dt-locked)-slowed*_enemy.shock_slow;
    _enemy.lock_left=max(0,_enemy.lock_left-_dt);
    _enemy.shock_left=max(0,_enemy.shock_left-_dt);
    // Floating-point subtraction must not leave expired stacks alive for a frame.
    if(_enemy.shock_left<=0.000001) { _enemy.shock_left=0; _enemy.shock_stacks=0; _enemy.shock_slow=0; }
    return _enemy.tourniquet_heal>0 ? movement*0.75 : movement;
}
function tower_charge_progress(_tower) {
    if(_tower.charge_mode==TowerChargeState.Charging) return clamp(1-_tower.charge_left/_tower.charge_duration,0,1);
    if(_tower.charge_mode==TowerChargeState.Burst && _tower.burst_total>0) return _tower.stored_shots/_tower.burst_total;
    return 0;
}
function tower_status(_tower) {
    if(_tower.summon_left>0) return "EMERGING";
    if(_tower.stun_left>0) return "STUNNED";
    if(_tower.definition.key=="singularity" && _tower.pulse_left>0) return "PULSE WINDUP";
    if(_tower.definition.key=="singularity" && (_tower.pulse_fx>0 || _tower.skill_release>0)) return "RECOVERING";
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
        if(_tower.definition.key=="triage") {
            if(_tower.kit_left>0) triage_emit("expire",_tower.kit_x,_tower.kit_y);
            triage_emit("land",_tower.world_x,_tower.world_y);
            triage_emit("kit",_tower.move_from_x,_tower.move_from_y);
            _tower.kit_x=_tower.move_from_x; _tower.kit_y=_tower.move_from_y;
            _tower.kit_left=_tower.definition.kit_duration; _tower.kit_healed=[];
        }
        _tower.move_active=false;
        _tower.relocating=false;
        _tower.settle=0.55;
        _tower.select_pulse=1;
    }
}

function wanderer_skill_attack(_tower) {
    var target=tower_find_target(_tower,true);
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
    if(obj_game.paused || _tower.stun_left>0 || (_tower.definition.key=="singularity" && (_tower.pulse_left>0 || _tower.summon_left>0 || _tower.pulse_fx>0 || _tower.skill_release>0)) || instance_exists(obj_placement) || _tower.relocating ||
        _tower.attack_shots_left>0 || _tower.charge_mode!=TowerChargeState.Ready) {
        _tower.reject_pulse=1;
        return false;
    }
    _tower.relocating=true;
    instance_create_depth(_tower.x,_tower.y,-_tower.y,obj_placement,{moving_tower:_tower});
    return true;
}
function tower_cancel_move() {
    if(!instance_exists(obj_placement)) return false;
    if(instance_exists(obj_placement.moving_tower)) obj_placement.moving_tower.relocating=false;
    instance_destroy(obj_placement);
    return true;
}
function tower_commit_move(_tower,_wx,_wy) {
    if(!instance_exists(_tower) || !_tower.relocating || obj_game.paused || _tower.stun_left>0 || !placement_is_valid(_wx,_wy,_tower)) return false;
    var distance=point_distance(_tower.world_x,_tower.world_y,_wx,_wy);
    if(distance<0.01 || _tower.move_speed<=0) return false;
    // MVE SPD is average world tiles per second, including the eased dash.
    _tower.move_duration=distance/_tower.move_speed;
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

function tower_take_damage(_tower,_amount) {
    if(!instance_exists(_tower) || obj_game.paused || _amount<=0) return false;
    var absorbed=min(_tower.shield_hp,_amount);
    _tower.shield_hp-=absorbed;
    if(absorbed>0) triage_emit(_tower.shield_hp<=0 ? "break" : "absorb",_tower.world_x,_tower.world_y,_tower);
    var minimum=0;
    for(var medic_index=0;medic_index<instance_number(obj_tower);++medic_index) {
        var medic=instance_find(obj_tower,medic_index);
        if(medic.definition.key=="triage" && medic.charge_mode==TowerChargeState.Charging &&
            point_distance(medic.world_x,medic.world_y,_tower.world_x,_tower.world_y)<=medic.attack_range) minimum=1;
    }
    var dealt=min(max(0,_tower.hit_points-minimum),_amount-absorbed);
    _tower.hit_points=max(minimum,_tower.hit_points-dealt);
    if(minimum>0 && _amount-absorbed>dealt) triage_emit("protect",_tower.world_x,_tower.world_y,_tower);
    _tower.hit_flash=0.3;
    combat_text(_tower,"-"+string(dealt),false);
    if(_tower.hit_points<=0) {
        if(_tower.definition.key=="triage" && _tower.kit_left>0) triage_emit("expire",_tower.kit_x,_tower.kit_y);
        // Cancel only this tower's preview before its instance becomes invalid.
        if(instance_exists(obj_placement) && obj_placement.moving_tower==_tower) tower_cancel_move();
        if(obj_game.selected_tower==_tower) game_select_tower(noone);
        if(obj_input.hovered_tower==_tower) obj_input.hovered_tower=noone;
        loadout_notice(_tower.definition.name+" destroyed");
        instance_destroy(_tower);
    }
    return true;
}

function enemy_laser_target(_enemy) {
    var nearest=noone; var distance=_enemy.enemy_definition.laser_range;
    for(var i=0;i<instance_number(obj_tower);++i) {
        var tower=instance_find(obj_tower,i);
        var candidate=point_distance(_enemy.world_x,_enemy.world_y,tower.world_x,tower.world_y);
        if(tower.hit_points>0 && candidate<=distance) { nearest=tower; distance=candidate; }
    }
    return nearest;
}

// Returns the part of this frame spent walking. Aiming and firing stop the Lancer.
function enemy_tick_laser(_enemy,_dt) {
    if(obj_game.paused || _dt<=0) return 0;
    var d=_enemy.enemy_definition;
    if(_enemy.laser_state=="walking") {
        _enemy.laser_clock=max(0,_enemy.laser_clock-_dt);
        if(_enemy.laser_clock>0 || _enemy.lock_left>0) return _dt;
        var target=enemy_laser_target(_enemy);
        if(!instance_exists(target)) return _dt;
        _enemy.laser_state="aiming";
        _enemy.laser_clock=d.laser_windup;
        _enemy.laser_target=target;
        // Lock the location when the warning appears; relocation can evade it.
        _enemy.laser_world_x=target.world_x;
        _enemy.laser_world_y=target.world_y;
        return 0;
    }
    // Lock interrupts a windup, giving Vestral a second way to counter the shot.
    if(_enemy.laser_state=="aiming" && (!instance_exists(_enemy.laser_target) || _enemy.lock_left>0)) {
        _enemy.laser_state="walking";
        _enemy.laser_clock=d.laser_cooldown;
        _enemy.laser_target=noone;
        return _dt;
    }
    _enemy.laser_clock=max(0,_enemy.laser_clock-_dt);
    if(_enemy.laser_clock>0) return 0;
    if(_enemy.laser_state=="aiming") {
        _enemy.laser_state="firing";
        _enemy.laser_clock=d.laser_duration;
        // Resolve once, against the marked area. Never apply damage each draw frame.
        for(var i=instance_number(obj_tower)-1;i>=0;--i) {
            var tower=instance_find(obj_tower,i);
            if(point_distance(tower.world_x,tower.world_y,_enemy.laser_world_x,_enemy.laser_world_y)<=d.laser_radius)
                tower_take_damage(tower,d.laser_damage);
        }
    } else {
        _enemy.laser_state="walking";
        _enemy.laser_clock=d.laser_cooldown;
        _enemy.laser_target=noone;
    }
    return 0;
}
// Deterministic, short-lived cues use the existing pause-aware impact object.
function triage_emit(_style,_wx,_wy,_owner=noone,_radius=1) {
    instance_create_depth(project_x(_wx,_wy),project_y(_wx,_wy),-10000,obj_impact,
        {effect_kind:"triage",burst:false,fx_style:_style,fx_owner:_owner,fx_radius:_radius,world_x:_wx,world_y:_wy});
}

function tower_resolve_kill(_tower,_target,_dealt) {
    if(_target.hit_points<=0) {
        if(_target.tourniquet_heal>0) {
            triage_emit("consume",_target.world_x,_target.world_y);
            tower_heal(_tower,_target.tourniquet_heal,_target.world_x,_target.world_y,20);
        }
        _tower.kills+=1;
        if(_tower.definition.key=="singularity") singularity_add_debris(_tower);
        loadout_award_kill();
        if(_tower.definition.key=="wanderer") {
            var stacks=clamp(ceil(_dealt/_tower.definition.vigil_damage_step),1,4);
            var full=min(stacks,max(0,_tower.definition.vigil_breakpoint-_tower.vigil_earned));
            _tower.vigil+=stacks;
            _tower.vigil_earned+=stacks;
            _tower.damage+=full*_tower.definition.vigil_attack+(stacks-full)*_tower.definition.vigil_attack_reduced;
            _tower.charge_lockout*=1-_tower.definition.kill_cooldown_reduction;
            instance_create_depth(_tower.x,_tower.y,-10002,obj_impact,{effect_kind:"vigil",burst:false,
                world_x:_tower.world_x,world_y:_tower.world_y,popup_stacks:stacks});
        }
        instance_destroy(_target);
    }
}
// Stun is an explicit tower status. Refreshes retain the longer remaining duration.
function tower_apply_stun(_tower,_duration) {
    if(!instance_exists(_tower) || obj_game.paused || _duration<=0) return false;
    _tower.stun_left=max(_tower.stun_left,_duration*(_tower.definition.key=="singularity" ? 1.5 : 1));
    combat_text(_tower,"Stunned",true);
    return true;
}
function singularity_add_debris(_tower) {
    var kept=[];var oldest=-1;var life=100000;
    if(array_length(_tower.debris)>=_tower.definition.debris_cap) {
        for(var i=0;i<array_length(_tower.debris);++i) if(_tower.debris[i].left<life) {oldest=i;life=_tower.debris[i].left;}
    }
    for(var i=0;i<array_length(_tower.debris);++i) if(i!=oldest) array_push(kept,_tower.debris[i]);
    _tower.debris_serial+=1;
    array_push(kept,{left:_tower.definition.debris_lifetime,angle:(_tower.debris_serial*137.5) mod 360,serial:_tower.debris_serial,contacts:[]});
    _tower.debris=kept;
    singularity_emit("debris",_tower.world_x,_tower.world_y,0.5);
}
function singularity_damage(_tower,_enemy,_amount) {
    if(!instance_exists(_enemy) || _enemy.hit_points<=0 || _enemy.spawn_left>0) return;
    var dealt=min(_amount,_enemy.hit_points);
    _enemy.hit_points-=dealt;_enemy.hit_flash=0.15;
    _tower.hits_landed+=1;_tower.damage_dealt+=dealt;
    combat_text(_enemy,string_format(dealt,1,dealt==floor(dealt) ? 0 : 1),false,_tower.hits_landed mod 3);
    singularity_emit("hit",_enemy.world_x,_enemy.world_y,0.2);
    tower_resolve_kill(_tower,_enemy,dealt);
}
function singularity_pulse(_tower) {
    _tower.shots_fired+=1;_tower.pulse_left=0;_tower.pulse_fx=_tower.definition.pulse_recovery;_tower.recoil=16;
    _tower.cooldown=_tower.attack_interval;
    singularity_emit("pulse",_tower.world_x,_tower.world_y,_tower.attack_range);
    // Reverse traversal remains valid when several enemies die to the same pulse.
    for(var i=instance_number(obj_enemy)-1;i>=0;--i) {
        var enemy=instance_find(obj_enemy,i);
        if(point_distance(_tower.world_x,_tower.world_y,enemy.world_x,enemy.world_y)<=_tower.attack_range)
            singularity_damage(_tower,enemy,_tower.damage);
    }
}
function singularity_tick_attack(_tower,_dt) {
    var d=_tower.definition;
    _tower.pulse_fx=max(0,_tower.pulse_fx-_dt);
    _tower.skill_release=max(0,_tower.skill_release-_dt);
    var charging=_tower.charge_mode==TowerChargeState.Charging;
    _tower.charge_pose=lerp(_tower.charge_pose,charging ? 1 : 0,1-exp(-5*_dt));
    var windup=_tower.pulse_left>0 ? 1-_tower.pulse_left/d.pulse_windup : 0;
    _tower.aim_blend=lerp(_tower.aim_blend,windup,1-exp(-8*_dt));
    if(charging) {
        _tower.charge_left=max(0,_tower.charge_left-_dt);
        if(_tower.charge_left<=0.000001) {
            _tower.skill_release=0.8;
            _tower.density+=_tower.pending_density;_tower.pending_density=0;
            _tower.charge_left=0;_tower.charge_mode=TowerChargeState.Ready;_tower.charge_lockout=_tower.charge_reuse_delay;
            singularity_emit("horizon",_tower.world_x,_tower.world_y,_tower.attack_range);
        }
        return;
    }
    if(_tower.pulse_left>0) {
        _tower.pulse_left=max(0,_tower.pulse_left-_dt);
        if(_tower.pulse_left<=0.000001) singularity_pulse(_tower);
        return;
    }
    if(_tower.cooldown>0) {
        var downtime=min(_dt,_tower.cooldown);_tower.cooldown=max(0,_tower.cooldown-downtime);_dt-=downtime;
        if(_dt<=0.000001) return;
    }
    if(_tower.skill_release>0 || _tower.settle>0 || !instance_exists(tower_find_target(_tower))) return;
    if(_tower.density>0) {_tower.density-=1;singularity_pulse(_tower);}
    else _tower.pulse_left=d.pulse_windup;
}
function singularity_segment_distance(_px,_py,_ax,_ay,_bx,_by) {
    var dx=_bx-_ax;var dy=_by-_ay;
    var t=clamp(((_px-_ax)*dx+(_py-_ay)*dy)/max(0.000001,dx*dx+dy*dy),0,1);
    return point_distance(_px,_py,_ax+dx*t,_ay+dy*t);
}
function singularity_tick_orbit(_tower,_dt) {
    var d=_tower.definition;var active=_tower.debris;var hits=[];
    _tower.debris=[];_tower.orbit_clock+=_dt;
    for(var i=0;i<array_length(active);++i) {
        var piece=active[i];var duration=min(_dt,piece.left);var previous=piece.angle;
        piece.angle=(piece.angle+d.debris_speed*duration) mod 360;
        piece.left=max(0,piece.left-_dt);
        var ax=_tower.orbit_x+dcos(previous)*d.debris_radius;var ay=_tower.orbit_y+dsin(previous)*d.debris_radius;
        var bx=_tower.world_x+dcos(piece.angle)*d.debris_radius;var by=_tower.world_y+dsin(piece.angle)*d.debris_radius;
        var contacts=[];
        for(var c=0;c<array_length(piece.contacts);++c) {
            var contact=piece.contacts[c];
            if(instance_exists(contact.enemy) && contact.ready_at>_tower.orbit_clock+0.000001) array_push(contacts,contact);
        }
        for(var j=0;j<instance_number(obj_enemy);++j) {
            var enemy=instance_find(obj_enemy,j);
            if(enemy.spawn_left>0 || enemy.hit_points<=0 || singularity_segment_distance(enemy.world_x,enemy.world_y,ax,ay,bx,by)>d.debris_hit_radius) continue;
            var ready=true;
            for(var c=0;c<array_length(contacts);++c) if(contacts[c].enemy==enemy) ready=false;
            if(ready && duration>0) {
                array_push(hits,enemy);array_push(contacts,{enemy:enemy,ready_at:_tower.orbit_clock+d.debris_tick});
            }
        }
        piece.contacts=contacts;
        if(piece.left>0.000001) array_push(_tower.debris,piece);
    }
    _tower.orbit_x=_tower.world_x;_tower.orbit_y=_tower.world_y;
    // Resolve after rebuilding survivors so kills can safely create new fragments.
    for(var i=0;i<array_length(hits);++i) singularity_damage(_tower,hits[i],_tower.damage*d.debris_multiplier);
}
function singularity_emit(_style,_wx,_wy,_radius) {
    instance_create_depth(project_x(_wx,_wy),project_y(_wx,_wy),-10000,obj_impact,
        {effect_kind:"singularity",burst:false,fx_style:_style,fx_radius:_radius,world_x:_wx,world_y:_wy});
}
