// Room Editor coordinates are a simple top-down authoring grid. Runtime code
// projects that data into the game's isometric view.
function map_editor_to_world(_x,_y) {
    var config=obj_game.config;
    return [(_x-config.map_editor_origin_x)/config.map_editor_grid,
        (_y-config.map_editor_origin_y)/config.map_editor_grid];
}

function map_collect_route() {
    var nodes=[];
    for(var i=0;i<instance_number(obj_map_route);++i) {
        var marker=instance_find(obj_map_route,i);
        var point=map_editor_to_world(marker.x,marker.y);
        array_push(nodes,{order:round(marker.image_index),x:point[0],y:point[1]});
    }
    // A tiny insertion sort keeps route order deterministic without relying on
    // room instance creation order.
    for(var a=1;a<array_length(nodes);++a) {
        var key=nodes[a]; var b=a-1;
        while(b>=0 && nodes[b].order>key.order) {
            nodes[b+1]=nodes[b];
            --b;
        }
        nodes[b+1]=key;
    }
    var route=array_create(array_length(nodes));
    for(var node=0;node<array_length(nodes);++node) route[node]=[nodes[node].x,nodes[node].y];
    return route;
}

function map_collect_regions(_object,_kind) {
    var regions=[];
    for(var i=0;i<instance_number(_object);++i) {
        var marker=instance_find(_object,i);
        var centre=map_editor_to_world(marker.x,marker.y);
        var half_width=abs(marker.image_xscale)*0.5;
        var half_height=abs(marker.image_yscale)*0.5;
        var region=[centre[0]-half_width,centre[1]-half_height,
            centre[0]+half_width,centre[1]+half_height];
        if(_kind==MapRegionKind.Surface) array_push(region,max(1,marker.image_index));
        array_push(regions,region);
    }
    return regions;
}

function map_spawn_terrain() {
    for(var i=0;i<instance_number(obj_map_terrain);++i) {
        var marker=instance_find(obj_map_terrain,i);
        var point=map_editor_to_world(marker.x,marker.y);
        var elevation=max(24,abs(marker.image_yscale)*100);
        instance_create_depth(project_x(point[0],point[1]),project_y(point[0],point[1]),
            -project_y(point[0],point[1]),obj_terrain,{
                world_x:point[0],world_y:point[1],radius:abs(marker.image_xscale),
                elevation:elevation,shape_phase:marker.image_angle,terrain_style:"null_pillar"
            });
    }
}

function map_point_in_region(_x,_y,_region,_margin=0) {
    return _x>=_region[0]+_margin && _x<=_region[2]-_margin &&
        _y>=_region[1]+_margin && _y<=_region[3]-_margin;
}

function map_point_on_surface(_x,_y,_margin=0) {
    if(!instance_exists(obj_world)) return false;
    var on_surface=false;
    for(var i=0;i<array_length(obj_world.land_shelves);++i) {
        if(map_point_in_region(_x,_y,obj_world.land_shelves[i],_margin)) {
            on_surface=true;
            break;
        }
    }
    if(!on_surface) return false;
    for(var i=0;i<array_length(obj_world.void_regions);++i) {
        if(map_point_in_region(_x,_y,obj_world.void_regions[i],-_margin)) return false;
    }
    return true;
}
