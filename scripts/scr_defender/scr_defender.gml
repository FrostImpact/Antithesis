// Reference model proportions are built at 100 units and displayed at enemy scale.
function defender_point(_x,_y,_u,_v,_z,_angle,_visual_scale=1) {
    var scale=0.36*_visual_scale;
    var posture=clamp((_z-12)/40,0,1);
    _v+=posture*7; // Forward torso lean above planted feet.
    _z-=posture*5; // Relaxed crouch rather than a straight upright stance.
    var gx=(_u*dsin(_angle)+_v*dcos(_angle))*scale;
    var gy=(_u*dcos(_angle)-_v*dsin(_angle))*scale;
    return [_x+gx,_y+gy*0.5-_z*scale,gy+_z*scale*0.5];
}
// Shoulder and elbow joints drive both the visible weapon and its firing origin.
function defender_pose(_time,_kick,_aim,_charge=0,_recovery=0) {
    // Quintic easing keeps the articulated rig smooth at both ends of every pose.
    var a=clamp(_aim,0,1); a=a*a*a*(a*(a*6-15)+10);
    var charge=clamp(_charge,0,1); charge=charge*charge*(3-2*charge);
    var breath=sin(_time*2.1);
    var sway=sin(_time*1.05+0.4)*1.8*(1-a*0.65);
    var bob=breath*1.25+sin(_time*4.2+0.8)*0.28-charge*2.5-sin(_recovery*pi)*3;
    var shoulder=lerp(8+sin(_time*1.3)*5+breath*1.5,68,a);
    var elbow=lerp(20+sin(_time*1.3+0.7)*7-breath,96,a);
    shoulder=lerp(shoulder,32,charge);
    elbow=lerp(elbow,138,charge);
    var sy=-_kick*0.25; var sz=64+bob;
    var ey=sy+dsin(shoulder)*21; var ez=sz-dcos(shoulder)*21;
    var hy=ey+dsin(elbow)*22-_kick; var hz=ez-dcos(elbow)*22;
    var pitch=lerp(-25+sin(_time*1.3)*5,0,a)+_kick*1.6;
    pitch=lerp(pitch,65,charge);
    return {bob:bob,breath:breath,sway:sway,aim:a,charge:charge,
        sy:sy,sz:sz,ey:ey,ez:ez,hy:hy,hz:hz,pitch:pitch};
}
function defender_muzzle(_x,_y,_angle,_time,_kick,_aim,_charge=0,_recovery=0,_visual_scale=1) {
    var pose=defender_pose(_time,_kick,_aim,_charge,_recovery);
    return defender_point(_x,_y,36,pose.hy+dcos(pose.pitch)*34-dsin(pose.pitch)*10,pose.hz+dsin(pose.pitch)*34+dcos(pose.pitch)*10,_angle,_visual_scale);
}
function draw_defender(_x,_y,_angle,_time,_kick,_aim,_charge=0,_recovery=0,_visual_scale=1) {
    var alpha=draw_get_alpha();
    var pose=defender_pose(_time,_kick,_aim,_charge,_recovery);
    var bob=pose.bob;
    var sway=pose.sway;
    var dark=make_colour_rgb(35,47,57);
    var armor=make_colour_rgb(60,69,76);
    var edge=make_colour_rgb(235,232,225);
    var skin=make_colour_rgb(61,81,92);
    var cyan=make_colour_rgb(85,174,185);
    draw_set_alpha(alpha*0.22);
    diamond(_x+3,_y+2,15,5,dark);
    draw_set_alpha(alpha);
    // Broad chest, layered sleeves, belt pouches, knee plates and heavy boots.
    var parts=[
        [-13-sway*0.16,10,6,15,20,12,dark],[13+sway*0.16,-7,6,15,20,12,dark],
        [-13-sway*0.12,11,13,15,20,5,armor],[13+sway*0.12,-6,13,15,20,5,armor],
        [-13-sway*0.08,8,20,12,13,16,dark,25+sway],[13+sway*0.08,-6,20,12,13,16,dark,15-sway],
        [-13+sway*0.1,3,30,13,14,17,armor,-25+sway],[13+sway*0.1,-8,30,13,14,17,armor,-15+sway],
        [-13,17,24,14,4,9,edge],[13,2,24,14,4,9,edge],
        [sway*0.35,0,36,43,25,8,dark],[sway*0.35,14,36,8,3,5,edge],
        [-19,9,33,10,10,12,dark],[19,9,33,10,10,12,dark],
        [sway*0.5,0,55+bob,32,22+pose.breath*0.5,31,armor],[sway*0.5,12,54+bob,28,3,24,armor],


        [sway*0.65,0,69.5+bob,24,22,5,dark],[sway*0.65,15,68+bob,5,3,7,cyan],
        // Right arm meshes rotate at the shoulder and elbow, rather than sliding upward.
        [36,(pose.sy+pose.ey)/2,(pose.sz+pose.ez)/2,12,12,21,armor,point_direction(0,0,pose.ez-pose.sz,pose.ey-pose.sy)],
        [36,pose.ey,pose.ez,13,13,10,dark],
        [36,(pose.ey+pose.hy)/2,(pose.ez+pose.hz)/2,11,11,22,edge,point_direction(0,0,pose.hz-pose.ez,pose.hy-pose.ey)],
        [36,pose.hy,pose.hz,13,12,9,dark],
    ];
    // A separate pistol: narrow grip in the palm, slide above the hand, exposed barrel,
    // trigger guard, magazine heel and sights. All rotate about the wrist together.
    var gun=[
        [0,2,1,7,8,14,dark],
        [0,3,-6,9,10,3,armor],
        [0,12,10,10,28,9,dark],
        [0,11,15,9,25,4,edge],
        [0,29,10,5,10,5,dark],
        [0,34,10,6,2,6,edge],
        [0,35.1,10,3,0.4,3,dark],
        [0,23,19,2,3,3,dark],
        [0,1,19,3,3,3,dark],
        [0,13,-1,7,12,2,dark],
        [0,19,3,7,2,8,dark]
    ];
    for(var g=0;g<array_length(gun);++g) {
        var piece=gun[g];
        array_push(parts,[36+piece[0],pose.hy+piece[1]*dcos(pose.pitch)-piece[2]*dsin(pose.pitch),
            pose.hz+piece[1]*dsin(pose.pitch)+piece[2]*dcos(pose.pitch),piece[3],piece[4],piece[5],piece[6],pose.pitch]);
    }
    var faces=[];
    var indices=[[0,1,2,3],[4,7,6,5],[0,4,5,1],[1,5,6,2],[2,6,7,3],[3,7,4,0]];
    for(var p=0;p<array_length(parts);++p) {
        var b=parts[p]; var verts=[];
        for(var j=0;j<8;++j) {
            var ux=((j mod 4)==0 || (j mod 4)==3) ? -1 : 1;
            var vy=(j mod 4)<2 ? -1 : 1;
            var local_y=vy*b[4]/2;
            var local_z=(j<4 ? -1 : 1)*b[5]/2;
            var pitch=array_length(b)>7 ? b[7] : 0;
            var rotated_y=local_y*dcos(pitch)-local_z*dsin(pitch);
            var rotated_z=local_y*dsin(pitch)+local_z*dcos(pitch);
            // Slow weight shift through the hips, while the feet stay planted.
            var lean=0; // Cloth and rigid meshes share the same anchored pose.
            verts[j]=defender_point(_x,_y,b[0]+ux*b[3]/2+lean,b[1]+rotated_y,b[2]+rotated_z,_angle,_visual_scale);
        }
        for(var f=0;f<6;++f) {
            var ids=indices[f]; var order=0;
            // Reject the hidden side of each rigid cuboid before depth sorting.
            // Drawing every face caused far-side panels to show through arms and guns.
            var area=0;
            for(var k=0;k<4;++k) {
                var p0=verts[ids[k]]; var p1=verts[ids[(k+1) mod 4]];
                area+=p0[0]*p1[1]-p1[0]*p0[1];
            }
            if(area<=0.00001) continue;
            for(var k=0;k<4;++k) order+=verts[ids[k]][2];
            array_push(faces,{points:[verts[ids[0]],verts[ids[1]],verts[ids[2]],verts[ids[3]]],sort_depth:order/4,colour:merge_colour(b[6],c_black,f==1 ? 0 : 0.1+0.07*(f mod 3))});
        }
    }
    // Connected support arm. Charge draws the hand inward in front of the chest,
    // rather than passing through it; elbow stays outside the mantle.
    var support_shoulder=[-34,2,61+bob];
    var support_elbow=[lerp(-36,-29,pose.charge),lerp(13,26,pose.charge),lerp(43,48,pose.charge)+bob];
    var support_hand=[lerp(-30,8,pose.charge),lerp(20,36,pose.charge),lerp(29,58,pose.charge)+bob];
    var bones=[[support_shoulder,support_elbow,10,armor],[support_elbow,support_hand,9,edge]];
    for(var bone=0;bone<array_length(bones);++bone) {
        var a=bones[bone][0]; var b=bones[bone][1]; var width=bones[bone][2];
        var dx=b[0]-a[0]; var dy=b[1]-a[1]; var dz=b[2]-a[2];
        var length=sqrt(dx*dx+dy*dy+dz*dz);
        dx/=length; dy/=length; dz/=length;
        var flat=max(0.0001,sqrt(dx*dx+dy*dy));
        var ux=dy/flat; var uy=-dx/flat;
        var vx=-dz*uy; var vy=dz*ux; var vz=dx*uy-dy*ux;
        var verts=[];
        for(var j=0;j<8;++j) {
            var centre=j<4 ? a : b;
            var u=((j mod 4)==0 || (j mod 4)==3) ? -1 : 1;
            var v=(j mod 4)<2 ? -1 : 1;
            verts[j]=defender_point(_x,_y,centre[0]+(ux*u+vx*v)*width/2,
                centre[1]+(uy*u+vy*v)*width/2,centre[2]+vz*v*width/2,_angle,_visual_scale);
        }
        for(var f=0;f<6;++f) {
            var ids=indices[f]; var order=0;
            // Reject the hidden side of each rigid cuboid before depth sorting.
            // Drawing every face caused far-side panels to show through arms and guns.
            var area=0;
            for(var k=0;k<4;++k) {
                var p0=verts[ids[k]]; var p1=verts[ids[(k+1) mod 4]];
                area+=p0[0]*p1[1]-p1[0]*p0[1];
            }
            if(area<=0.00001) continue;
            for(var k=0;k<4;++k) order+=verts[ids[k]][2];
            array_push(faces,{points:[verts[ids[0]],verts[ids[1]],verts[ids[2]],verts[ids[3]]],sort_depth:order/4,colour:bones[bone][3]});
        }
    }
    // Faceted hood and angular cloth panels, rather than stacked armor cubes.
    var ivory=make_colour_rgb(239,235,227);
    var fold=make_colour_rgb(190,192,190);
    var shade=make_colour_rgb(138,145,148);
    var outer=[[0,15,109],[-13,15,102],[-20,15,83],[-14,16,73],[0,17,70],[14,16,73],[20,15,83],[12,15,102]];
    var inner=[[0,15.5,101],[-8,15.5,96],[-12,15.5,83],[-9,16.5,78],[0,17.5,75],[9,16.5,78],[12,15.5,83],[8,15.5,96]];
    var rear=[[0,-6,105],[-12,-12,99],[-16,-13,83],[-12,-11,73],[0,-11,72],[12,-11,73],[16,-13,83],[12,-12,99]];
    var fabric=[];
    for(var i=0;i<8;++i) {
        var n=(i+1) mod 8;
        array_push(fabric,{points:[outer[i],outer[n],inner[i]],colour:i<4 ? ivory : fold});
        array_push(fabric,{points:[outer[n],inner[n],inner[i]],colour:i<4 ? fold : ivory});
        array_push(fabric,{points:[outer[i],rear[i],rear[n]],colour:i<4 ? fold : shade});
        array_push(fabric,{points:[outer[i],rear[n],outer[n]],colour:i<4 ? ivory : fold});
        array_push(fabric,{points:[rear[i],[-1,-15,88],rear[n]],colour:fold});
    }
    // The opening is an empty dark recess: no eyes or facial markings.
    var recess=[];
    for(var i=0;i<8;++i) array_push(recess,[inner[i][0],inner[i][1]-1.5,inner[i][2]]);
    array_push(fabric,{points:recess,colour:make_colour_rgb(17,24,29)});
    // Layered shoulder cape with a pointed hem and separated coat tails.
    var panels=[
        {points:[[-21,-17,66],[0,-20,63],[-5,-22,13],[-27,-18,22]],colour:fold},
        {points:[[0,-20,63],[21,-17,66],[27,-18,20],[-5,-22,13]],colour:ivory},
        {points:[[-18,18,58],[-5,20,46],[-14,21,16],[-25,17,26]],colour:ivory},
        {points:[[15,20,58],[21,20,27],[14,23,13],[7,22,44]],colour:fold},
        {points:[[-10,4,76],[-25,1,64],[-19,19,57],[0,16,65]],colour:ivory},
        {points:[[-25,1,64],[-27,-3,54],[-19,19,57]],colour:fold},
        {points:[[10,4,76],[23,0,65],[16,18,59],[0,16,65]],colour:fold},
        {points:[[23,0,65],[24,-2,57],[16,18,59]],colour:ivory},
        {points:[[-26,-4,61],[-15,-12,40],[-32,-15,10],[-37,-8,25]],colour:ivory},
        {points:[[-26,-4,61],[-37,-8,25],[-40,-1,42]],colour:fold},
        {points:[[-15,-12,40],[-20,-5,11],[-32,-15,10]],colour:fold},
        {points:[[22,-7,60],[30,-12,32],[22,-18,9],[12,-14,39]],colour:fold},
        {points:[[22,-7,60],[33,-8,46],[30,-12,32]],colour:ivory},
        {points:[[-12,12,39],[-15,15,12],[-3,17,22],[0,12,40]],colour:shade},
        {points:[[4,12,39],[4,16,16],[15,13,8],[16,11,37]],colour:armor},
        // Single desaturated teal scarf adds a quiet identifying accent.
        {points:[[-12,17,73],[0,21,67],[13,17,72],[2,22,62]],colour:cyan},
        {points:[[2,-12,66],[10,-13,65],[19,-25,42],[12,-26,34]],colour:cyan}
    ];
    for(var i=0;i<array_length(panels);++i) array_push(fabric,panels[i]);
    for(var i=0;i<array_length(fabric);++i) {
        var patch=fabric[i]; var points=[]; var order=0;
        for(var j=0;j<array_length(patch.points);++j) {
            var v=patch.points[j];
            var flutter=clamp((38-v[2])/28,0,1);
            var q=defender_point(_x,_y,v[0]+sway*(0.2+flutter*0.35)+sin(_time*1.8+v[0]*0.06)*flutter*1.5,
                v[1]+sin(_time*1.5+v[0]*0.05)*flutter*2,v[2]+bob,_angle,_visual_scale);
            array_push(points,q); order+=q[2];
        }
        array_push(faces,{points:points,sort_depth:order/array_length(points),colour:patch.colour});
    }
    array_sort(faces,function(_a,_b){return sign(_a.sort_depth-_b.sort_depth);});
    for(var f=0;f<array_length(faces);++f) {
        var face=faces[f];
        draw_set_colour(face.colour);
        draw_primitive_begin(pr_trianglefan);
        for(var k=0;k<array_length(face.points);++k) draw_vertex(face.points[k][0],face.points[k][1]);
        draw_primitive_end();
    }
}













// WANDERER follows the supplied sculpt: ivory beaked hood, torn mantle,
// faceless lime slit, asymmetric prosthetic shin and a supported sniper rifle.
function wanderer_pose(_time,_kick,_aim,_charge,_recovery) {
    var aim=clamp(_aim+_charge,0,1);
    aim=aim*aim*(3-2*aim);
    var bob=sin(_time*1.7)*0.7-25*(1-aim)-_charge*5-_kick*0.18;
    return {bob:bob,
        pitch:lerp(-16,-2,aim)+_kick*0.9,hy:lerp(18,23,aim)-_kick,
        hz:lerp(61,76,aim)+bob,aim:aim};
}
// Longer exposed legs preserve the reference silhouette beneath the torn mantle.
function wanderer_point(_x,_y,_u,_v,_z,_angle,_scale) {
    _z+=16;
    return defender_point(_x,_y,_u,_v,_z,_angle,_scale);
}
function wanderer_muzzle(_x,_y,_angle,_time,_kick,_aim,_charge=0,_recovery=0,_visual_scale=1) {
    var pose=wanderer_pose(_time,_kick,_aim,_charge,_recovery);
    return wanderer_point(_x,_y,13,pose.hy+81*dcos(pose.pitch),pose.hz+81*dsin(pose.pitch),_angle,_visual_scale);
}
function draw_wanderer(_x,_y,_angle,_time,_kick,_aim,_charge=0,_recovery=0,_visual_scale=1) {
    var pose=wanderer_pose(_time,_kick,_aim,_charge,_recovery);
    var dark=make_colour_rgb(34,42,32);
    var coat=make_colour_rgb(53,63,46);
    var steel=make_colour_rgb(91,109,82);
    var ivory=make_colour_rgb(228,237,203);
    var fold=make_colour_rgb(173,187,148);
    var shade=make_colour_rgb(112,133,93);
    var cyan=make_colour_rgb(187,244,72);
    var joint=make_colour_rgb(167,178,130);
    var bob=pose.bob;
    var flutter=sin(_time*2)*4;
    var parts=[
        [0,-1,62+bob,25,18,28,coat],
        [0,0,80+bob,12,12,12,dark],
        [0,4,92+bob,17,15,23,make_colour_rgb(12,18,23)],
        [3,12,94+bob,2,1,8,cyan,-8],
        [13,pose.hy-3,pose.hz-5,8,11,9,dark,pose.pitch],
        [13,pose.hy+24*dcos(pose.pitch),pose.hz+24*dsin(pose.pitch)-5,9,10,8,dark,pose.pitch]
    ];
    var gun=[[0,-17,-1,6,24,10,steel],[0,-29,-1,7,3,12,dark],
        [0,9,0,8,36,9,steel],[0,12,5,6,29,2,shade],[0,2,-8,5,7,11,dark],
        [0,49,0,2.5,48,2.5,fold],[0,76,0,7,10,6,steel],[0,81.1,0,3,0.3,2,dark],
        [0,4,8,3,4,7,dark],[0,16,8,3,4,7,dark],
        [0,10,12,6,21,6,steel],[0,21,12,7,4,7,dark],[0,23.1,12,5,0.3,5,cyan]];
    for(var g=0;g<array_length(gun);++g) {
        var piece=gun[g];
        array_push(parts,[13+piece[0],pose.hy+piece[1]*dcos(pose.pitch)-piece[2]*dsin(pose.pitch),
            pose.hz+piece[1]*dsin(pose.pitch)+piece[2]*dcos(pose.pitch),piece[3],piece[4],piece[5],piece[6],pose.pitch]);
    }
    var faces=[];
    var indices=[[0,1,2,3],[4,7,6,5],[0,4,5,1],[1,5,6,2],[2,6,7,3],[3,7,4,0]];
    for(var p=0;p<array_length(parts);++p) {
        var b=parts[p]; var verts=[];
        for(var j=0;j<8;++j) {
            var ux=((j mod 4)==0 || (j mod 4)==3) ? -1 : 1;
            var vy=(j mod 4)<2 ? -1 : 1;
            var local_y=vy*b[4]/2;
            var local_z=(j<4 ? -1 : 1)*b[5]/2;
            var pitch=array_length(b)>7 ? b[7] : 0;
            var rotated_y=local_y*dcos(pitch)-local_z*dsin(pitch);
            var rotated_z=local_y*dsin(pitch)+local_z*dcos(pitch);
            // Slow weight shift through the hips, while the feet stay planted.
            var lean=0; // Cloth and rigid meshes share the same anchored pose.
            verts[j]=wanderer_point(_x,_y,b[0]+ux*b[3]/2+lean,b[1]+rotated_y,b[2]+rotated_z,_angle,_visual_scale);
        }
        for(var f=0;f<6;++f) {
            var ids=indices[f]; var order=0;
            // Reject the hidden side of each rigid cuboid before depth sorting.
            // Drawing every face caused far-side panels to show through arms and guns.
            var area=0;
            for(var k=0;k<4;++k) {
                var p0=verts[ids[k]]; var p1=verts[ids[(k+1) mod 4]];
                area+=p0[0]*p1[1]-p1[0]*p0[1];
            }
            if(area<=0.00001) continue;
            for(var k=0;k<4;++k) order+=verts[ids[k]][2];
            array_push(faces,{points:[verts[ids[0]],verts[ids[1]],verts[ids[2]],verts[ids[3]]],sort_depth:order/4,colour:merge_colour(b[6],c_black,f==1 ? 0 : 0.1+0.07*(f mod 3))});
        }
    }


    // Hood opening remains empty. The crown extends far beyond the face as a beak.
    var fabric=[
        [[0,0,120],[-19,1,104],[-20,-15,95],fold],
        [[0,0,120],[-20,-15,95],[0,-22,108],ivory],
        [[0,0,120],[0,-22,108],[18,-12,100],fold],
        [[0,0,120],[18,-12,100],[17,7,105],ivory],
        [[0,0,120],[17,7,105],[0,67,88],ivory],
        [[0,0,120],[0,67,88],[-8,24,107],ivory],
        [[0,0,120],[-8,24,107],[-19,1,104],fold],
        [[-19,1,104],[-8,24,107],[-17,19,80],ivory],
        [[-19,1,104],[-17,19,80],[-24,-8,81],fold],
        [[-19,1,104],[-24,-8,81],[-20,-15,95],shade],
        [[-20,-15,95],[-24,-8,81],[0,-23,81],fold],
        [[-20,-15,95],[0,-23,81],[0,-22,108],shade],
        [[0,-22,108],[0,-23,81],[21,-10,82],fold],
        [[0,-22,108],[21,-10,82],[18,-12,100],ivory],
        [[18,-12,100],[21,-10,82],[17,7,105],fold],
        [[17,7,105],[21,-10,82],[16,16,83],shade],
        // Folded collar and asymmetric shoulder mantle.
        [[-23,-10,84],[-17,19,80],[0,18,73],shade],
        [[-23,-10,84],[0,18,73],[0,-19,75],fold],
        [[-18,1,79],[-35,0,70],[-27,22,67],ivory],
        [[-18,1,79],[-27,22,67],[0,18,73],fold],
        [[-35,0,70],[-36,-16,63],[-18,-16,76],fold],
        [[0,-19,75],[-18,-16,76],[-36,-16,63],ivory],
        [[0,-19,75],[24,-14,73],[32,2,68],fold],
        [[0,-19,75],[32,2,68],[0,18,73],ivory],
        [[0,18,73],[32,2,68],[24,21,56],ivory],
        // Torn front strips: separate triangles leave visible holes, not painted marks.
        [[24,21,56],[32,2,68],[31,15,41],fold],
        [[24,21,56],[31,15,41],[21,25,37],ivory],
        [[21,25,37],[31,15,41],[38,17,14],ivory],
        [[21,25,37],[38,17,14],[25,26,24],fold],
        [[24,21,56],[21,25,37],[13,26,50],ivory],
        [[21,25,37],[25,26,24],[29,29,5],ivory],
        [[-27,22,67],[-35,0,70],[-32,9,46],ivory],
        [[-27,22,67],[-32,9,46],[-18,22,47],fold],
        [[-32,9,46],[-39,4,22],[-25,17,37],ivory],
        [[-32,9,46],[-25,17,37],[-18,22,47],ivory],
        [[-39,4,22],[-43,8,9],[-25,17,37],fold],
        // Back mantle breaks into long featherlike points.
        [[-36,-16,63],[-17,-23,68],[-26,-25,37],fold],
        [[-36,-16,63],[-26,-25,37],[-44,-18,17],ivory],
        [[-17,-23,68],[0,-24,74],[-8,-29,39],ivory],
        [[-17,-23,68],[-8,-29,39],[-26,-25,37],fold],
        [[-26,-25,37],[-8,-29,39],[-31,-26,7],ivory],
        [[0,-24,74],[24,-14,73],[16,-25,43],fold],
        [[0,-24,74],[16,-25,43],[-8,-29,39],ivory],
        [[16,-25,43],[24,-14,73],[31,-20,30],ivory],
        [[16,-25,43],[31,-20,30],[26,-25,8],fold],
        [[-8,-29,39],[16,-25,43],[3,-31,18],shade],
        [[-8,-29,39],[3,-31,18],[-12,-31,2],ivory]
    ];
    for(var patch=0;patch<array_length(fabric);++patch) {
        var panel=fabric[patch];var points=[];
        for(var vertex=0;vertex<3;++vertex) {
            var v=panel[vertex];var hem=clamp((65-v[2])/60,0,1);
            array_push(points,[v[0]+sin(_time*1.9+v[0]*0.06)*hem*2,
                v[1]+sin(_time*(1.6+_charge*4)+v[0]*0.04)*hem*(3+_charge*8)-_kick*hem*0.9,
                max(-9,v[2]+bob+hem*13+_charge*hem*5)]);
        }
        wanderer_mesh_face(faces,points,panel[3],_x,_y,_angle,_visual_scale);
    }
    // Jointed sleeves end at the two weapon grips in every pose.
    var hand=[13,pose.hy-3,pose.hz-5];
    var support=[13,pose.hy+24*dcos(pose.pitch),pose.hz+24*dsin(pose.pitch)-5];
    var elbow=[23,lerp(4,10,pose.aim),lerp(53,62,pose.aim)+bob];
    var support_elbow=[-22,lerp(13,22,pose.aim),lerp(45,59,pose.aim)+bob];
    wanderer_limb(faces,[16,1,73+bob],elbow,10,coat,_x,_y,_angle,_visual_scale);
    wanderer_limb(faces,elbow,hand,8,coat,_x,_y,_angle,_visual_scale);
    wanderer_limb(faces,[-18,2,73+bob],support_elbow,10,coat,_x,_y,_angle,_visual_scale);
    wanderer_limb(faces,support_elbow,support,8,coat,_x,_y,_angle,_visual_scale);
    var knee_y=lerp(24,5,pose.aim);var knee_z=lerp(16,34,pose.aim);
    var rear_knee_z=lerp(-8,30,pose.aim);var rear_foot_y=lerp(-34,-9,pose.aim);
    wanderer_limb(faces,[-10,0,53+bob],[-13,knee_y,knee_z],11,coat,_x,_y,_angle,_visual_scale);
    wanderer_limb(faces,[-13,knee_y,knee_z],[-13,16,-8],6,joint,_x,_y,_angle,_visual_scale);
    wanderer_limb(faces,[10,-5,53+bob],[14,-5,rear_knee_z],12,coat,_x,_y,_angle,_visual_scale);
    wanderer_limb(faces,[14,-5,rear_knee_z],[16,rear_foot_y,-8],9,coat,_x,_y,_angle,_visual_scale);
    // Open octagonal mechanical knee ring, over the exposed warm-metal shin.
    for(var segment=0;segment<8;++segment) {
        var a=segment*45;var b=(segment+1)*45;
        wanderer_mesh_face(faces,[[-13+dcos(a)*6,knee_y+6,knee_z+dsin(a)*6],[-13+dcos(b)*6,knee_y+6,knee_z+dsin(b)*6],
            [-13+dcos(b)*3,knee_y+6.2,knee_z+dsin(b)*3],[-13+dcos(a)*3,knee_y+6.2,knee_z+dsin(a)*3]],
            segment<4 ? joint : shade,_x,_y,_angle,_visual_scale);
    }
    // Low wedge boots end in angular toes instead of square blocks.
    for(var foot=0;foot<2;++foot) {
        var fx=foot==0 ? -13 : 16;var fy=foot==0 ? 16 : rear_foot_y;
        var boot=[[-4,-5,-15],[4,-5,-15],[5,14,-15],[-5,14,-15],[0,1,-5],[0,16,-12]];
        var boot_faces=[[0,1,4],[1,2,4],[2,5,4],[5,3,4],[3,0,4],[3,5,2]];
        for(var f=0;f<array_length(boot_faces);++f) {
            var points=[];
            for(var v=0;v<3;++v) {
                var q=boot[boot_faces[f][v]];array_push(points,[fx+q[0],fy+q[1],q[2]]);
            }
            wanderer_mesh_face(faces,points,f mod 2==0 ? coat : dark,_x,_y,_angle,_visual_scale);
        }
    }
    array_sort(faces,function(_a,_b){return sign(_a.sort_depth-_b.sort_depth);});
    for(var f=0;f<array_length(faces);++f) {
        var face=faces[f];
        draw_set_colour(face.colour);
        draw_primitive_begin(pr_trianglefan);
        for(var k=0;k<array_length(face.points);++k) draw_vertex(face.points[k][0],face.points[k][1]);
        draw_primitive_end();
    }
}

function wanderer_mesh_face(_faces,_points,_colour,_x,_y,_angle,_scale) {
    var projected=[];var order=0;
    for(var i=0;i<array_length(_points);++i) {
        var v=_points[i];var q=wanderer_point(_x,_y,v[0],v[1],v[2],_angle,_scale);
        array_push(projected,q);order+=q[2];
    }
    array_push(_faces,{points:projected,sort_depth:order/array_length(projected),colour:_colour});
}
function wanderer_limb(_faces,_a,_b,_width,_colour,_x,_y,_angle,_scale) {
    var dx=_b[0]-_a[0];var dy=_b[1]-_a[1];var dz=_b[2]-_a[2];
    var length=max(0.001,sqrt(dx*dx+dy*dy+dz*dz));dx/=length;dy/=length;dz/=length;
    var flat=max(0.001,sqrt(dx*dx+dy*dy));var ux=dy/flat;var uy=-dx/flat;
    var vx=-dz*uy;var vy=dz*ux;var vz=dx*uy-dy*ux;
    var vertices=[];
    for(var i=0;i<8;++i) {
        var centre=i<4 ? _a : _b;var u=((i mod 4)==0 || (i mod 4)==3) ? -1 : 1;var v=(i mod 4)<2 ? -1 : 1;
        var radius=_width*(i<4 ? 0.5 : 0.36);
        array_push(vertices,[centre[0]+(ux*u+vx*v)*radius,centre[1]+(uy*u+vy*v)*radius,centre[2]+vz*v*radius]);
    }
    var indices=[[0,1,2,3],[4,7,6,5],[0,4,5,1],[1,5,6,2],[2,6,7,3],[3,7,4,0]];
    for(var i=0;i<6;++i) {
        var ids=indices[i];
        wanderer_mesh_face(_faces,[vertices[ids[0]],vertices[ids[1]],vertices[ids[2]],vertices[ids[3]]],
            merge_colour(_colour,c_black,(i mod 3)*0.12),_x,_y,_angle,_scale);
    }
}
