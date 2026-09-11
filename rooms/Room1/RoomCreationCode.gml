instance_create_depth(0,0,100,obj_game);
instance_create_depth(0,0,100,obj_camera);
instance_create_depth(0,0,50,obj_world);
instance_create_depth(0,0,100,obj_input);
instance_create_depth(0,0,0,obj_encounter);
instance_create_depth(0,0,100,obj_combat);
// Keep GUI inside GameMaker's drawable depth range (-16000..16000).
instance_create_depth(0,0,-15000,obj_ui);
