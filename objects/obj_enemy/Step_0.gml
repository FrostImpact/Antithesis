if (obj_game.paused) exit;
var dt=min(delta_time/1000000,0.05);
elapsed+=dt;
hit_flash=max(0,hit_flash-dt);
lock_visual=lerp(lock_visual,lock_left>0 ? 1 : 0,1-exp(-(lock_left>0 ? 18 : 9)*dt));
// Hold the old health briefly on contact, then ease the damage segment away.
if(hit_flash<=0) display_hit_points=lerp(display_hit_points,hit_points,1-exp(-9*dt));
var route=obj_world.route;
// Finish materializing at the entrance before joining the route or taking hits.
var active_dt=max(0,dt-spawn_left);
spawn_left=max(0,spawn_left-dt);
var walking_dt=enemy_definition.model=="lancer" ? enemy_tick_laser(id,active_dt) : active_dt;
// Debuffs still expire while the laser holds the enemy stationary.
var movement_dt=enemy_movement_time(id,active_dt);
if(walking_dt<=0) movement_dt=0;
progress=min(progress+enemy_definition.move_speed*movement_dt,array_length(route)-1);
var segment=min(floor(progress),array_length(route)-2);
var fraction=progress-segment;
world_x=lerp(route[segment][0],route[segment+1][0],fraction);
world_y=lerp(route[segment][1],route[segment+1][1],fraction);
// Articulated fragment motion uses all 48 poses. Root and pause hold it.
drift_phase=(drift_phase+movement_dt/enemy_definition.drift_period*pi*2) mod (pi*2);
x=project_x(world_x,world_y);
y=project_y(world_x,world_y);
depth=-y;
if (progress>=array_length(route)-1) { encounter_record_escape(); instance_destroy(); }


