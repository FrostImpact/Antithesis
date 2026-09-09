if(obj_game.paused) exit;
var dt=min(delta_time/1000000,0.05);
age+=dt;
for(var i=0;i<array_length(particles);++i) {
    var p=particles[i];
    p.wx+=p.vx*dt; p.wy+=p.vy*dt;
    p.z+=p.vz*dt; p.vz-=140*dt;
    p.rotation+=p.spin*dt;
}
if(age>=lifetime) instance_destroy();
