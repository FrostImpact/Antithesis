// A pale null horizon restores the reference's open, high-key atmosphere while
// the land's dark side planes carry the depth and isometric read.
draw_set_alpha(1);
draw_clear(make_colour_rgb(177,179,178));
draw_rectangle_colour(0,0,1366,768,
    make_colour_rgb(211,212,210),make_colour_rgb(211,212,210),
    make_colour_rgb(153,156,155),make_colour_rgb(153,156,155),false);

// Wide veils of value move almost imperceptibly through the empty realm.
for(var veil=0;veil<4;++veil) {
    var veil_x=100+veil*390+sin(elapsed*(0.022+veil*0.006)+veil)*46;
    var veil_y=170+(veil mod 2)*185+cos(elapsed*0.025+veil*1.6)*17;
    draw_set_alpha(0.025+veil*0.007);
    draw_set_colour(veil mod 2==0 ? c_white : make_colour_rgb(73,76,76));
    draw_ellipse(veil_x-270,veil_y-74,veil_x+270,veil_y+74,false);
}

// Connections periodically zip through physical world-space points, hold as a
// constellation, then vanish. Staggered cycles keep the realm quietly alive.
for(var constellation=0;constellation<array_length(sky_constellations);++constellation) {
    var branch=sky_constellations[constellation];
    var links=sky_constellation_links[constellation];
    var cycle=(elapsed+constellation*3.1) mod 10;
    var build=clamp(cycle/2.2,0,1);
    var presence=cycle<5.8 ? 1 : clamp((7.2-cycle)/1.4,0,1);
    if(presence<=0) continue;
    var projected=[];
    for(var point_index=0;point_index<array_length(branch);++point_index) {
        var point=branch[point_index];
        var flex=sin(elapsed*0.42+constellation*1.7+point_index)*3;
        projected[point_index]=[project_x(point[0],point[1]),
            project_y(point[0],point[1])-(point[2]+flex)*obj_camera.zoom];
    }
    for(var link_index=0;link_index<array_length(links);++link_index) {
        var connection=links[link_index];
        var a=projected[connection[0]]; var b=projected[connection[1]];
        var link_progress=clamp(build*array_length(links)-link_index,0,1);
        if(link_progress<=0) continue;
        var end_x=lerp(a[0],b[0],link_progress);
        var end_y=lerp(a[1],b[1],link_progress);
        draw_set_alpha(0.48*presence);
        draw_set_colour(make_colour_rgb(62,64,63));
        draw_line_width(a[0],a[1],end_x,end_y,1.35*obj_camera.zoom);
        // The bright head is the only accent: it visibly travels as the line forms.
        if(link_progress<1) {
            var tail=max(0,link_progress-0.2);
            draw_set_alpha(0.82*presence);
            draw_set_colour(make_colour_rgb(240,241,237));
            draw_line_width(lerp(a[0],b[0],tail),lerp(a[1],b[1],tail),end_x,end_y,2.2*obj_camera.zoom);
            diamond(end_x,end_y,3.6*obj_camera.zoom,1.8*obj_camera.zoom,c_white);
        }
    }
    for(var node=0;node<array_length(projected);++node) {
        var node_progress=clamp(build*array_length(projected)-node,0,1);
        if(node_progress<=0) continue;
        var np=projected[node];
        draw_set_alpha(0.62*presence*node_progress);
        diamond(np[0],np[1],3.1*obj_camera.zoom,1.55*obj_camera.zoom,make_colour_rgb(83,85,83));
    }
}

// A few fragments drift through the full depth of the void.
for(var mote=0;mote<12;++mote) {
    var mote_x=(93+mote*197) mod 1366;
    var mote_y=(86+mote*83+sin(elapsed*0.19+mote)*18) mod 660;
    var mote_size=1+(mote mod 3);
    draw_set_alpha(0.14+(mote mod 4)*0.035);
    draw_set_colour(mote mod 3==0 ? c_white : make_colour_rgb(91,94,93));
    draw_rectangle(mote_x-mote_size,mote_y-mote_size,mote_x+mote_size,mote_y+mote_size,false);
}

// The connected shelf system casts one broad, soft absence beneath it.
draw_set_alpha(0.22);
draw_set_colour(make_colour_rgb(47,49,50));
draw_ellipse(project_x(4,3)-500*obj_camera.zoom,project_y(4,3)-80*obj_camera.zoom,
    project_x(4,3)+500*obj_camera.zoom,project_y(4,3)+185*obj_camera.zoom,false);

// First render every exposed side plane. The two value families make the fixed
// 45-degree projection immediately legible from any zoom level.
for(var shelf_index=0;shelf_index<array_length(land_shelves);++shelf_index) {
    var shelf=land_shelves[shelf_index];
    var x1=shelf[0]; var y1=shelf[1]; var x2=shelf[2]; var y2=shelf[3];
    var shelf_depth=shelf[4]*obj_camera.zoom;
    var shelf_points=[[x1,y1],[x2,y1],[x2,y2],[x1,y2]];
    var centre_y=project_y((x1+x2)*0.5,(y1+y2)*0.5);
    for(var edge=0;edge<4;++edge) {
        var edge_a=shelf_points[edge]; var edge_b=shelf_points[(edge+1) mod 4];
        if(project_y((edge_a[0]+edge_b[0])*0.5,(edge_a[1]+edge_b[1])*0.5)<=centre_y) continue;
        var ax=project_x(edge_a[0],edge_a[1]); var ay=project_y(edge_a[0],edge_a[1]);
        var bx=project_x(edge_b[0],edge_b[1]); var by=project_y(edge_b[0],edge_b[1]);
        draw_set_alpha(1);
        draw_set_colour(edge==1 ? make_colour_rgb(92,95,95) : make_colour_rgb(116,119,118));
        draw_primitive_begin(pr_trianglefan);
        draw_vertex(ax,ay); draw_vertex(bx,by);
        draw_vertex(bx,by+shelf_depth); draw_vertex(ax,ay+shelf_depth);
        draw_primitive_end();
    }
}

// Lay the broad top planes over their shared edges. Slight value differences
// reveal the connected shelves without turning them into separate structures.
for(var shelf_index=0;shelf_index<array_length(land_shelves);++shelf_index) {
    var shelf=land_shelves[shelf_index];
    var x1=shelf[0]; var y1=shelf[1]; var x2=shelf[2]; var y2=shelf[3];
    var cx=(x1+x2)*0.5; var cy=(y1+y2)*0.5;
    var shelf_points=[[x1,y1],[x2,y1],[x2,y2],[x1,y2]];
    draw_set_alpha(1);
    draw_set_colour(make_colour_rgb(112,115,114));
    draw_primitive_begin(pr_trianglefan);
    for(var vertex=0;vertex<4;++vertex)
        draw_vertex(project_x(shelf_points[vertex][0],shelf_points[vertex][1]),
            project_y(shelf_points[vertex][0],shelf_points[vertex][1]));
    draw_primitive_end();
    draw_set_colour(shelf_index==0 ? make_colour_rgb(218,219,216) :
        make_colour_rgb(207+shelf_index mod 2*5,208+shelf_index mod 2*5,205+shelf_index mod 2*5));
    draw_primitive_begin(pr_trianglefan);
    for(var vertex=0;vertex<4;++vertex) {
        var inset_x=lerp(shelf_points[vertex][0],cx,0.035);
        var inset_y=lerp(shelf_points[vertex][1],cy,0.045);
        draw_vertex(project_x(inset_x,inset_y),project_y(inset_x,inset_y));
    }
    draw_primitive_end();
}

// A faint stress lattice lets the eye measure the isometric plane. Its uneven
// opacity makes it feel like quantised geology surfacing through the stone.
draw_set_colour(make_colour_rgb(105,109,109));
for(var gx=0;gx<=8;++gx) {
    draw_set_alpha(0.065+0.025*sin(gx*1.8));
    draw_line(project_x(gx,0),project_y(gx,0),project_x(gx,6),project_y(gx,6));
}
for(var gy=0;gy<=6;++gy) {
    draw_set_alpha(0.065+0.025*cos(gy*2.1));
    draw_line(project_x(0,gy),project_y(0,gy),project_x(8,gy),project_y(8,gy));
}

// Cut a recessed absence into the top plane. Bright far walls and the black
// floor make this read as real depth instead of a symbol painted on the map.
for(var void_index=0;void_index<array_length(void_regions);++void_index) {
    var region=void_regions[void_index];
    var hx1=region[0]; var hy1=region[1]; var hx2=region[2]; var hy2=region[3];
    var rim_points=[[hx1-0.14,hy1-0.14],[hx2+0.14,hy1-0.14],[hx2+0.14,hy2+0.14],[hx1-0.14,hy2+0.14]];
    var hole_points=[[hx1,hy1],[hx2,hy1],[hx2,hy2],[hx1,hy2]];
    var aperture=[];
    for(var corner=0;corner<4;++corner) array_push(aperture,[project_x(hole_points[corner][0],hole_points[corner][1]),project_y(hole_points[corner][0],hole_points[corner][1])]);
    draw_set_alpha(1);
    draw_set_colour(make_colour_rgb(92,96,96));
    draw_primitive_begin(pr_trianglefan);
    for(var vertex=0;vertex<4;++vertex)
        draw_vertex(project_x(rim_points[vertex][0],rim_points[vertex][1]),project_y(rim_points[vertex][0],rim_points[vertex][1]));
    draw_primitive_end();
    draw_set_colour(make_colour_rgb(43,46,47));
    draw_primitive_begin(pr_trianglefan);
    for(var vertex=0;vertex<4;++vertex)
        draw_vertex(project_x(hole_points[vertex][0],hole_points[vertex][1]),project_y(hole_points[vertex][0],hole_points[vertex][1]));
    draw_primitive_end();
    var hole_centre_y=project_y((hx1+hx2)*0.5,(hy1+hy2)*0.5);
    for(var edge=0;edge<4;++edge) {
        var edge_a=hole_points[edge]; var edge_b=hole_points[(edge+1) mod 4];
        if(project_y((edge_a[0]+edge_b[0])*0.5,(edge_a[1]+edge_b[1])*0.5)>=hole_centre_y) continue;
        var ax=project_x(edge_a[0],edge_a[1]); var ay=project_y(edge_a[0],edge_a[1]);
        var bx=project_x(edge_b[0],edge_b[1]); var by=project_y(edge_b[0],edge_b[1]);
        var inner_depth=31*obj_camera.zoom;
        draw_set_colour(edge==0 ? make_colour_rgb(153,156,154) : make_colour_rgb(126,130,129));
        map_draw_polygon(map_clip_polygon([[ax,ay],[bx,by],[bx,by+inner_depth],[ax,ay+inner_depth]],aperture));
    }
}

// The route is the only intentional-looking surface: dark, broad and legible.
draw_set_alpha(1);
for(var i=0;i<array_length(route);++i)
    draw_ground_tile(route[i][0],route[i][1],make_colour_rgb(112,116,117));
var offsets=[[-0.5,-0.5],[0.5,-0.5],[0.5,0.5],[-0.5,0.5]];
var neighbours=[[0,-1],[1,0],[0,1],[-1,0]];
for(var i=0;i<array_length(route);++i) {
    var wx=route[i][0]; var wy=route[i][1];
    for(var side=0;side<4;++side) {
        if(is_path(wx+neighbours[side][0],wy+neighbours[side][1])) continue;
        var side_a=offsets[side]; var side_b=offsets[(side+1) mod 4];
        var path_ax=project_x(wx+side_a[0],wy+side_a[1]); var path_ay=project_y(wx+side_a[0],wy+side_a[1]);
        var path_bx=project_x(wx+side_b[0],wy+side_b[1]); var path_by=project_y(wx+side_b[0],wy+side_b[1]);
        draw_set_colour(make_colour_rgb(70,74,76));
        draw_line_width(path_ax,path_ay,path_bx,path_by,3*obj_camera.zoom);
        draw_set_colour(make_colour_rgb(222,223,219));
        draw_line(path_ax,path_ay-2*obj_camera.zoom,path_bx,path_by-2*obj_camera.zoom);
    }
}

// Low colour-coded endpoint platforms sit over the route and behind actors.
map_draw_spawn_platform(route,elapsed);
map_draw_base_platform(route,elapsed);

// Grounded shadows are drawn once, beneath every actor (including hover glows).
for(var tower_index=0;tower_index<instance_number(obj_tower);++tower_index)
    tower_draw_shadow(instance_find(obj_tower,tower_index));

draw_set_alpha(1);
ui_draw_world_feedback();

for(var medic_index=0;medic_index<instance_number(obj_tower);++medic_index) triage_draw_support(instance_find(obj_tower,medic_index));
