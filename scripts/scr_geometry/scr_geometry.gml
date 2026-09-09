// Fixed isometric projection with a smooth, simulation-independent camera zoom.
function project_x(_x,_y) {
    var a=obj_camera.map_angle;
    return 683+((_x-4)*dcos(a)-(_y-3)*dsin(a))*69.29646456*obj_camera.zoom;
}
function project_y(_x,_y) {
    var a=obj_camera.map_angle;
    return 380+((_x-4)*dsin(a)+(_y-3)*dcos(a))*35.35533906*obj_camera.zoom;
}
function unproject(_x,_y) {
    var a=obj_camera.map_angle;
    var scale=max(0.001,obj_camera.zoom);
    var u=(_x-683)/(69.29646456*scale); var v=(_y-380)/(35.35533906*scale);
    return [4+u*dcos(a)+v*dsin(a),3-u*dsin(a)+v*dcos(a)];
}
function draw_ground_tile(_x,_y,_colour) {
    draw_set_colour(_colour);
    draw_primitive_begin(pr_trianglefan);
    draw_vertex(project_x(_x-0.5,_y-0.5),project_y(_x-0.5,_y-0.5));
    draw_vertex(project_x(_x+0.5,_y-0.5),project_y(_x+0.5,_y-0.5));
    draw_vertex(project_x(_x+0.5,_y+0.5),project_y(_x+0.5,_y+0.5));
    draw_vertex(project_x(_x-0.5,_y+0.5),project_y(_x-0.5,_y+0.5));
    draw_primitive_end();
}
function is_path(_x, _y) {
    for (var i = 0; i < array_length(obj_world.route); ++i) {
        if (obj_world.route[i][0] == _x && obj_world.route[i][1] == _y) return true;
    }
    return false;
};
function diamond(_x, _y, _w, _h, _colour) {
    draw_set_colour(_colour);
    draw_primitive_begin(pr_trianglefan);
    draw_vertex(_x, _y - _h);
    draw_vertex(_x + _w, _y);
    draw_vertex(_x, _y + _h);
    draw_vertex(_x - _w, _y);
    draw_primitive_end();
};
function block(_x, _y, _w, _d, _height, _top, _left, _right) {
    draw_set_colour(_left);
    draw_primitive_begin(pr_trianglefan);
    draw_vertex(_x - _w, _y - _height);
    draw_vertex(_x, _y + _d - _height);
    draw_vertex(_x, _y + _d);
    draw_vertex(_x - _w, _y);
    draw_primitive_end();
    draw_set_colour(_right);
    draw_primitive_begin(pr_trianglefan);
    draw_vertex(_x, _y + _d - _height);
    draw_vertex(_x + _w, _y - _height);
    draw_vertex(_x + _w, _y);
    draw_vertex(_x, _y + _d);
    draw_primitive_end();
    diamond(_x, _y - _height, _w, _d, _top);
};


function draw_range(_wx,_wy,_radius) {
    draw_primitive_begin(pr_linestrip);
    for (var i=0; i<=96; ++i) {
        var a=i/96*360;
        draw_vertex(project_x(_wx+dcos(a)*_radius,_wy+dsin(a)*_radius),project_y(_wx+dcos(a)*_radius,_wy+dsin(a)*_radius));
    }
    draw_primitive_end();
}







function camera_sync_actors() {
    with(obj_tower) { x=project_x(world_x,world_y); y=project_y(world_x,world_y); depth=-y; }
    with(obj_enemy) { x=project_x(world_x,world_y); y=project_y(world_x,world_y); depth=-y; }
    with(obj_terrain) { x=project_x(world_x,world_y); y=project_y(world_x,world_y); depth=-y; }
}
