// Smooth wheel zoom and synchronize rendering after enemies move.
var dt=min(delta_time/1000000,0.05);
zoom=lerp(zoom,target_zoom,1-exp(-12*dt));
camera_sync_actors();
