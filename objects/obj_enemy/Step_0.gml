if (obj_game.paused) exit;
var dt=min(delta_time/1000000,0.05);
elapsed+=dt;
hit_flash=max(0,hit_flash-dt);
lock_visual=lerp(lock_visual,lock_left>0 ? 1 : 0,1-exp(-(lock_left>0 ? 18 : 9)*dt));
// Hold the old health briefly on contact, then ease the damage segment away.
if(hit_flash<=0) display_hit_points=lerp(display_hit_points,hit_points,1-exp(-9*dt));
var route=obj_world.route;
progress=min(progress+enemy_definition.move_speed*enemy_movement_time(id,dt),array_length(route)-1);
var segment=min(floor(progress),array_length(route)-2);
var fraction=progress-segment;
world_x=lerp(route[segment][0],route[segment+1][0],fraction);
world_y=lerp(route[segment][1],route[segment+1][1],fraction);
x=project_x(world_x,world_y);
y=project_y(world_x,world_y);
depth=-y;
if (progress>=array_length(route)-1) instance_destroy();


