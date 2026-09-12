function loadout_initialize() {
    obj_game.card_catalog=[
        {title:"VESTRAL",kind:"TOWER",tower:"vestral",copy:"Adds one Vestral copy to your loadout. Place it for 75 Bits.",accent:make_colour_rgb(116,216,231)},
        {title:"WANDERER",kind:"TOWER",tower:"wanderer",copy:"Adds one Wanderer copy to your loadout. Place it for 120 Bits.",accent:make_colour_rgb(187,244,72)},
        {title:"BIT CACHE",kind:"ITEM",tower:"",copy:"Gain 150 Bits. Spend Bits to deploy towers from your loadout.",accent:make_colour_rgb(236,202,121)},
        {title:"BOUNTY PROTOCOL",kind:"GAMEPLAY",tower:"",copy:"Each kill grants +2 Bits for the rest of the run. Repeat uses stack.",accent:make_colour_rgb(195,163,236)},
        {title:"TRIAGE",kind:"TOWER",tower:"triage",copy:"Prepare TRIAGE, Support / Medic. Deploy for 100 Bits.",accent:make_colour_rgb(246,143,191)},
        {title:"SINGULARITY",kind:"TOWER",tower:"singularity",copy:"Prepare SINGULARITY, AoE / Area Denial. Deploy for 140 Bits.",accent:make_colour_rgb(184,132,247)}
    ];
    obj_game.loadout={bits:200,keys:["","","","",""],copies:[0,0,0,0,0],cards:[2,1,1,0,1,1],
        selected:-1,hover:-1,fan_hover:[0,0,0,0,0,0],pending:-1,use_elapsed:0,use_duration:0.85,
        deck:[],deck_cursor:0,last_reward_round:0,kill_bonus:0,
        notice:"",notice_left:0,notice_age:0,notice_next:"",
        bits_display:200,bits_gain:0,bits_gain_left:0,bits_wait:0,bits_fraction:0,
        bar_pinned:true,bar_open:1,bar_peek:false,bar_suppress:false,slot_hover:[0,0,0,0,0],
        reward_state:"",reward_cards:[],reward_choice:-1,reward_time:0,reward_hover:[0,0,0]};
}
function loadout_notice(_text) {
    var s=obj_game.loadout;
    if(s.notice_left>0) { s.notice_next=_text; s.notice_left=min(s.notice_left,0.18); return; }
    s.notice=_text; s.notice_left=2.8; s.notice_age=0;
}
function loadout_add_bits(_amount) {
    if(_amount<=0) return;
    var s=obj_game.loadout;
    var settled=s.bits_display>=s.bits;
    s.bits+=_amount;
    s.bits_gain=s.bits_gain_left>0 ? s.bits_gain+_amount : _amount;
    s.bits_gain_left=1.5; if(settled) s.bits_wait=0.16;
}
function loadout_reward_active() { return obj_game.loadout.reward_state!=""; }
function loadout_choose_reward(_index) {
    var s=obj_game.loadout;
    if(obj_game.paused || s.reward_state!="choice" || _index<0 || _index>=array_length(s.reward_cards)) return false;
    s.reward_choice=_index; s.reward_state="claim"; s.reward_time=0;
    return true;
}
function loadout_find_slot(_key) {
    for(var i=0;i<5;++i) if(obj_game.loadout.keys[i]==_key) return i;
    return -1;
}
function loadout_refill_deck() {
    var cards=[0,0,0,1,1,1,2,2,3,4,4,4,5,5,5];
    for(var i=array_length(cards)-1;i>0;--i) {
        var j=irandom(i); var swap=cards[i]; cards[i]=cards[j]; cards[j]=swap;
    }
    obj_game.loadout.deck=cards; obj_game.loadout.deck_cursor=0;
}
function loadout_round_reward(_round) {
    var s=obj_game.loadout;
    if(_round<=s.last_reward_round || loadout_reward_active()) return false;
    s.last_reward_round=_round; loadout_add_bits(75);
    s.reward_cards=[];
    // Distinct choices prevent a reward screen with three identical cards.
    while(array_length(s.reward_cards)<3) {
        if(s.deck_cursor>=array_length(s.deck)) loadout_refill_deck();
        var card=s.deck[s.deck_cursor]; s.deck_cursor+=1;
        var duplicate=false;
        for(var i=0;i<array_length(s.reward_cards);++i) if(s.reward_cards[i]==card) duplicate=true;
        if(!duplicate) array_push(s.reward_cards,card);
    }
    s.reward_state="enter"; s.reward_time=0; s.reward_choice=-1;
    s.selected=-1; s.hover=-1;
    return true;
}
function loadout_award_kill() { loadout_add_bits(6+obj_game.loadout.kill_bonus); }
function loadout_use_card(_index) {
    var s=obj_game.loadout;
    if(obj_game.paused || loadout_reward_active() || s.pending>=0 || _index<0 || _index>=array_length(s.cards) || s.cards[_index]<=0) return false;
    var card=obj_game.card_catalog[_index];
    if(card.tower!="" && loadout_find_slot("")<0) {
        loadout_notice("All five loadout slots are occupied."); return false;
    }
    s.cards[_index]-=1; s.pending=_index; s.use_elapsed=0; s.selected=-1;
    return true;
}
function loadout_tick(_dt) {
    var s=obj_game.loadout;
    var mx=device_mouse_x_to_gui(0); var my=device_mouse_y_to_gui(0);
    var handle=loadout_handle_hovered();
    var over_bar=point_in_rectangle(mx,my,479,loadout_bar_top()-22,887,768);
    // Clicking closed stays closed until the pointer leaves; hover can then peek.
    if(!over_bar) s.bar_suppress=false;
    s.bar_peek=!s.bar_suppress && (handle || (s.bar_peek && over_bar));
    s.bar_open=lerp(s.bar_open,s.bar_pinned || s.bar_peek ? 1 : 0,1-exp(-14*_dt));
    if(s.bar_open<0.001) s.bar_open=0;
    if(s.bar_open>0.999) s.bar_open=1;
    for(var slot=0;slot<5;++slot) {
        var r=loadout_slot_rect(slot);
        var hovered=!loadout_reward_active() && point_in_rectangle(mx,my,r[0],r[1],r[2],r[3]);
        s.slot_hover[slot]=lerp(s.slot_hover[slot],hovered ? 1 : 0,1-exp(-18*_dt));
    }
    s.hover=loadout_reward_active() ? -1 : loadout_card_at_pointer();
    for(var i=0;i<array_length(s.cards);++i)
        s.fan_hover[i]=lerp(s.fan_hover[i],s.hover==i || s.selected==i ? 1 : 0,1-exp(-15*_dt));
    if(obj_game.paused) return;
    s.notice_age+=_dt;
    s.notice_left=max(0,s.notice_left-_dt);
    if(s.notice_left<=0 && s.notice_next!="") {
        var next=s.notice_next; s.notice_next=""; loadout_notice(next);
    }
    s.bits_wait=max(0,s.bits_wait-_dt);
    if(s.bits_wait<=0 && s.bits_display<s.bits) {
        s.bits_fraction+=_dt*max(45,(s.bits-s.bits_display)*6);
        var add=min(s.bits-s.bits_display,floor(s.bits_fraction));
        s.bits_fraction-=add; s.bits_display+=add;
    }
    if(s.bits_display>=s.bits) { s.bits_display=s.bits; s.bits_fraction=0; }
    s.bits_gain_left=max(0,s.bits_gain_left-_dt);
    if(s.bits_display<s.bits) s.bits_gain_left=max(0.4,s.bits_gain_left);
    if(loadout_reward_active()) {
        s.reward_time+=_dt;
        for(var i=0;i<3;++i) {
            var r=loadout_reward_rect(i);
            var over=s.reward_state=="choice" && point_in_rectangle(mx,my,r[0],r[1],r[2],r[3]);
            s.reward_hover[i]=lerp(s.reward_hover[i],over ? 1 : 0,1-exp(-14*_dt));
        }
        if(s.reward_state=="enter" && s.reward_time>=0.65) { s.reward_state="choice"; s.reward_time=0; }
        if(s.reward_state=="claim" && s.reward_time>=0.85) {
            var card=s.reward_cards[s.reward_choice]; s.cards[card]+=1;
            s.fan_hover[card]=1; s.reward_state=""; s.reward_cards=[];
            loadout_notice(obj_game.card_catalog[card].title+" added to your cards");
        }
    }
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
    } else if(index==2) { loadout_add_bits(150); loadout_notice("Bit Cache redeemed"); }
    else { s.kill_bonus+=2; loadout_notice("Bounty Protocol active: +"+string(s.kill_bonus)+" Bits per kill."); }
}
function loadout_can_place(_slot) {
    var s=obj_game.loadout;
    if(obj_game.paused || loadout_reward_active() || _slot<0 || _slot>=5 || s.keys[_slot]=="" || s.copies[_slot]<=0) return false;
    return s.bits>=tower_definition(s.keys[_slot]).bit_cost;
}
function loadout_select(_slot) {
    var s=obj_game.loadout;
    if(obj_game.paused || loadout_reward_active() || _slot<0 || _slot>=5 || s.keys[_slot]=="") return false;
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
    obj_game.loadout.bits_display=max(0,min(obj_game.loadout.bits,obj_game.loadout.bits_display-tower.definition.bit_cost));
    return tower;
}

function loadout_bar_top() { return lerp(790,688,obj_game.loadout.bar_open); }
function loadout_handle_y() { return lerp(768,688,obj_game.loadout.bar_open); }
function loadout_handle_hovered() {
    var dy=device_mouse_y_to_gui(0)-loadout_handle_y();
    return dy<=0 && dy>=-12 && abs(device_mouse_x_to_gui(0)-683)/18+abs(dy)/12<=1;
}
function loadout_slot_rect(_slot) { var top=loadout_bar_top()+8; return [491+_slot*78,top,563+_slot*78,top+60]; }
function loadout_reward_rect(_index) {
    var s=obj_game.loadout;
    var enter=s.reward_state=="enter" ? clamp((s.reward_time-_index*0.1)/0.4,0,1) : 1;
    var top=260+32*power(1-enter,3)-s.reward_hover[_index]*10;
    return [335+_index*240,top,551+_index*240,top+278];
}
function loadout_notice_rect() {
    var s=obj_game.loadout;
    var reveal=1-power(1-clamp(s.notice_age/0.22,0,1),3);
    var fade=clamp(s.notice_left/0.25,0,1);
    var top=100-(1-reveal)*12+(1-fade)*6;
    var width=clamp(string_width(s.notice)+72,220,620);
    return [(1366-width)*0.5,top,(1366+width)*0.5,top+38];
}
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
    if(loadout_reward_active()) return true;
    if(point_in_rectangle(mx,my,1120,24,1342,80)) return true;
    if(s.notice_left>0) {
        var notice_rect=loadout_notice_rect();
        if(point_in_rectangle(mx,my,notice_rect[0],notice_rect[1],notice_rect[2],notice_rect[3])) return true;
    }
    if(loadout_handle_hovered() || point_in_rectangle(mx,my,479,loadout_bar_top(),887,768)) return true;
    if(mx>=0 && my<=768 && point_distance(0,768,mx,my)<=191) return true;
    if(loadout_card_at_pointer()>=0) return true;
    return (s.selected>=0 || s.hover>=0) && point_in_rectangle(mx,my,24,278,276,530);
}
function loadout_handle_input() {
    if(!mouse_check_button_pressed(mb_left) || !loadout_pointer_blocked()) return false;
    var s=obj_game.loadout; var mx=device_mouse_x_to_gui(0); var my=device_mouse_y_to_gui(0);
    if(loadout_reward_active()) {
        for(var i=0;i<3;++i) {
            var r=loadout_reward_rect(i);
            if(point_in_rectangle(mx,my,r[0],r[1],r[2],r[3])) loadout_choose_reward(i);
        }
        return true;
    }
    if(loadout_handle_hovered()) {
        s.bar_pinned=!s.bar_pinned; s.bar_peek=false; s.bar_suppress=!s.bar_pinned;
        return true;
    }
    if((s.selected>=0 || s.hover>=0) && point_in_rectangle(mx,my,24,278,276,530)) {
        if(point_in_rectangle(mx,my,246,282,272,310)) { s.selected=-1; s.hover=-1; }
        else loadout_use_card(s.selected>=0 ? s.selected : s.hover);
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
    draw_set_alpha(_alpha); draw_set_colour(obj_game.ui_theme.surface);
    draw_primitive_begin(pr_trianglefan);
    for(var i=0;i<4;++i) { var v=loadout_card_point(_pose,corners[i][0],corners[i][1]); draw_vertex(v[0],v[1]); }
    draw_primitive_end();
    draw_set_colour(merge_colour(obj_game.ui_theme.border,card.accent,0.45));
    for(var i=0;i<4;++i) {
        var a=loadout_card_point(_pose,corners[i][0],corners[i][1]); var b=loadout_card_point(_pose,corners[(i+1) mod 4][0],corners[(i+1) mod 4][1]);
        draw_line_width(a[0],a[1],b[0],b[1],1);
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
    ui_draw_surface(1120,24,1342,80);
    draw_set_colour(theme.muted); draw_text_transformed(1136,34,"AVAILABLE BITS",0.72,0.72,0);
    draw_set_colour(theme.accent); draw_text_transformed(1136,51,string(s.bits_display),1.2,1.2,0);
    if(s.bits_gain_left>0) {
        var gain_alpha=clamp(s.bits_gain_left/0.35,0,1);
        draw_set_alpha(gain_alpha); draw_set_colour(make_colour_rgb(194,236,117));
        draw_set_halign(fa_right);draw_text_transformed(1326,51-(1-gain_alpha)*8,"+"+string(s.bits_gain),0.95,0.95,0);
        draw_set_halign(fa_left);draw_set_alpha(1);
    }
    var equipped=0;for(var i=0;i<5;++i) if(s.keys[i]!="") equipped+=1;
    draw_set_colour(theme.surface);
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
        ui_draw_surface(24,278,276,530);
        draw_set_colour(card.accent); draw_rectangle(42,278,90,280,false);
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

    var bar_top=loadout_bar_top();
    // A narrow tray and one diamond handle leave more of the battlefield visible.
    ui_draw_surface(479,bar_top,887,bar_top+76);
    var hy=loadout_handle_y();
    draw_set_colour(loadout_handle_hovered() ? theme.muted : theme.border);
    draw_triangle(665,hy,683,hy-12,701,hy,false);
    for(var slot=0;slot<5;++slot) {
        var r=loadout_slot_rect(slot); var key=s.keys[slot];
        var active=instance_exists(obj_placement) && !instance_exists(obj_placement.moving_tower) && obj_game.build_tower_type==key;
        draw_set_colour(active ? theme.surface_active : merge_colour(theme.shadow,theme.surface_hover,s.slot_hover[slot]));
        draw_rectangle(r[0],r[1],r[2],r[3],false);
        var border_col=active ? theme.accent : theme.border;
        draw_set_colour(border_col);
        draw_rectangle(r[0],r[1],r[2],r[3],true);
        draw_set_colour(theme.muted); draw_text_transformed(r[0]+5,r[1]+3,string(slot+1),0.7,0.7,0);
        if(key=="") { draw_set_colour(theme.divider);draw_line(r[0]+31,r[1]+29,r[0]+41,r[1]+29); continue; }
        var d=tower_definition(key);
        draw_set_halign(fa_right);draw_set_colour(theme.muted);draw_text_transformed(r[2]-5,r[1]+3,"x"+string(s.copies[slot]),0.7,0.7,0);draw_set_halign(fa_left);
        draw_set_alpha(1); d.draw_model((r[0]+r[2])*0.5,r[1]+37-s.slot_hover[slot]*3,300,0,0,0,0,0,0.9);
        draw_set_colour(loadout_can_place(slot) ? theme.accent : theme.disabled);
        draw_set_halign(fa_center);draw_text_transformed((r[0]+r[2])*0.5,r[1]+45,string(d.bit_cost)+" B",0.78,0.78,0);draw_set_halign(fa_left);
        if(s.slot_hover[slot]>0.1 && !loadout_reward_active()) {
            var cx=(r[0]+r[2])*0.5;var tip_width=string_width(d.name)*0.8+20;
            draw_set_alpha(s.slot_hover[slot]);ui_draw_surface(cx-tip_width*0.5,bar_top-43,cx+tip_width*0.5,bar_top-17);
            draw_set_colour(theme.title);
            draw_set_halign(fa_center);draw_text_transformed(cx,bar_top-36,d.name,0.8,0.8,0);draw_set_halign(fa_left);draw_set_alpha(1);
        }
    }
    if(s.notice_left>0) {
        var reveal=clamp(s.notice_age/0.22,0,1); reveal=1-power(1-reveal,3);
        var fade=clamp(s.notice_left/0.25,0,1);
        var notice_rect=loadout_notice_rect();
        var nx=notice_rect[0];var ny=notice_rect[1];var width=notice_rect[2]-nx;
        draw_set_alpha(reveal*fade);
        ui_draw_surface(nx,ny,nx+width,ny+38);
        diamond(nx+18,ny+19,4,6,theme.accent);
        draw_set_colour(theme.title); draw_text(nx+34,ny+11,s.notice);
        draw_set_colour(theme.accent);draw_rectangle(nx+1,ny+37,nx+1+(width-2)*clamp(s.notice_left/2.8,0,1),ny+38,false);
        draw_set_alpha(1);
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
    if(loadout_reward_active()) loadout_draw_reward();
    draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_alpha(1);
}

function loadout_draw_reward() {
    var s=obj_game.loadout; var theme=obj_game.ui_theme;
    var claiming=s.reward_state=="claim";
    var p=claiming ? clamp(s.reward_time/0.85,0,1) : 0;
    var reveal=s.reward_state=="enter" ? clamp(s.reward_time/0.25,0,1) : 1;
    draw_set_alpha(0.72*reveal*(1-p));draw_set_colour(theme.shadow);
    draw_rectangle(0,0,1366,768,false);
    draw_set_alpha(reveal*(1-p));draw_set_halign(fa_center);
    draw_set_colour(theme.accent);draw_text_transformed(683,158,"ROUND "+string(s.last_reward_round)+" COMPLETE",0.8,0.8,0);
    draw_set_colour(theme.title);draw_text_transformed(683,190,"Choose your reward",1.6,1.6,0);
    draw_set_colour(theme.muted);draw_text(683,226,"Keep one card. The others are discarded.");
    draw_set_halign(fa_left);
    for(var i=0;i<array_length(s.reward_cards);++i) {
        var card=obj_game.card_catalog[s.reward_cards[i]];
        var r=loadout_reward_rect(i);
        if(claiming && i==s.reward_choice) continue;
        var alpha=s.reward_state=="enter" ? clamp((s.reward_time-i*0.1)/0.3,0,1) : 1;
        if(claiming) { alpha*=max(0,1-p*3); r[1]+=p*70; r[3]+=p*70; }
        draw_set_alpha(alpha);
        ui_draw_surface(r[0],r[1],r[2],r[3]);
        draw_set_colour(merge_colour(theme.border,card.accent,s.reward_hover[i]));draw_rectangle(r[0],r[1],r[2],r[3],true);
        draw_set_colour(card.accent);draw_rectangle(r[0]+18,r[1],r[0]+64,r[1]+2,false);
        draw_text_transformed(r[0]+18,r[1]+18,card.kind,0.75,0.75,0);
        draw_set_colour(theme.title);draw_text(r[0]+18,r[1]+45,card.title);
        if(card.tower!="") tower_definition(card.tower).draw_model((r[0]+r[2])*0.5,r[1]+164,300,s.reward_time,0,0,0,0,1.8);
        else diamond((r[0]+r[2])*0.5,r[1]+122,22,32,card.accent);
        draw_set_colour(theme.copy);draw_text_ext(r[0]+18,r[1]+185,card.copy,18,180);
    }
    if(claiming) {
        var chosen=s.reward_cards[s.reward_choice];var r=loadout_reward_rect(s.reward_choice);
        var travel=clamp((p-0.12)/0.88,0,1);var eased=travel*travel*(3-2*travel);
        var destination=loadout_card_pose(chosen);
        var pose={x:lerp((r[0]+r[2])*0.5,destination.x,eased),y:lerp(r[1]+139,destination.y,eased)-sin(travel*pi)*75,
            angle:lerp(0,destination.angle,eased),scale:lerp(2.4,1,eased)};
        loadout_draw_card(chosen,pose,1,false);
        draw_set_alpha((1-p)*0.6);draw_set_colour(obj_game.card_catalog[chosen].accent);
        draw_ellipse(pose.x-42*pose.scale,pose.y-58*pose.scale,pose.x+42*pose.scale,pose.y+58*pose.scale,true);
    }
    draw_set_alpha(1);draw_set_halign(fa_left);draw_set_valign(fa_top);
}
