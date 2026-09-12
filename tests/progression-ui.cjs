const fs=require('node:fs'),assert=require('node:assert/strict');
const {createHost}=require('./loadout.cjs');
const {h,api}=createHost(),s=h.obj_game.loadout;
const tick=(n=30)=>{for(let i=0;i<n;i++)api.tick(.05);};
const point=(x,y)=>{h.mouseX=x;h.mouseY=y;};
const click=()=>{h.pressed=true;api.click();h.pressed=false;};
// Collapse is persistent; hovering temporarily reveals, then closes on departure.
point(683,api.handleY());click();assert.equal(s.bar_pinned,false);tick(40);
assert.equal(s.bar_open,0);point(500,710);assert.equal(api.blocked(),false,'Hidden slots cannot intercept the world');
point(683,767);assert.equal(api.blocked(),true);tick(40);
assert.equal(s.bar_open,1);assert.equal(s.bar_pinned,false,'Peeking never pins the tray');
point(800,735);tick(10);assert.equal(s.bar_open,1,'Tray stays usable while moving from tip to slots');
point(1100,200);tick(40);assert.equal(s.bar_open,0);
point(683,767);click();tick(40);assert.equal(s.bar_pinned,true);assert.equal(s.bar_open,1);
point(1100,200);tick(30);assert.equal(s.bar_open,1,'Pinned tray stays open away from pointer');
point(1100,710);assert.equal(api.blocked(),false,'Removed hint box has no hidden hit area');
// Currency is authoritative immediately; display ticks up and never overshoots.
assert.equal(s.bits_display,200);api.addBits(150);assert.equal(s.bits,350);assert.equal(s.bits_display,200);
assert.equal(s.bits_gain,150);api.tick(.05);assert.equal(s.bits_display,200);
api.tick(.15);assert.ok(s.bits_display>200&&s.bits_display<350);
h.obj_game.paused=true;const paused=s.bits_display;tick();assert.equal(s.bits_display,paused);h.obj_game.paused=false;
api.addBits(6);assert.equal(s.bits_gain,156);let previous=s.bits_display;
for(let i=0;i<100;i++){api.tick(.05);assert.ok(s.bits_display>=previous&&s.bits_display<=s.bits);assert.ok(Number.isInteger(s.bits_display));previous=s.bits_display;}
assert.equal(s.bits_display,356);assert.equal(s.bits_gain_left,0);
api.addBits(150);api.use(0);api.tick(.9);api.select(0);assert.ok(api.place(3,3));
assert.ok(s.bits_display<=s.bits,'Spending during count-up cannot leave a false balance');tick(100);assert.equal(s.bits_display,s.bits);
// Notifications enter, transition to the next message and expire.
api.notice('First');api.tick(.1);assert.equal(s.notice,'First');assert.ok(s.notice_age>0);
api.notice('Second');assert.equal(s.notice,'First');assert.equal(s.notice_next,'Second');
api.tick(.2);assert.equal(s.notice,'Second');assert.equal(s.notice_age,0);tick(60);assert.equal(s.notice_left,0);
// Exactly one selected reward arrives; all other offers are discarded.
const before=s.cards.slice(),bits=s.bits;
assert.equal(api.reward(1),true);assert.equal(s.bits,bits+75);assert.deepEqual(s.cards,before);
assert.equal(new Set(s.reward_cards).size,3);assert.equal(api.choose(0),false,'Opening animation prevents accidental selection');
assert.equal(api.reward(1),false);assert.equal(api.reward(2),false,'Cannot replace a pending reward');
point(1100,200);assert.equal(api.blocked(),true,'Reward screen owns world input');
assert.equal(api.use(0),false);assert.equal(api.select(0),false);
h.obj_game.paused=true;tick();assert.equal(s.reward_time,0);h.obj_game.paused=false;api.tick(.7);
const choices=s.reward_cards.slice(),r=api.rewardRect(1);point((r[0]+r[2])/2,(r[1]+r[3])/2);click();
assert.equal(s.reward_state,'claim');assert.equal(api.choose(2),false);assert.deepEqual(s.cards,before);
h.obj_game.paused=true;tick();assert.equal(s.reward_time,0);h.obj_game.paused=false;
api.tick(.9);assert.equal(api.rewardActive(),false);
assert.deepEqual(s.cards,before.map((v,i)=>v+(i===choices[1]?1:0)));tick(30);
assert.equal(s.cards.reduce((a,v,i)=>a+v-before[i],0),1,'Claim animation cannot award twice');
// Shared HP ramp reaches lime, amber and red smoothly.
const source=fs.readFileSync('scripts/scr_interface/scr_interface.gml','utf8').replace(/\bmod\b/g,'%');
h.merge_colour=(a,b,t)=>a.map((v,i)=>v+(b[i]-v)*t);
const colour=new Function('h',`with(h){${source};return ui_health_colour;}`)(h);
assert.deepEqual(colour(1),[186,235,83]);assert.deepEqual(colour(.5),[235,189,78]);assert.deepEqual(colour(0),[236,82,78]);
for(let i=1;i<=100;i++)assert.ok(colour(i/100).every((v,k)=>Math.abs(v-colour((i-1)/100)[k])<3));
console.log('PASS: compact tray, minimize/peek/pin, hidden hit areas, animated Bits/spending/pause, notice transitions, unique reward choice/claim and HP gradient.');
