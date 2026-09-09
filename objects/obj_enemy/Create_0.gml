progress=0;
// Avoid GameMaker's built-in global health variable; combat state is per enemy.
if(!variable_instance_exists(id,"enemy_type")) enemy_type="intrusion";
enemy_definition=variable_struct_get(obj_game.enemy_catalog,enemy_type);
hit_points=enemy_definition.max_hit_points;
display_hit_points=hit_points;
hit_flash=0;
shock_stacks=0;
shock_left=0;
shock_slow=0;
lock_left=0;
lock_visual=0;
world_x=obj_world.route[0][0];
world_y=obj_world.route[0][1];
x=project_x(world_x,world_y);
y=project_y(world_x,world_y);
depth=-y;
elapsed=0;
max_hit_points=enemy_definition.max_hit_points;


