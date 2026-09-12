// All generic combat uses one implementation; actor instances hold independent state.
if(!obj_game.paused) triage_tick_support(min(delta_time/1000000,0.05));
with(obj_tower) tower_tick();
