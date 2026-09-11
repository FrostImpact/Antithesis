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
    // Subtract shelf rectangles from the footprint: touching shelves form one
    // surface, while narrow gaps and partially unsupported footprints still fail.
    var uncovered=[[_x-_margin,_y-_margin,_x+_margin,_y+_margin]];
    for(var i=0;i<array_length(obj_world.land_shelves);++i) {
        var shelf=obj_world.land_shelves[i]; var remaining=[];
        for(var part=0;part<array_length(uncovered);++part) {
            var r=uncovered[part];
            var x1=max(r[0],shelf[0]); var y1=max(r[1],shelf[1]);
            var x2=min(r[2],shelf[2]); var y2=min(r[3],shelf[3]);
            if(x1>x2 || y1>y2) { array_push(remaining,r); continue; }
            if(r[0]<x1) array_push(remaining,[r[0],r[1],x1,r[3]]);
            if(x2<r[2]) array_push(remaining,[x2,r[1],r[2],r[3]]);
            if(r[1]<y1) array_push(remaining,[x1,r[1],x2,y1]);
            if(y2<r[3]) array_push(remaining,[x1,y2,x2,r[3]]);
        }
        uncovered=remaining;
    }
    if(array_length(uncovered)>0) return false;
    for(var i=0;i<array_length(obj_world.void_regions);++i) {
        if(map_point_in_region(_x,_y,obj_world.void_regions[i],-(_margin+0.14))) return false;
    }
    return true;
}

// Clip a convex screen polygon to the projected aperture. Inner walls must
// never escape its rim, regardless of hole size, depth or camera zoom.
function map_clip_polygon(_polygon,_clip) {
    var result=_polygon;
    for(var edge=0;edge<array_length(_clip);++edge) {
        if(array_length(result)==0) break;
        var a=_clip[edge]; var b=_clip[(edge+1) mod array_length(_clip)];
        var input=result; result=[];
        var previous=input[array_length(input)-1];
        var previous_side=(b[0]-a[0])*(previous[1]-a[1])-(b[1]-a[1])*(previous[0]-a[0]);
        for(var i=0;i<array_length(input);++i) {
            var current=input[i];
            var side=(b[0]-a[0])*(current[1]-a[1])-(b[1]-a[1])*(current[0]-a[0]);
            if((side>=0)!=(previous_side>=0)) {
                var t=previous_side/(previous_side-side);
                array_push(result,[lerp(previous[0],current[0],t),lerp(previous[1],current[1],t)]);
            }
            if(side>=0) array_push(result,current);
            previous=current; previous_side=side;
        }
    }
    return result;
}
function map_draw_polygon(_points) {
    if(array_length(_points)<3) return;
    draw_primitive_begin(pr_trianglefan);
    for(var i=0;i<array_length(_points);++i) draw_vertex(_points[i][0],_points[i][1]);
    draw_primitive_end();
}

// The route begins at a complete aperture: an upright mineral ring around a
// deep void. It is drawn from the authored first route node, so map edits move
// the landmark without introducing another position to maintain.
function map_draw_spawn_portal(_route,_time) {
    if(array_length(_route)<2) return;
    var point=_route[0];
    var sx=project_x(point[0],point[1]);
    var ground_y=project_y(point[0],point[1]);
    var zoom=obj_camera.zoom;
    var pulse=0.5+0.5*sin(_time*1.15);
    var centre_y=ground_y-35*zoom;
    var outer_w=(29+pulse*1.2)*zoom;
    var outer_h=(43+pulse*1.4)*zoom;
    var inner_w=19*zoom;
    var inner_h=32*zoom;

    draw_set_alpha(0.22);
    diamond(sx+3*zoom,ground_y+3*zoom,35*zoom,9*zoom,make_colour_rgb(31,37,39));
    draw_set_alpha(0.96);
    draw_set_colour(make_colour_rgb(9,14,18));
    draw_ellipse(sx-inner_w,centre_y-inner_h,sx+inner_w,centre_y+inner_h,false);

    // Individual blocks create a broken stone ring instead of a clean machine.
    for(var segment=0;segment<16;++segment) {
        var a0=segment/16*360;
        var a1=(segment+0.78)/16*360;
        var variation=1+0.055*sin(segment*4.7);
        var ox0=sx+dcos(a0)*outer_w*variation;
        var oy0=centre_y+dsin(a0)*outer_h*variation;
        var ox1=sx+dcos(a1)*outer_w*variation;
        var oy1=centre_y+dsin(a1)*outer_h*variation;
        var ix0=sx+dcos(a0)*inner_w;
        var iy0=centre_y+dsin(a0)*inner_h;
        var ix1=sx+dcos(a1)*inner_w;
        var iy1=centre_y+dsin(a1)*inner_h;
        draw_set_alpha(1);
        draw_set_colour(segment mod 3==0 ? make_colour_rgb(237,238,233) :
            (segment mod 3==1 ? make_colour_rgb(151,158,157) : make_colour_rgb(83,90,92)));
        draw_primitive_begin(pr_trianglefan);
        draw_vertex(ox0,oy0); draw_vertex(ox1,oy1);
        draw_vertex(ix1,iy1); draw_vertex(ix0,iy0);
        draw_primitive_end();
    }

    // A restrained internal current gives the entrance life without particles.
    for(var current=0;current<3;++current) {
        var current_y=centre_y+(current-1)*13*zoom+sin(_time*1.4+current*2)*3*zoom;
        draw_set_alpha(0.24+current*0.08);
        draw_set_colour(make_colour_rgb(180,213,210));
        draw_line_width(sx-inner_w*0.55,current_y,sx+inner_w*0.55,current_y-5*zoom,
            (1+current*0.35)*zoom);
    }
    draw_set_alpha(1);
}

// The base is an unstable tear rather than a second portal. Its asymmetrical
// silhouette and loose shell pieces make the destination visually distinct.
function map_draw_base_rift(_route,_time) {
    if(array_length(_route)<2) return;
    var point=_route[array_length(_route)-1];
    var sx=project_x(point[0],point[1]);
    var ground_y=project_y(point[0],point[1]);
    var zoom=obj_camera.zoom;
    var breathe=sin(_time*0.82)*2*zoom;
    var centre_y=ground_y-31*zoom;

    draw_set_alpha(0.24);
    diamond(sx-2*zoom,ground_y+3*zoom,31*zoom,8*zoom,make_colour_rgb(30,36,39));

    // A black, jagged opening with a cool inner seam.
    draw_set_alpha(0.98);
    draw_set_colour(make_colour_rgb(8,13,17));
    draw_primitive_begin(pr_trianglefan);
    draw_vertex(sx-3*zoom,centre_y-39*zoom-breathe);
    draw_vertex(sx+8*zoom,centre_y-24*zoom);
    draw_vertex(sx+4*zoom,centre_y-9*zoom);
    draw_vertex(sx+10*zoom,centre_y+8*zoom);
    draw_vertex(sx+2*zoom,centre_y+36*zoom+breathe);
    draw_vertex(sx-7*zoom,centre_y+17*zoom);
    draw_vertex(sx-4*zoom,centre_y+1*zoom);
    draw_vertex(sx-10*zoom,centre_y-17*zoom);
    draw_primitive_end();
    draw_set_alpha(0.64+0.18*sin(_time*1.65));
    draw_set_colour(make_colour_rgb(190,222,218));
    draw_line_width(sx-1*zoom,centre_y-28*zoom,sx+2*zoom,centre_y+27*zoom,1.5*zoom);

    // Four separated mineral braces breathe away from the opening.
    for(var shard=0;shard<4;++shard) {
        var side=shard mod 2==0 ? -1 : 1;
        var level=floor(shard/2);
        var spread=(16+level*7+sin(_time*0.82+shard)*1.5)*zoom;
        var cy=centre_y+(level==0 ? -20 : 17)*zoom;
        var sw=(6+level*2)*zoom;
        var sh=(14-level*3)*zoom;
        draw_set_alpha(1);
        draw_set_colour(shard mod 3==0 ? make_colour_rgb(231,233,227) :
            (shard mod 3==1 ? make_colour_rgb(145,153,153) : make_colour_rgb(77,85,88)));
        draw_primitive_begin(pr_trianglefan);
        draw_vertex(sx+side*(spread+sw),cy);
        draw_vertex(sx+side*spread,cy-sh);
        draw_vertex(sx+side*(spread-sw*0.35),cy+sh*0.72);
        draw_primitive_end();
    }

    // Hairline cracks bind the rift to the surface at the final route tile.
    draw_set_alpha(0.5);
    draw_set_colour(make_colour_rgb(67,74,77));
    for(var crack=0;crack<4;++crack) {
        var angle=22+crack*47;
        var length=(18+crack*3)*zoom;
        draw_line_width(sx,ground_y,sx+dcos(angle)*length,
            ground_y+dsin(angle)*length*0.34,1.2*zoom);
    }
    draw_set_alpha(1);
}

// Low endpoint platforms keep the route readable and leave enemy silhouettes
// unobstructed. Colour and icon communicate the function at a glance.
function map_draw_endpoint_platform(_point,_accent,_shield,_time) {
    var half=0.5; // One world tile, exactly matching the route footprint.
    var corners=[
        [_point[0]-half,_point[1]-half],[_point[0]+half,_point[1]-half],
        [_point[0]+half,_point[1]+half],[_point[0]-half,_point[1]+half]
    ];
    var screen=[];
    for(var i=0;i<4;++i)
        screen[i]=[project_x(corners[i][0],corners[i][1]),project_y(corners[i][0],corners[i][1])];
    var sx=project_x(_point[0],_point[1]);
    var sy=project_y(_point[0],_point[1]);
    var zoom=obj_camera.zoom;
    var pulse=0.78+0.22*sin(_time*1.35);

    draw_set_alpha(0.3);
    draw_set_colour(make_colour_rgb(31,37,39));
    draw_primitive_begin(pr_trianglefan);
    for(var i=0;i<4;++i) draw_vertex(screen[i][0],screen[i][1]+6*zoom);
    draw_primitive_end();
    draw_set_alpha(1);
    draw_set_colour(make_colour_rgb(48,54,56));
    draw_primitive_begin(pr_trianglefan);
    for(var i=0;i<4;++i) draw_vertex(screen[i][0],screen[i][1]);
    draw_primitive_end();

    // A strong perimeter and quieter inset line define the platform surface.
    draw_set_colour(_accent);
    draw_set_alpha(0.78+0.18*pulse);
    for(var edge=0;edge<4;++edge) {
        var next=(edge+1) mod 4;
        draw_line_width(screen[edge][0],screen[edge][1],
            screen[next][0],screen[next][1],3.2*zoom);
    }
    var inset=0.26;
    draw_set_alpha(0.35+0.18*pulse);
    for(var edge=0;edge<4;++edge) {
        var next=(edge+1) mod 4;
        draw_line_width(lerp(screen[edge][0],sx,inset),lerp(screen[edge][1],sy,inset),
            lerp(screen[next][0],sx,inset),lerp(screen[next][1],sy,inset),1.2*zoom);
    }

    draw_set_alpha(1);
    draw_set_colour(_accent);
    if(_shield) {
        // Aqua shield: broad shoulders, tapered point and a central brace.
        var iw=12*zoom; var ih=12*zoom;
        draw_line_width(sx-iw,sy-ih*0.65,sx,sy-ih,2.4*zoom);
        draw_line_width(sx,sy-ih,sx+iw,sy-ih*0.65,2.4*zoom);
        draw_line_width(sx+iw,sy-ih*0.65,sx+iw*0.72,sy+ih*0.45,2.4*zoom);
        draw_line_width(sx+iw*0.72,sy+ih*0.45,sx,sy+ih,2.4*zoom);
        draw_line_width(sx,sy+ih,sx-iw*0.72,sy+ih*0.45,2.4*zoom);
        draw_line_width(sx-iw*0.72,sy+ih*0.45,sx-iw,sy-ih*0.65,2.4*zoom);
        draw_line_width(sx,sy-ih*0.55,sx,sy+ih*0.55,1.4*zoom);
    } else {
        // Red warning triangle and exclamation mark identify enemy entry.
        var iw=13*zoom; var ih=12*zoom;
        draw_line_width(sx,sy-ih,sx+iw,sy+ih*0.8,2.5*zoom);
        draw_line_width(sx+iw,sy+ih*0.8,sx-iw,sy+ih*0.8,2.5*zoom);
        draw_line_width(sx-iw,sy+ih*0.8,sx,sy-ih,2.5*zoom);
        draw_line_width(sx,sy-ih*0.35,sx,sy+ih*0.25,2.2*zoom);
        diamond(sx,sy+ih*0.52,1.8*zoom,1.2*zoom,_accent);
    }
    draw_set_alpha(1);
}

function map_draw_spawn_platform(_route,_time) {
    if(array_length(_route)<2) return;
    map_draw_endpoint_platform(_route[0],make_colour_rgb(235,61,69),false,_time);
}

function map_draw_base_platform(_route,_time) {
    if(array_length(_route)<2) return;
    map_draw_endpoint_platform(_route[array_length(_route)-1],make_colour_rgb(103,226,221),true,_time);
}
