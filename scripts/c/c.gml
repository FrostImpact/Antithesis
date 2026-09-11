function loadout_initialize() {
    obj_game.card_catalog=[
        {title:"VESTRAL",kind:"TOWER",tower:"vestral",copy:"Adds one Vestral copy to your loadout. Place it for 75 Bits.",accent:make_colour_rgb(116,216,231)},
        {title:"WANDERER",kind:"TOWER",tower:"wanderer",copy:"Adds one Wanderer copy to your loadout. Place it for 120 Bits.",accent:make_colour_rgb(187,244,72)},
        {title:"BIT CACHE",kind:"ITEM",tower:"",copy:"Gain 150 Bits. Spend Bits to deploy towers from your loadout.",accent:make_colour_rgb(236,202,121)},
        {title:"BOUNTY PROTOCOL",kind:"GAMEPLAY",tower:"",copy:"Each kill grants +2 Bits for the rest of the run. Repeat uses stack.",accent:make_colour_rgb(195,163,236)}
    ];
    obj_game.loadout={bits:200,keys:["","","","",""],copies:[0,0,0,0,0],cards:[2,1,1,0],
        selected:-1,hover:-1,fan_hover:[0,0,0,0],pending:-1,use_elapsed:0,use_duration:0.85,
        deck:[],deck_cursor:0,last_reward_round:0,kill_bonus:0,
        notice:"Use a tower card, then select its loadout slot to place it.",notice_left:0};
}
function loadout_notice(_text) {
    obj_game.loadout.notice=_text; obj_game.loadout.notice_left=4;
}
function loadout_find_slot(_key) {
    for(var i=0;i<5;++i) if(obj_game.loadout.keys[i]==_key) return i;
    return -1;
}
function loadout_refill_deck() {
    var cards=[0,0,0,1,1,1,2,2,3];
    for(var i=array_length(cards)-1;i>0;--i) {
        var j=irandom(i); var swap=cards[i]; cards[i]=cards[j]; cards[j]=swap;
    }
    obj_game.loadout.deck=cards; obj_game.loadout.deck_cursor=0;
}
function loadout_round_reward(_round) {
    var s=obj_game.loadout;
    if(_round<=s.last_reward_round) return false;
    s.last_reward_round=_round; s.bits+=75;
    for(var i=0;i<3;++i) {
        if(s.deck_cursor>=array_length(s.deck)) loadout_refill_deck();
        var card=s.deck[s.deck_cursor]; s.deck_cursor+=1;
        s.cards[card]+=1;
    }
    loadout_notice("Round cleared: +75 Bits and 3 cards stored.");
    return true;
}
function loadout_award_kill() { obj_game.loadout.bits+=6+obj_game.loadout.kill_bonus; }
function loadout_use_card(_index) {
    var s=obj_game.loadout;
    if(obj_game.paused || s.pending>=0 || _index<0 || _index>=array_length(s.cards) || s.cards[_index]<=0) return false;
    var card=obj_game.card_catalog[_index];
    if(card.tower!="" && loadout_find_slot("")<0) {
        loadout_notice("All five loadout slots are occupied."); return false;
    }
    s.cards[_index]-=1; s.pending=_index; s.use_elapsed=0; s.selected=-1;
    return true;
}
function loadout_tick(_dt) {
    var s=obj_game.loadout;
    s.hover=loadout_card_at_pointer();
    for(var i=0;i<array_length(s.cards);++i)
        s.fan_hover[i]=lerp(s.fan_hover[i],s.hover==i || s.selected==i ? 1 : 0,1-exp(-15*_dt));
    if(obj_game.paused) return;
    s.notice_left=max(0,s.notice_left-_dt);
    if(s.pending<0) return;
    s.use_elapsed=min(s.use_duration,s.use_elapsed+_dt);
    if(s.use_elapsed<s.use_duration) return;
    var index=s.pending; var card=obj_game.card_catalog[index];
    s.pending=-1;
    if(card.tower!="") {
        var slot=loadout_find_slot("");
        if(slot>=0) {
            s.keys[slot]=card.tower;
            s.copies[slot]=1;
        }
    } else if(index==2) { s.bits+=150; loadout_notice("Bit Cache opened: +150 Bits."); }
    else { s.kill_bonus+=2; loadout_notice("Bounty Protocol active: +"+string(s.kill_bonus)+" Bits per kill."); }
}
function loadout_can_place(_slot) {
    var s=obj_game.loadout;
    if(obj_game.paused || _slot<0 || _slot>=5 || s.keys[_slot]=="" || s.copies[_slot]<=0) return false;
    return s.bits>=tower_definition(s.keys[_slot]).bit_cost;
}
function loadout_select(_slot) {
    var s=obj_game.loadout;
    if(obj_game.paused || _slot<0 || _slot>=5 || s.keys[_slot]=="") return false;
    if(instance_exists(obj_placement) && instance_exists(obj_placement.moving_tower)) {
        loadout_notice("Finish or cancel the current move first."); return false;
    }
    if(!loadout_can_place(_slot)) {
        loadout_notice("Not enough Bits to deploy this tower.");
        return false;
    }
    obj_game.build_tower_type=s.keys[_slot]; s.selected=-1;
    if(!instance_exists(obj_placement)) instance_create_depth(0,0,0,obj_placement);
    return true;
}
function loadout_place(_wx,_wy) {
    var slot=loadout_find_slot(obj_game.build_tower_type);
    if(!loadout_can_place(slot) || !placement_is_valid(_wx,_wy)) return noone;
    var tower=instance_create_depth(project_x(_wx,_wy),project_y(_wx,_wy),-project_y(_wx,_wy),obj_tower,
        {world_x:_wx,world_y:_wy,tower_type:obj_game.build_tower_type});
    if(!instance_exists(tower)) return noone;
    obj_game.loadout.keys[slot]="";
    obj_game.loadout.copies[slot]=0;
    obj_game.loadout.bits-=tower.definition.bit_cost;
    return tower;
}

function loadout_slot_rect(_slot) { return [428+_slot*105,658,518+_slot*105,748]; }
function loadout_card_pose(_index) {
    var s=obj_game.loadout; var rank=0;
    for(var i=0;i<_index;++i) if(s.cards[i]>0) rank+=1;
    var angle=20+rank*16;
    var lift=s.fan_hover[_index]; var radius=143+lift*22;
    return {x:dcos(angle)*radius,y:768-dsin(angle)*radius,angle:90-angle,scale:1+lift*0.18};
}
function loadout_card_point(_pose,_x,_y) {
    _x*=_pose.scale; _y*=_pose.scale;
    return [_pose.x+_x*dcos(_pose.angle)-_y*dsin(_pose.angle),_pose.y+_x*dsin(_pose.angle)+_y*dcos(_pose.angle)];
}
function loadout_card_contains(_index,_mx,_my) {
    var p=loadout_card_pose(_index); var dx=_mx-p.x; var dy=_my-p.y;
    var lx=(dx*dcos(p.angle)+dy*dsin(p.angle))/p.scale;
    var ly=(-dx*dsin(p.angle)+dy*dcos(p.angle))/p.scale;
    return abs(lx)<=34 && abs(ly)<=53;
}
function loadout_card_at_pointer() {
    var s=obj_game.loadout; var mx=device_mouse_x_to_gui(0); var my=device_mouse_y_to_gui(0);
    if(s.hover>=0 && s.cards[s.hover]>0 && point_in_rectangle(mx,my,24,278,276,530)) return s.hover;
    if(s.selected>=0 && s.cards[s.selected]>0 && loadout_card_contains(s.selected,mx,my)) return s.selected;
    if(s.selected<0 && s.hover>=0 && s.cards[s.hover]>0 && loadout_card_contains(s.hover,mx,my)) return s.hover;
    for(var i=array_length(s.cards)-1;i>=0;--i)
        if(s.cards[i]>0 && loadout_card_contains(i,mx,my)) return i;
    return -1;
}
function loadout_pointer_blocked() {
    var s=obj_game.loadout; var mx=device_mouse_x_to_gui(0); var my=device_mouse_y_to_gui(0);
    if(point_in_rectangle(mx,my,373,608,993,768)) return true;
    if(mx>=0 && my<=768 && point_distance(0,768,mx,my)<=191) return true;
    if(loadout_card_at_pointer()>=0) return true;
    return (s.selected>=0 || s.hover>=0) && point_in_rectangle(mx,my,24,278,276,530);
}
function loadout_handle_input() {
    if(!mouse_check_button_pressed(mb_left) || !loadout_pointer_blocked()) return false;
    var s=obj_game.loadout; var mx=device_mouse_x_to_gui(0); var my=device_mouse_y_to_gui(0);
    if((s.selected>=0 || s.hover>=0) && point_in_rectangle(mx,my,24,278,276,530)) {
        if(point_in_rectangle(mx,my,246,282,272,310)) { s.selected=-1; s.hover=-1; }
        return true;
    }
    for(var i=0;i<5;++i) {
        var r=loadout_slot_rect(i);
        if(point_in_rectangle(mx,my,r[0],r[1],r[2],r[3])) { loadout_select(i); return true; }
    }
    var card=loadout_card_at_pointer();
    if(card>=0) {
        if(s.selected==card) loadout_use_card(card);
        else s.selected=card;
    }
    return true;
}

function loadout_draw_card(_index,_pose,_alpha=1,_show_count=true) {
    var card=obj_game.card_catalog[_index];
    var corners=[[-34,-53],[34,-53],[34,53],[-34,53]];
    draw_set_alpha(_alpha); draw_set_colour(make_colour_rgb(29,35,36));
    draw_primitive_begin(pr_trianglefan);
    for(var i=0;i<4;++i) { var v=loadout_card_point(_pose,corners[i][0],corners[i][1]); draw_vertex(v[0],v[1]); }
    draw_primitive_end();
    draw_set_colour(card.accent);
    for(var i=0;i<4;++i) {
        var a=loadout_card_point(_pose,corners[i][0],corners[i][1]); var b=loadout_card_point(_pose,corners[(i+1) mod 4][0],corners[(i+1) mod 4][1]);
        draw_line_width(a[0],a[1],b[0],b[1],1.5);
    }
    if(card.tower!="") tower_definition(card.tower).draw_model(_pose.x,_pose.y+14,300,0,0,0,0,0,0.9*_pose.scale);
    else {
        diamond(_pose.x,_pose.y,14*_pose.scale,20*_pose.scale,card.accent);
        draw_set_colour(make_colour_rgb(29,35,36));
        draw_set_halign(fa_center); draw_set_valign(fa_middle); draw_text(_pose.x,_pose.y,_index==2 ? "B" : "+");
    }
    var label=loadout_card_point(_pose,0,35);
    draw_set_colour(card.accent); draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_text_transformed(label[0],label[1],card.title,0.48*_pose.scale,0.48*_pose.scale,-_pose.angle);
    var count=loadout_card_point(_pose,21,-40);
    if(_show_count) draw_text_transformed(count[0],count[1],"x"+string(obj_game.loadout.cards[_index]),0.65,0.65,-_pose.angle);
    draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_alpha(1);
}
function loadout_draw() {
    var s=obj_game.loadout; var theme=obj_game.ui_theme;
    draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_colour(theme.surface); draw_rectangle(1120,24,1342,92,false);
    draw_set_colour(make_colour_rgb(236,202,121)); draw_text(1136,34,string(s.bits)+" BITS");
    var equipped=0;for(var i=0;i<5;++i) if(s.keys[i]!="") equipped+=1;
    draw_set_colour(make_colour_rgb(23,29,31));
    draw_primitive_begin(pr_trianglefan); draw_vertex(0,768);
    for(var arc=0;arc<=32;++arc) draw_vertex(dcos(arc/32*90)*190,768-dsin(arc/32*90)*190);
    draw_primitive_end();
    draw_set_colour(theme.border);
    for(var arc=0;arc<32;++arc) draw_line_width(dcos(arc/32*90)*190,768-dsin(arc/32*90)*190,
        dcos((arc+1)/32*90)*190,768-dsin((arc+1)/32*90)*190,1);
    var total=0; var front=s.selected>=0 ? s.selected : s.hover;
    for(var i=0;i<array_length(s.cards);++i) {
        total+=s.cards[i];
        if(s.cards[i]>0 && i!=front) loadout_draw_card(i,loadout_card_pose(i));
    }
    if(front>=0 && s.cards[front]>0) loadout_draw_card(front,loadout_card_pose(front));
    
    var detail=s.selected>=0 ? s.selected : s.hover;
    if(detail>=0 && s.cards[detail]>0) {
        var card=obj_game.card_catalog[detail];
        draw_set_colour(theme.surface); draw_rectangle(24,278,276,530,false);
        draw_set_colour(card.accent); draw_rectangle(24,278,28,530,false);
        draw_text(42,294,card.kind+" / x"+string(s.cards[detail]));
        draw_set_colour(theme.title); draw_text(42,322,card.title);
        if(card.tower!="") tower_definition(card.tower).draw_model(150,409,300,0,0,0,0,0,1.7);
        else {
            diamond(150,383,20,28,card.accent);
            draw_set_colour(theme.surface); draw_set_halign(fa_center); draw_text(150,376,detail==2 ? "B" : "+"); draw_set_halign(fa_left);
        }
        draw_set_colour(theme.copy); draw_text_ext(42,424,card.copy,17,216);
        draw_set_halign(fa_left); draw_set_colour(theme.muted); draw_text(253,289,"x");
    }

    for(var slot=0;slot<5;++slot) {
        var r=loadout_slot_rect(slot); var key=s.keys[slot];
        var active=instance_exists(obj_placement) && !instance_exists(obj_placement.moving_tower) && obj_game.build_tower_type==key;
        if(active) {
            draw_set_colour(theme.surface_active);
            draw_rectangle(r[0],r[1],r[2],r[3],false);
        }
        var border_col=active ? make_colour_rgb(187,244,72) : merge_colour(theme.border,c_black,0.5);
        draw_set_colour(border_col);
        draw_line_width(r[0],r[1],r[2],r[1],3);
        draw_line_width(r[2],r[1],r[2],r[3],3);
        draw_line_width(r[2],r[3],r[0],r[3],3);
        draw_line_width(r[0],r[3],r[0],r[1],3);
        draw_set_colour(theme.title); draw_text(r[0]+6,r[1]+4,string(slot+1));
        if(key=="") { draw_set_colour(theme.disabled); draw_text(r[0]+20,r[1]+35,"EMPTY"); continue; }
        var d=tower_definition(key);
        draw_set_alpha(1); d.draw_model((r[0]+r[2])*0.5,r[1]+43,300,0,0,0,0,0,1.25);
        draw_set_colour(loadout_can_place(slot) ? make_colour_rgb(187,244,72) : theme.disabled);
        draw_text(r[0]+6,r[1]+68,string(d.bit_cost)+" BITS");
    }
    if(s.notice_left>0) {
        draw_set_colour(theme.surface); draw_rectangle(373,564,993,598,false);
        draw_set_colour(theme.title); draw_text(387,573,s.notice);
    }
    if(s.pending>=0) {
        var p=clamp(s.use_elapsed/s.use_duration,0,1); var eased=1-power(1-p,3);
        var pose={x:lerp(130,683,eased),y:lerp(665,400,eased),angle:lerp(28,0,eased),scale:1+sin(p*pi)*1.1};
        loadout_draw_card(s.pending,pose,1-power(p,6),false);
        draw_set_alpha(sin(p*pi)*0.7); draw_set_colour(obj_game.card_catalog[s.pending].accent);
        for(var ray=0;ray<8;++ray) {
            var a=ray*45+p*90; var radius=45+p*70;
            draw_line_width(pose.x+dcos(a)*radius,pose.y+dsin(a)*radius,pose.x+dcos(a)*(radius+12),pose.y+dsin(a)*(radius+12),2);
        }
        draw_set_alpha(1);
    }
    draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_alpha(1);
}