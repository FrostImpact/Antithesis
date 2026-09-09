// Angular white crystal outcrops, with dark contact shading and detached tips.
var visual_scale=obj_camera.zoom;
var w=radius*50*visual_scale;
var h=elevation*visual_scale;
var t=obj_world.elapsed;
if(variable_instance_exists(id,"terrain_style") && terrain_style=="null_pillar") {
    draw_set_alpha(0.16);
    diamond(x+7*visual_scale,y+6*visual_scale,w*1.3,w*0.58,make_colour_rgb(58,61,61));
    draw_set_alpha(1);
    // One uninterrupted mass per root. Neighbouring pillars provide the shape;
    // the individual mountain carries no small-scale decoration.
    block(x,y,w,w*0.46,h,
        make_colour_rgb(204,205,201),make_colour_rgb(82,85,85),make_colour_rgb(113,116,115));
    exit;
}
if(variable_instance_exists(id,"terrain_style") && terrain_style=="rift_spire") {
    var phase=shape_phase;
    var breathe=sin(t*0.62+phase)*1.4*visual_scale;
    var lean=sin(phase*2.3)*w*0.22;
    draw_set_alpha(0.2);
    diamond(x+5*visual_scale,y+4*visual_scale,w+8*visual_scale,w*0.48,make_colour_rgb(48,54,57));
    draw_set_alpha(1);
    // Uneven faces taper, lean and split; no two clustered growths share a silhouette.
    draw_set_colour(make_colour_rgb(87,92,93));
    draw_primitive_begin(pr_trianglefan);
    draw_vertex(x-w,y); draw_vertex(x-lean*0.4,y-h*0.48);
    draw_vertex(x+lean,y-h+breathe); draw_vertex(x-2*visual_scale,y+4*visual_scale);
    draw_primitive_end();
    draw_set_colour(make_colour_rgb(142,145,143));
    draw_primitive_begin(pr_trianglefan);
    draw_vertex(x-2*visual_scale,y+4*visual_scale); draw_vertex(x+lean,y-h+breathe);
    draw_vertex(x+w*0.72,y-h*0.34); draw_vertex(x+w,y);
    draw_primitive_end();
    draw_set_colour(make_colour_rgb(205,206,201));
    draw_primitive_begin(pr_trianglefan);
    draw_vertex(x-w,y); draw_vertex(x+lean,y-h+breathe);
    draw_vertex(x+w,y); draw_vertex(x-2*visual_scale,y+4*visual_scale);
    draw_primitive_end();
    // A small torn fragment hangs above the fracture and drifts in place.
    var fragment_y=y-h-(8+sin(t*0.9+phase)*2)*visual_scale;
    draw_set_alpha(0.72);
    diamond(x+lean*1.15,fragment_y,w*0.28,w*0.13,make_colour_rgb(186,188,184));
    draw_set_alpha(1);
    exit;
}
draw_set_alpha(0.15);
diamond(x+5,y+3,w+8,w*0.45,make_colour_rgb(97,113,124));
draw_set_alpha(1);
draw_set_colour(make_colour_rgb(196,209,218));
draw_triangle(x-w,y,x,y-h,x+2,y+6,false);
draw_set_colour(make_colour_rgb(235,241,245));
draw_triangle(x,y-h,x+w,y,x+2,y+6,false);
draw_set_colour(c_white);
draw_triangle(x-w,y,x,y-h,x-5,y-5,false);
var float_y=sin(t*0.8+world_x)*2*visual_scale;
draw_set_colour(make_colour_rgb(222,232,240));
draw_triangle(x-4,y-h-7+float_y,x+5,y-h-6+float_y,x,y-h-18+float_y,false);
draw_set_colour(c_white);
draw_line(x,y-h+3,x+2,y-3);
// Detached splinters orbit slowly in opposing phases, reinforcing the broken-null motif.
for(var splinter=0;splinter<3;++splinter) {
    var orbit=t*(12+splinter*4)+world_x*31+splinter*120;
    var ox=dcos(orbit)*(w+(7+splinter*2)*visual_scale);
    var oy=dsin(orbit)*(3+splinter)*visual_scale-h*(0.35+splinter*0.16);
    draw_set_alpha(0.45+splinter*0.16);
    draw_set_colour(splinter==0 ? make_colour_rgb(132,220,234) : make_colour_rgb(205,218,224));
    draw_triangle(x+ox-2*visual_scale,y+oy+2*visual_scale,x+ox+2*visual_scale,y+oy,x+ox,y+oy-6*visual_scale,false);
}
draw_set_alpha(1);
