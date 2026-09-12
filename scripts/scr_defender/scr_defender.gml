// Reference model proportions are built at 100 units and displayed at enemy scale.
function defender_point(_x,_y,_u,_v,_z,_angle,_visual_scale=1,_pose=undefined) {
    var scale=0.36*_visual_scale;
    var posture=clamp((_z-12)/40,0,1);
    if(_pose!=undefined) {
        var twist=(-10-_pose.aim*5+_pose.sway)*posture;
        var u=_u; _u=u*dcos(twist)-_v*dsin(twist); _v=u*dsin(twist)+_v*dcos(twist);
        _u+=(-4+_pose.sway)*posture;
        _v+=(_pose.aim*4-_pose.kick*0.3)*posture;
        _z-=2*posture;
    }
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
    var sway=sin(_time*1.05+0.4)*3.4*(1-a*0.45);
    var bob=breath*1.25+sin(_time*4.2+0.8)*0.28-charge*2.5-sin(_recovery*pi)*3;
    var shoulder=lerp(30+sin(_time*1.3)*7+breath*2,72,a);
    var elbow=lerp(62+sin(_time*1.3+0.7)*9-breath,100,a);
    shoulder=lerp(shoulder,32,charge);
    elbow=lerp(elbow,138,charge);
    var sy=-_kick*0.25; var sz=64+bob;
    var ey=sy+dsin(shoulder)*21; var ez=sz-dcos(shoulder)*21;
    var hy=ey+dsin(elbow)*22-_kick; var hz=ez-dcos(elbow)*22;
    var pitch=lerp(-32+sin(_time*1.3)*7,0,a)+_kick*1.6;
    pitch=lerp(pitch,65,charge);
    return {bob:bob,breath:breath,sway:sway,aim:a,charge:charge,kick:_kick,
        sy:sy,sz:sz,ey:ey,ez:ez,hy:hy,hz:hz,pitch:pitch};
}
function defender_muzzle(_x,_y,_angle,_time,_kick,_aim,_charge=0,_recovery=0,_visual_scale=1) {
    var pose=defender_pose(_time,_kick,_aim,_charge,_recovery);
    return defender_point(_x,_y,36,pose.hy+dcos(pose.pitch)*34-dsin(pose.pitch)*10,pose.hz+dsin(pose.pitch)*34+dcos(pose.pitch)*10,_angle,_visual_scale,pose);
}
function draw_defender(_x,_y,_angle,_time,_kick,_aim,_charge=0,_recovery=0,_visual_scale=1) {
    var pose=defender_pose(_time,_kick,_aim,_charge,_recovery);
    var bob=pose.bob;
    var sway=pose.sway;
    var dark=make_colour_rgb(35,47,57);
    var armor=make_colour_rgb(60,69,76);
    var edge=make_colour_rgb(235,232,225);
    var skin=make_colour_rgb(61,81,92);
    var cyan=make_colour_rgb(85,174,185);
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
            verts[j]=defender_point(_x,_y,b[0]+ux*b[3]/2+lean,b[1]+rotated_y,b[2]+rotated_z,_angle,_visual_scale,pose);
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
    var support_elbow=[lerp(-41,-29,pose.charge),lerp(17+pose.aim*5,26,pose.charge),lerp(47,48,pose.charge)+bob];
    var support_hand=[lerp(-14+pose.aim*9,8,pose.charge),lerp(29+pose.aim*5,36,pose.charge),lerp(56+pose.breath*1.5,58,pose.charge)+bob];
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
                centre[1]+(uy*u+vy*v)*width/2,centre[2]+vz*v*width/2,_angle,_visual_scale,pose);
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
                v[1]+sin(_time*1.5+v[0]*0.05)*flutter*2,v[2]+bob,_angle,_visual_scale,pose);
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
    var aim=clamp(_aim,0,1);
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
function triage_pose(_time,_kick,_aim,_charge,_travel=0) {
    var aim=clamp(_aim,0,1);aim=aim*aim*(3-2*aim);
    var charge=clamp(_charge,0,1);charge=charge*charge*(3-2*charge);
    // Cocked applicator and an open assessing palm distinguish the medic's stance.
    var breath=sin(_time*2.6);var scan=sin(_time*1.4+0.6);
    var bob=-5+breath*1.2-charge*4+sin(_time*15)*_travel*2;
    var hy=lerp(17+scan*3,34,aim)-_kick*0.55;
    var hz=lerp(57+breath*1.2,65,aim)+bob;
    hy=lerp(hy,10+sin(_time*15)*7,_travel);hz=lerp(hz,45+bob,_travel);
    return {bob:bob,charge:charge,travel:_travel,
        hand:[lerp(25,21,aim),lerp(hy,24,charge),lerp(hz,78+bob,charge)],
        elbow:[32+scan*(1-aim),lerp(-3,12,aim)-_kick*0.2,lerp(49,54,aim)+bob],
        support:[lerp(-29-scan*2,-22,charge),lerp(lerp(25+scan*3,30,charge),14-sin(_time*15)*9,_travel),lerp(51+breath*2-aim*5,73,charge)+bob],
        pitch:lerp(lerp(lerp(32+scan*6,0,aim)+_kick*1.1,56,charge),-30,_travel)};
}
function triage_muzzle(_x,_y,_angle,_time,_kick,_aim,_charge=0,_recovery=0,_visual_scale=1) {
    var pose=triage_pose(_time,_kick,_aim,_charge);
    return wanderer_point(_x,_y,pose.hand[0],pose.hand[1]+27*dcos(pose.pitch),pose.hand[2]+27*dsin(pose.pitch),_angle,_visual_scale);
}
// Beveled octagonal volumes keep equipment readable without rectangular blocks.
function triage_box(_faces,_u,_v,_z,_w,_d,_h,_colour,_x,_y,_angle,_scale) {
    var ring=[[-0.65,-1],[0.65,-1],[1,-0.65],[1,0.65],[0.65,1],[-0.65,1],[-1,0.65],[-1,-0.65]];
    var cap=[];
    for(var i=0;i<8;++i) {
        var a=ring[i];var b=ring[(i+1) mod 8];
        var p=[_u+a[0]*_w,_v+a[1]*_d,_z+_h];array_push(cap,p);
        wanderer_mesh_face(_faces,[[_u+a[0]*_w,_v+a[1]*_d,_z],[_u+b[0]*_w,_v+b[1]*_d,_z],[_u+b[0]*_w,_v+b[1]*_d,_z+_h],p],merge_colour(_colour,c_black,(i mod 4)*0.075),_x,_y,_angle,_scale);
    }
    wanderer_mesh_face(_faces,cap,merge_colour(_colour,make_colour_rgb(255,232,239),0.16),_x,_y,_angle,_scale);
}
function triage_weapon_point(_pose,_u,_v,_z) {
    return [_pose.hand[0]+_u,_pose.hand[1]+_v*dcos(_pose.pitch)-_z*dsin(_pose.pitch),_pose.hand[2]+_v*dsin(_pose.pitch)+_z*dcos(_pose.pitch)];
}
function draw_triage(_x,_y,_angle,_time,_kick,_aim,_charge=0,_recovery=0,_visual_scale=1,_travel=0) {
    var faces=[];var pose=triage_pose(_time,_kick,_aim,_charge,_travel);var bob=pose.bob;
    var pale=make_colour_rgb(247,220,232);var coat=make_colour_rgb(217,147,177);var shade=make_colour_rgb(155,91,125);
    var dark=make_colour_rgb(43,34,49);var leather=make_colour_rgb(83,59,73);var pink=make_colour_rgb(255,126,188);var metal=make_colour_rgb(187,161,178);
    // A forward planted foot and trailing heel support a low, assessing stance.
    var legs=[];var shift=sin(_time*1.4)*1.4;
    for(var side=-1;side<=1;side+=2) {
        var stride=sin(_time*15+side*1.57)*_travel*11;
        var foot_y=(side==1 ? -9 : 13)+stride;
        var hip=[side*9+shift,-1,34+bob];var knee=[side*12+shift*0.35,foot_y+7,12+bob*0.18];var ankle=[side*13,foot_y,-7];
        tower_stance_leg(legs,hip,knee,ankle,side==-1 ? 1 : 0,shade,dark,metal);
    }
    for(var i=0;i<array_length(legs);++i) wanderer_mesh_face(faces,legs[i].vertices,legs[i].colour,_x,_y,_angle,_visual_scale);
    triage_box(faces,0,0,29+bob,15,10,36,dark,_x,_y,_angle,_visual_scale);
    // Compact medical pack: contoured lid, twin pockets, straps and pink vials.
    triage_box(faces,0,-19,35+bob,18,9,33,leather,_x,_y,_angle,_visual_scale);
    triage_box(faces,0,-19,68+bob,19,10,7,shade,_x,_y,_angle,_visual_scale);
    for(var side=-1;side<=1;side+=2) {
        triage_box(faces,side*10,-29,39+bob,7,4,16,shade,_x,_y,_angle,_visual_scale);
        triage_box(faces,side*10,-33.5,48+bob,2,1,5,metal,_x,_y,_angle,_visual_scale);
        triage_box(faces,side*12,-29,58+bob,2,1,16,dark,_x,_y,_angle,_visual_scale);
        triage_box(faces,side*22,-19,43+bob,4,4,18,metal,_x,_y,_angle,_visual_scale);
        triage_box(faces,side*22,-19,47+bob,4.2,4.2,10,pink,_x,_y,_angle,_visual_scale);
    }
    triage_box(faces,0,-29,60+bob,2,1,11,pale,_x,_y,_angle,_visual_scale);
    triage_box(faces,0,-29.5,64+bob,5,1,3,pale,_x,_y,_angle,_visual_scale);
    // Each split coat panel has a raised central fold and an irregular torn hem.
    for(var panel=0;panel<8;++panel) {
        var a=panel*45+22.5;var b=a+43;var mid=(a+b)*0.5;
        var sway=sin(_time*2.4+panel*0.8)*(2+pose.charge*4)+_travel*13;
        var hem=(dsin(mid)>0 ? 19 : 7)+(panel mod 3)*3;
        var p0=[dcos(a)*18,dsin(a)*11,62+bob];var p1=[dcos(b)*18,dsin(b)*11,62+bob];
        var p2=[dcos(b)*26,dsin(b)*17-sway,hem+bob];var p3=[dcos(mid)*24,dsin(mid)*18-sway,hem-5+bob];
        var p4=[dcos(a)*27,dsin(a)*17-sway,hem+3+bob];var ridge=[dcos(mid)*23,dsin(mid)*16-sway*0.3,37+bob];
        wanderer_mesh_face(faces,[p0,p1,ridge],panel mod 2==0 ? pale : coat,_x,_y,_angle,_visual_scale);
        wanderer_mesh_face(faces,[p1,p2,p3,ridge],coat,_x,_y,_angle,_visual_scale);
        wanderer_mesh_face(faces,[ridge,p3,p4,p0],panel mod 2==0 ? shade : pale,_x,_y,_angle,_visual_scale);
    }
    // Articulated shoulder, elbow, wrist and support palm share the firing rig.
    for(var side=-1;side<=1;side+=2) {
        var elbow=side==1 ? pose.elbow : [-33,9,49+bob+pose.charge*9];
        var hand=side==1 ? pose.hand : pose.support;
        wanderer_limb(faces,[side*17,-1,66+bob],elbow,15,coat,_x,_y,_angle,_visual_scale);
        wanderer_limb(faces,elbow,hand,10,pale,_x,_y,_angle,_visual_scale);
        triage_box(faces,hand[0],hand[1],hand[2]-3,4,4,7,dark,_x,_y,_angle,_visual_scale);
        wanderer_mesh_face(faces,[[side*13,12,67+bob],[side*18,12,66+bob],[side*5,15,34+bob],[side*0,15,35+bob]],leather,_x,_y,_angle,_visual_scale);
        triage_box(faces,side*10,17,41+bob,3,1,5,metal,_x,_y,_angle,_visual_scale);
        triage_box(faces,side*12,14,27+bob,5,4,11,leather,_x,_y,_angle,_visual_scale);
    }
    // Folded shoulder cape and a deep hood opening, framed by multiple rim facets.
    wanderer_mesh_face(faces,[[-24,8,64+bob],[-17,-14,70+bob],[0,-18,77+bob],[0,20,67+bob]],pale,_x,_y,_angle,_visual_scale);
    wanderer_mesh_face(faces,[[0,-18,77+bob],[19,-12,70+bob],[25,9,64+bob],[0,20,67+bob]],coat,_x,_y,_angle,_visual_scale);
    var outer=[[-17,13,86],[-9,10,99],[5,8,104],[18,11,91],[17,19,73],[0,23,68],[-18,19,73]];
    var inner=[[-11,20,84],[-6,20,93],[4,20,96],[12,20,87],[10,23,76],[0,24,73],[-11,23,76]];
    for(var i=0;i<7;++i) {
        var j=(i+1) mod 7;var a=outer[i];var b=outer[j];var c=inner[j];var d=inner[i];
        wanderer_mesh_face(faces,[[a[0],a[1],a[2]+bob],[b[0],b[1],b[2]+bob],[c[0],c[1],c[2]+bob],[d[0],d[1],d[2]+bob]],i mod 3==0 ? coat : pale,_x,_y,_angle,_visual_scale);
        wanderer_mesh_face(faces,[[a[0],a[1],a[2]+bob],[0,-17,86+bob],[b[0],b[1],b[2]+bob]],i mod 2==0 ? coat : shade,_x,_y,_angle,_visual_scale);
    }
    var mask=[];for(var i=0;i<7;++i) {var p=inner[i];array_push(mask,[p[0]*0.96,p[1]-1,p[2]+bob]);}
    wanderer_mesh_face(faces,mask,dark,_x,_y,_angle,_visual_scale);
    for(var ring=0;ring<3;++ring) {
        var lens=[];var radius=ring==0 ? 6 : (ring==1 ? 4.6 : 2);
        for(var i=0;i<10;++i) array_push(lens,[-2+dcos(i*36)*radius,24+ring*0.4,83+bob+dsin(i*36)*radius]);
        wanderer_mesh_face(faces,lens,ring==0 ? metal : (ring==1 ? pink : pale),_x,_y,_angle,_visual_scale);
    }
    // Sleeve badge sits against the moving upper arm.
    var badge_z=58+bob+pose.charge*3;
    triage_box(faces,-24,8,badge_z-5,5,1,10,shade,_x,_y,_angle,_visual_scale);
    triage_box(faces,-24,9,badge_z-4,1.4,1,8,pink,_x,_y,_angle,_visual_scale);
    triage_box(faces,-24,10,badge_z-1.4,4,1,2.8,pink,_x,_y,_angle,_visual_scale);
    // Dart applicator: barrel, rose reservoir, grip and a narrow steel needle.
    wanderer_limb(faces,triage_weapon_point(pose,0,0,-6),triage_weapon_point(pose,0,2,2),6,leather,_x,_y,_angle,_visual_scale);
    wanderer_limb(faces,triage_weapon_point(pose,0,-3,0),triage_weapon_point(pose,0,18,0),8,metal,_x,_y,_angle,_visual_scale);
    wanderer_limb(faces,triage_weapon_point(pose,0,2,4),triage_weapon_point(pose,0,15,4),4,pink,_x,_y,_angle,_visual_scale);
    wanderer_limb(faces,triage_weapon_point(pose,0,18,0),triage_weapon_point(pose,0,27,0),2,pale,_x,_y,_angle,_visual_scale);
    array_sort(faces,function(_a,_b){return sign(_a.sort_depth-_b.sort_depth);});
    for(var f=0;f<array_length(faces);++f) {var face=faces[f];draw_set_colour(face.colour);draw_primitive_begin(pr_trianglefan);
        for(var k=0;k<array_length(face.points);++k) draw_vertex(face.points[k][0],face.points[k][1]);draw_primitive_end();}
}
function singularity_muzzle(_x,_y,_angle,_time,_kick,_aim,_charge=0,_recovery=0,_visual_scale=1) {
    return wanderer_point(_x,_y,0,10,63+sin(_time*1.6)*2,_angle,_visual_scale);
}
function singularity_shard(_faces,_u,_v,_z,_width,_height,_colour,_x,_y,_angle,_scale) {
    var points=[[_u,_v,_z+_height],[_u-_width,_v,_z],[_u,_v-_width*0.6,_z],[_u+_width,_v,_z],[_u,_v+_width*0.6,_z],[_u,_v,_z-_height*0.7]];
    var sides=[[0,1,2],[0,2,3],[0,3,4],[0,4,1],[5,2,1],[5,3,2],[5,4,3],[5,1,4]];
    for(var i=0;i<8;++i) {var f=sides[i];wanderer_mesh_face(_faces,[points[f[0]],points[f[1]],points[f[2]]],merge_colour(_colour,c_black,(i mod 4)*0.13),_x,_y,_angle,_scale);}
}
// A shared pose drives the arm, carried black hole and impact position.
function tower_pose_ease(_t) {var t=clamp(_t,0,1);return t*t*(3-2*t);}
function tower_pose_mix(_a,_b,_t) {return [lerp(_a[0],_b[0],_t),lerp(_a[1],_b[1],_t),lerp(_a[2],_b[2],_t)];}
function singularity_pose(_time,_attack,_impact,_skill,_release) {
    var breath=sin(_time*1.7);var sway=sin(_time*1.1+0.4);
    var idle_bob=-5.5+breath*0.9;
    var idle_right=[25+sway*1.4,17+sway*2,55+breath*1.2];
    var idle_left=[-27+sway,24,48-breath];
    var idle_re=[32,3,47+idle_bob];var idle_le=[-31,9,45+idle_bob];
    var lift=tower_pose_ease(_attack/0.81);
    var slam=tower_pose_ease((_attack-0.81)/0.19);
    var weight=max(slam,tower_pose_ease(_impact/0.82));
    var right=tower_pose_mix(tower_pose_mix(idle_right,[20,5,120],lift),[7,0,-6],weight);
    var left=tower_pose_mix(idle_left,[-25,21,25],weight);
    var right_elbow=tower_pose_mix(tower_pose_mix(idle_re,[23,0,91],lift),[24,10,20],weight);
    var left_elbow=tower_pose_mix(idle_le,[-29,8,31],weight);
    var bob=lerp(idle_bob,-22,weight);var ritual=0;
    if(_skill>0 || _release>0) {
        var open=tower_pose_ease(_skill/0.6);var compress=tower_pose_ease((_skill-0.6)/0.4);
        right=tower_pose_mix(tower_pose_mix(idle_right,[40,20,74],open),[10,22,85],compress);
        left=tower_pose_mix(tower_pose_mix(idle_left,[-40,20,74],open),[-10,22,85],compress);
        right_elbow=tower_pose_mix(tower_pose_mix(idle_re,[32,5,62],open),[25,7,70],compress);
        left_elbow=tower_pose_mix(tower_pose_mix(idle_le,[-32,5,62],open),[-25,7,70],compress);
        bob=lerp(idle_bob,0,open);ritual=open;
        if(_release>0) {
            var t=1-clamp(_release,0,1);var burst=tower_pose_ease(t/0.22);var settle=tower_pose_ease((t-0.22)/0.78);
            right=tower_pose_mix(tower_pose_mix([10,22,85],[42,18,68],burst),idle_right,settle);
            left=tower_pose_mix(tower_pose_mix([-10,22,85],[-42,18,68],burst),idle_left,settle);
            right_elbow=tower_pose_mix(tower_pose_mix([25,7,70],[33,5,56],burst),idle_re,settle);
            left_elbow=tower_pose_mix(tower_pose_mix([-25,7,70],[-33,5,56],burst),idle_le,settle);
            bob=lerp(lerp(0,-10,burst),idle_bob,settle);ritual=1-settle;
        }
    }
    return {bob:bob,weight:weight,right:right,left:left,right_elbow:right_elbow,left_elbow:left_elbow,lift:lift,slam:slam,ritual:ritual};
}
// Slim segmented shins, separate ankles and tapered boots shared by the two new rigs.
function tower_stance_leg(_faces,_hip,_knee,_ankle,_front,_armour,_dark,_metal) {
    singularity_local_limb(_faces,_hip,_knee,9,_dark);
    var upper=tower_pose_mix(_hip,_knee,0.15);var lower=tower_pose_mix(_hip,_knee,0.72);
    singularity_local_limb(_faces,[upper[0],upper[1]+2,upper[2]],[lower[0],lower[1]+2,lower[2]],7.5,_armour);
    singularity_local_limb(_faces,_knee,_ankle,5.5,_dark);
    singularity_local_limb(_faces,[_knee[0],_knee[1]+2,_knee[2]-4],[_ankle[0],_ankle[1]+2,_ankle[2]+5],6.5,_armour);
    // Round faceted kneecap, with a small exposed central hinge.
    for(var i=0;i<8;++i) {
        var a=i*45;var b=a+45;
        singularity_local_face(_faces,[[_knee[0]+dcos(a)*4.6,_knee[1]+4,_knee[2]+dsin(a)*4.6],[_knee[0]+dcos(b)*4.6,_knee[1]+4,_knee[2]+dsin(b)*4.6],
            [_knee[0]+dcos(b)*2.4,_knee[1]+4.8,_knee[2]+dsin(b)*2.4],[_knee[0]+dcos(a)*2.4,_knee[1]+4.8,_knee[2]+dsin(a)*2.4]],_metal);
    }
    singularity_local_limb(_faces,[_ankle[0],_ankle[1],_ankle[2]+3],[_ankle[0],_ankle[1]+0.5,-9],6,_dark);
    var boot_x =_ankle[0];var boot_y=_ankle[1];var toe=11+_front*2;
    var vertices=[[boot_x-4,boot_y-5,-16],[boot_x+4,boot_y-5,-16],[boot_x+4.5,boot_y+toe-3,-16],[boot_x+2.8,boot_y+toe,-16],[boot_x-2.8,boot_y+toe,-16],[boot_x-4.5,boot_y+toe-3,-16],
        [boot_x-3.5,boot_y-4,-8],[boot_x+3.5,boot_y-4,-8],[boot_x+3.8,boot_y+toe-4,-12],[boot_x+2.4,boot_y+toe,-13],[boot_x-2.4,boot_y+toe,-13],[boot_x-3.8,boot_y+toe-4,-12]];
    for(var i=0;i<6;++i) {var j=(i+1) mod 6;singularity_local_face(_faces,[vertices[i],vertices[j],vertices[j+6],vertices[i+6]],i mod 2==0 ? _armour : _dark);}
    singularity_local_face(_faces,[vertices[6],vertices[7],vertices[8],vertices[9],vertices[10],vertices[11]],_metal);
}
function singularity_local_face(_faces,_points,_colour) {array_push(_faces,{vertices:_points,colour:_colour});}
function singularity_local_shard(_faces,_u,_v,_z,_width,_height,_colour) {
    var points=[[_u,_v,_z+_height],[_u-_width,_v,_z],[_u,_v-_width*0.6,_z],[_u+_width,_v,_z],[_u,_v+_width*0.6,_z],[_u,_v,_z-_height*0.7]];
    var sides=[[0,1,2],[0,2,3],[0,3,4],[0,4,1],[5,2,1],[5,3,2],[5,4,3],[5,1,4]];
    for(var i=0;i<8;++i) {var f=sides[i];singularity_local_face(_faces,[points[f[0]],points[f[1]],points[f[2]]],merge_colour(_colour,c_black,(i mod 4)*0.13));}
}
function singularity_local_limb(_faces,_a,_b,_width,_colour) {
    var dx=_b[0]-_a[0];var dy=_b[1]-_a[1];var dz=_b[2]-_a[2];
    var length=max(0.001,sqrt(dx*dx+dy*dy+dz*dz));dx/=length;dy/=length;dz/=length;
    var flat=sqrt(dx*dx+dy*dy);var ux=flat>0.001 ? dy/flat : 1;var uy=flat>0.001 ? -dx/flat : 0;
    var vx=-dz*uy;var vy=dz*ux;var vz=dx*uy-dy*ux;var points=[];
    for(var i=0;i<8;++i) {
        var c=i<4 ? _a : _b;var u=(i mod 4==0 || i mod 4==3) ? -1 : 1;var v=i mod 4<2 ? -1 : 1;var r=_width*(i<4 ? 0.5 : 0.4);
        array_push(points,[c[0]+(ux*u+vx*v)*r,c[1]+(uy*u+vy*v)*r,c[2]+vz*v*r]);
    }
    var ids=[[0,1,2,3],[4,7,6,5],[0,4,5,1],[1,5,6,2],[2,6,7,3],[3,7,4,0]];
    for(var i=0;i<6;++i) {var f=ids[i];singularity_local_face(_faces,[points[f[0]],points[f[1]],points[f[2]],points[f[3]]],merge_colour(_colour,c_black,(i mod 3)*0.12));}
}
// Clip in model space at the ground plane: emerging geometry cannot cover the ground.
function singularity_emergence_face(_points,_offset) {
    var result=[];
    for(var i=0;i<array_length(_points);++i) {
        var a=_points[i];var b=_points[(i+1) mod array_length(_points)];
        var az=a[2]-_offset;var bz=b[2]-_offset;
        if(az>=-16) array_push(result,[a[0],a[1],az]);
        if((az>=-16)!=(bz>=-16)) {
            var t=(-16-az)/(bz-az);array_push(result,[lerp(a[0],b[0],t),lerp(a[1],b[1],t),-16]);
        }
    }
    return result;
}
function draw_singularity(_x,_y,_angle,_time,_kick,_aim,_charge=0,_recovery=0,_visual_scale=1,_attack=-1,_impact=0,_emerge=1,_skill_release=0) {
    var pose=singularity_pose(_time,_attack<0 ? _aim*0.8 : _attack,_impact,_charge,_skill_release);var bob=pose.bob;
    var model_faces=[];var faces=[];var violet=make_colour_rgb(135,84,194);var pale=make_colour_rgb(216,191,247);var dark=make_colour_rgb(34,24,49);var glow=make_colour_rgb(178,116,255);
    // Asymmetric planted feet, bent knees and exposed mechanical joints.
    var shift=sin(_time*1.1+0.4)*1.5*(1-pose.weight);
    for(var side=-1;side<=1;side+=2) {
        var foot_y=side==1 ? -10 : 12;
        var hip=[side*10+shift,-3,39+bob];var knee=[side*13+shift*0.4,foot_y+8+pose.weight*6,14-pose.weight*6+bob*0.12];var ankle=[side*15,foot_y,-7];
        tower_stance_leg(model_faces,hip,knee,ankle,side==-1 ? 1 : 0,violet,dark,pale);
    }
    // Short front panels expose the legs; longer split tails trail behind the stance.
    for(var i=0;i<8;++i) {
        var a=i*45;var b=a+36;var swing=sin(_time*1.8+i)*1.5+pose.weight*5;
        var hem=dsin(a)>0 ? 24 : 9;
        var top=[dcos(a)*14,dsin(a)*9,62+bob];var outer=[dcos(a)*21,dsin(a)*14,40+bob];
        var bottom=[dcos(a)*(21+swing),dsin(a)*(15+swing),hem+bob*0.25];var edge=[dcos(b)*20,dsin(b)*14,hem+11+bob*0.25];
        singularity_local_face(model_faces,[top,outer,bottom],i mod 2==0 ? violet : dark);
        singularity_local_face(model_faces,[top,bottom,edge],i mod 3==0 ? pale : violet);
    }
    for(var side=-1;side<=1;side+=2) {
        singularity_local_shard(model_faces,side*24,-2,68+bob,12,16,side==1 ? violet : pale);
        singularity_local_shard(model_faces,side*30,-5,79+bob,5,16,violet);
        var hand=side==1 ? pose.right : pose.left;
        var elbow=side==1 ? pose.right_elbow : pose.left_elbow;
        singularity_local_limb(model_faces,[side*18,0,66+bob],elbow,10,dark);
        singularity_local_limb(model_faces,elbow,hand,8,violet);
        singularity_local_shard(model_faces,hand[0],hand[1],hand[2],5,6,pale);
        for(var f=0;f<3;++f) singularity_local_limb(model_faces,[hand[0]+(f-1)*3,hand[1],hand[2]+2],[hand[0]+(f-1)*4,hand[1]+4,hand[2]+8],2,pale);
    }
    singularity_local_shard(model_faces,0,-2,87+bob,15,20,dark);
    singularity_local_shard(model_faces,-11,0,94+bob,7,23,pale);singularity_local_shard(model_faces,11,0,94+bob,7,23,violet);
    singularity_local_face(model_faces,[[-2,10,92+bob],[2,10,94+bob],[1,12,81+bob],[-1,12,80+bob]],glow);
    singularity_local_shard(model_faces,0,15,62+bob,10,11,dark);
    for(var i=0;i<28;++i) {
        var a=i*360/28+_time*25;var b=a+10;var r=14+pose.ritual*5;
        singularity_local_face(model_faces,[[dcos(a)*r,15+dsin(a)*4,62+bob+dsin(a)*r*0.7],[dcos(b)*r,15+dsin(b)*4,62+bob+dsin(b)*r*0.7],
            [dcos(b)*(r+2),15+dsin(b)*4,62+bob+dsin(b)*(r+2)*0.7],[dcos(a)*(r+2),15+dsin(a)*4,62+bob+dsin(a)*(r+2)*0.7]],i mod 4==0 ? pale : glow);
    }
    var rise=clamp((_emerge-0.12)/0.78,0,1);rise=rise*rise*(3-2*rise);var offset=(1-rise)*145;
    for(var i=0;i<array_length(model_faces);++i) {
        var face=model_faces[i];var vertices=singularity_emergence_face(face.vertices,offset);
        if(array_length(vertices)>=3) wanderer_mesh_face(faces,vertices,face.colour,_x,_y,_angle,_visual_scale);
    }
    array_sort(faces,function(_a,_b){return sign(_a.sort_depth-_b.sort_depth);});
    for(var f=0;f<array_length(faces);++f) {var face=faces[f];draw_set_colour(face.colour);draw_primitive_begin(pr_trianglefan);
        for(var k=0;k<array_length(face.points);++k) draw_vertex(face.points[k][0],face.points[k][1]);draw_primitive_end();}
}
function singularity_draw_actor(_tower) {
    var p=_tower.pulse_left>0 ? 1-_tower.pulse_left/_tower.definition.pulse_windup : 0;
    var charge=_tower.charge_mode==TowerChargeState.Charging ? tower_charge_progress(_tower) : 0;
    var emerge=1-_tower.summon_left/_tower.definition.summon_duration;
    draw_singularity(_tower.x,_tower.summon_left>0 ? _tower.y : tower_visual_y(_tower),_tower.facing,_tower.idle_time,0,0,charge,0,obj_camera.zoom,
        p,_tower.pulse_fx/_tower.definition.pulse_recovery,emerge,_tower.skill_release/0.8);
}
