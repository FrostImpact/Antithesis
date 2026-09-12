const fs=require('node:fs'),assert=require('node:assert/strict');
const read=p=>fs.readFileSync(p,'utf8').replace(/\bmod\b/g,'%');
function createHost(){
 const towers=[];
 const h={obj_game:{paused:false,build_tower_type:'vestral'},obj_tower:'tower',obj_placement:{exists:false,moving_tower:null},
  noone:null,min:Math.min,max:Math.max,floor:Math.floor,abs:Math.abs,sin:Math.sin,exp:Math.exp,power:Math.pow,pi:Math.PI,
  dcos:a=>Math.cos(a*Math.PI/180),dsin:a=>Math.sin(a*Math.PI/180),clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),
  lerp:(a,b,t)=>a+(b-a)*t,array_length:a=>a.length,array_push:(a,v)=>a.push(v),irandom:n=>Math.floor(n*.37),string:String,
  make_colour_rgb:(...v)=>v,string_width:s=>s.length*7,GlossaryTerm:{None:-1,GreatPowers:0,Charge:1,Lock:2},TowerAbility:{DoubleTap:0,ShockBolts:1,Overloaded:2},
  draw_singularity:()=>{},singularity_muzzle:()=>{},draw_triage:()=>{},triage_muzzle:()=>{},draw_defender:()=>{},defender_muzzle:()=>{},draw_wanderer:()=>{},wanderer_muzzle:()=>{},
  variable_struct_exists:(o,k)=>k in o,variable_struct_get:(o,k)=>o[k],
  mouseX:1100,mouseY:150,pressed:false,mb_left:0,
  device_mouse_x_to_gui:()=>h.mouseX,device_mouse_y_to_gui:()=>h.mouseY,mouse_check_button_pressed:()=>h.pressed,
  point_in_rectangle:(x,y,a,b,c,d)=>x>=a&&x<=c&&y>=b&&y<=d,point_distance:(x,y,a,b)=>Math.hypot(a-x,b-y),
  instance_number:o=>o==='tower'?towers.length:0,
  instance_destroy:o=>{o.exists=false;},
  instance_exists:o=>o==='tower'?towers.length>0:!!o&&o.exists!==false,
  project_x:x=>x,project_y:(x,y)=>y,valid:true,placement_is_valid:()=>h.valid,
  instance_create_depth:(x,y,depth,o,data)=>{
   if(o===h.obj_placement){h.obj_placement.exists=true;return h.obj_placement;}
   const t={...data,x,y,definition:h.obj_game.tower_catalog[data.tower_type]};towers.push(t);return t;
  }};
 const api=new Function('s',`with(s){${read('scripts/scr_definitions/scr_definitions.gml')}\n${read('scripts/c/c.gml')};obj_game.tower_catalog=build_tower_catalog();obj_game.ui_theme=build_ui_theme();return {init:loadout_initialize,use:loadout_use_card,tick:loadout_tick,reward:loadout_round_reward,choose:loadout_choose_reward,rewardActive:loadout_reward_active,addBits:loadout_add_bits,notice:loadout_notice,slotRect:loadout_slot_rect,handleY:loadout_handle_y,rewardRect:loadout_reward_rect,kill:loadout_award_kill,select:loadout_select,place:loadout_place,canPlace:loadout_can_place,blocked:loadout_pointer_blocked,click:loadout_handle_input,pose:loadout_card_pose,cardAt:loadout_card_at_pointer,draw:loadout_draw};}`)(h);
 api.init();return {h,api,towers};
}
function test(){
 const {h,api,towers}=createHost();const s=h.obj_game.loadout;
 assert.deepEqual(s.cards,[2,1,1,0,1,1]);assert.ok(s.keys.every(k=>k===''));
 assert.equal(api.select(0),false,'Starter cards are stored, not automatically usable towers');
 assert.equal(api.use(0),true);assert.equal(api.use(0),false,'Double click cannot spend twice');
 assert.equal(s.cards[0],1);assert.equal(s.copies[0],0);
 h.obj_game.paused=true;api.tick(2);assert.equal(s.use_elapsed,0);assert.equal(s.copies[0],0);
 h.obj_game.paused=false;api.tick(.4);assert.equal(s.copies[0],0);api.tick(.5);
 assert.equal(s.keys[0],'vestral');assert.equal(s.copies[0],1);api.tick(4);assert.equal(s.copies[0],1,'Reward commits exactly once');
 assert.equal(api.select(0),true);assert.equal(s.bits,200);assert.equal(s.copies[0],1,'Preview is free');
 const cancel=new Function('s',`with(s){${read('scripts/scr_combat/scr_combat.gml')};return tower_cancel_move;}`)(h);
 assert.equal(cancel(),true);assert.equal(h.obj_placement.exists,false);assert.equal(s.bits,200);assert.equal(s.copies[0],1,'Cancelling normal placement preserves Bits and copies');
 assert.equal(api.select(0),true);
 h.valid=false;assert.equal(api.place(3,3),null);assert.equal(s.bits,200);assert.equal(s.copies[0],1);
 h.valid=true;assert.ok(api.place(3,3));assert.equal(s.bits,125);assert.equal(s.copies[0],0);
 assert.equal(api.place(4,4),null,'No unowned duplicate placements');assert.equal(towers.length,1);
 assert.equal(s.keys[0],'','Deployment frees its card slot');
 api.use(1);api.tick(1);assert.equal(s.keys[0],'wanderer');s.bits=119;
 assert.equal(api.select(0),false);assert.equal(api.place(4,4),null);
 s.bits=120;api.select(0);assert.ok(api.place(4,4));assert.equal(s.bits,0);
 api.use(2);api.tick(1);assert.equal(s.bits,150);
 s.cards[3]=2;api.use(3);api.tick(1);api.kill();assert.equal(s.bits,158);api.use(3);api.tick(1);api.kill();assert.equal(s.bits,168);
 const before=s.cards.slice(),bits=s.bits;
 for(let r=1;r<=3;r++){
  assert.equal(api.reward(r),true);assert.equal(new Set(s.reward_cards).size,3);
  api.tick(.7);assert.equal(api.choose(0),true);api.tick(.9);
 }
 assert.equal(s.cards.reduce((a,v,i)=>a+v-before[i],0),3,'Three rounds award exactly three chosen cards');
 assert.equal(s.bits,bits+225);assert.equal(api.reward(3),false);assert.equal(s.bits,bits+225);
 assert.equal(s.copies[0],0,'Drawn cards remain stored until used');
 s.bits=1000;s.cards[0]=10;
 while(towers.length<6){api.use(0);api.tick(1);api.select(0);assert.ok(api.place(2,2),'Five hotbar slots must not impose a five-deployed-tower limit');}
 h.obj_placement.moving_tower=towers[0];assert.equal(api.select(1),false,'Selecting loadout cannot interrupt relocation');
 h.obj_placement.moving_tower=null;
 h.obj_game.paused=true;assert.equal(api.use(0),false);assert.equal(api.select(0),false);assert.equal(api.place(2,2),null);
 h.obj_game.paused=false;
 for(let i=0;i<4;i++){s.cards[i]=1;s.selected=i;const p=api.pose(i);h.mouseX=p.x;h.mouseY=Math.min(767,p.y);assert.equal(api.cardAt(),i);assert.equal(api.blocked(),true);}
 h.mouseX=1100;h.mouseY=150;s.selected=-1;s.hover=-1;assert.equal(api.blocked(),false);
 h.mouseX=500;h.mouseY=710;assert.equal(api.blocked(),true);
 s.selected=0;h.mouseX=150;h.mouseY=502;h.pressed=true;
 const beforeUse=s.cards[0];assert.equal(api.click(),true);assert.equal(s.cards[0],beforeUse-1,'Clicking the expanded card spends once');
 api.click();assert.equal(s.cards[0],beforeUse-1,'Pending animation prevents repeated use');
 h.pressed=false;api.tick(1);
 const occupied=s.keys.slice();s.keys=['a','b','c','d','e'];const stored=s.cards[0];
 assert.equal(api.use(0),false,'A sixth distinct tower type cannot enter a full hotbar');assert.equal(s.cards[0],stored);
 s.keys=occupied;
 console.log('PASS: stored starters, use animation, pause, duplicate guards, tower/item/gameplay rewards, deck refill, round deduplication, costs/copies, five hotbar slots and UI boundaries.');
}
if(require.main===module)test();module.exports={createHost};
