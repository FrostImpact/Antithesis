var visual_scale=obj_camera.zoom;
draw_set_alpha(0.16);
draw_set_colour(make_colour_rgb(76,80,82));
draw_ellipse(x-20*visual_scale,y-7*visual_scale,x+23*visual_scale,y+10*visual_scale,false);
draw_set_alpha(1);
var flash=hit_flash/0.15;
// A small contact squash is visual only; path position and hit testing stay fixed.
block(x,y+(-5+sin(elapsed*7)*3)*visual_scale,13*(1+flash*0.08)*visual_scale,7*visual_scale,25*(1-flash*0.1)*visual_scale,
    merge_colour(make_colour_rgb(131,137,137),c_white,flash),
    merge_colour(make_colour_rgb(66,75,73),c_white,flash),
    merge_colour(make_colour_rgb(101,112,107),c_white,flash));

// LOCK is shown in-world with two clean chains from the ground to the body.
if(lock_visual>0.01) {
    var bind=lock_visual*lock_visual*(3-2*lock_visual);
    var chain_light=make_colour_rgb(104,220,232);
    draw_set_alpha(bind*0.82);
    draw_set_colour(chain_light);
    for(var side=-1;side<=1;side+=2) {
        var anchor_x=x+side*16*bind*visual_scale;
        var anchor_y=y+5*visual_scale;
        var attach_x=x+side*4*visual_scale;
        var attach_y=y-15*visual_scale;
        draw_line_width(anchor_x,anchor_y,attach_x,attach_y,1.4*visual_scale);
        var link_t=0.52*bind;
        diamond(lerp(anchor_x,attach_x,link_t),lerp(anchor_y,attach_y,link_t),
            1.7*visual_scale,0.85*visual_scale,chain_light);
        diamond(anchor_x,anchor_y,3.2*visual_scale,1.6*visual_scale,chain_light);
    }
    draw_set_alpha(1);
}
