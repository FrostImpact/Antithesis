const fs=require('node:fs'),assert=require('node:assert/strict'),zlib=require('node:zlib');
const {variants,mesh,renderCell,W,H,FRAMES,DIRECTIONS,COLUMNS,ROWS}=require('../tools/bake-blanks.cjs');
const code=fs.readFileSync('scripts/scr_blanks/scr_blanks.gml','utf8').replace(/\bmod\b/g,'%');
let calls=[],blend='normal';
const host={obj_camera:{map_angle:45,zoom:1},floor:Math.floor,pi:Math.PI,c_white:0xffffff,power:Math.pow,sin:Math.sin,
 bm_add:'add',bm_normal:'normal',clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),
 draw_sprite_part_ext:(...args)=>calls.push({args,blend}),gpu_set_blendmode:v=>blend=v};
const draw=new Function('s',`with(s){${code};return blank_draw_model;}`)(host);
assert.equal(FRAMES,48);assert.equal(DIRECTIONS,1);
function decode(png){
 const width=png.readUInt32BE(16),height=png.readUInt32BE(20),chunks=[];
 assert.equal(png[24],8);assert.equal(png[25],6,'RGBA sprite');assert.equal(png[28],0,'Non-interlaced sprite');
 for(let at=8;at<png.length;){const n=png.readUInt32BE(at);if(png.toString('ascii',at+4,at+8)==='IDAT')chunks.push(png.subarray(at+8,at+8+n));at+=n+12;}
 const raw=zlib.inflateSync(Buffer.concat(chunks));
 // GameMaker may rewrite PNGs with any standard scanline filter after import.
 const bytes=width*4;
 for(let y=0;y<height;y++){
   const at=y*(bytes+1),filter=raw[at];
   for(let x=0;x<bytes;x++){
     const left=x>=4?raw[at+1+x-4]:0,up=y?raw[at+1+x-(bytes+1)]:0,
       corner=y&&x>=4?raw[at+1+x-(bytes+1)-4]:0;
     let predictor=0;
     if(filter===1)predictor=left;
     else if(filter===2)predictor=up;
     else if(filter===3)predictor=Math.floor((left+up)/2);
     else if(filter===4){const p=left+up-corner,a=Math.abs(p-left),b=Math.abs(p-up),c=Math.abs(p-corner);predictor=a<=b&&a<=c?left:b<=c?up:corner;}
     else assert.equal(filter,0,'Supported PNG filter');
     raw[at+1+x]=(raw[at+1+x]+predictor)&255;
   }
   raw[at]=0; // Normalize filter bytes before comparing decoded image data.
 }
 return raw;
}
for(const d of variants){
 const dir=`sprites/spr_blank_${d.name}/`,meta=JSON.parse(fs.readFileSync(dir+`spr_blank_${d.name}.yy`,'utf8').replace(/,\s*([}\]])/g,'$1'));
 const png=fs.readFileSync(dir+meta.frames[0].name+'.png');
 assert.equal(meta.width,W*COLUMNS);assert.equal(meta.height,H*ROWS);
 assert.equal(png.readUInt32BE(16),meta.width);assert.equal(png.readUInt32BE(20),meta.height);
 const raw=decode(png),layer=decode(fs.readFileSync(dir+'layers/'+meta.frames[0].name+'/'+meta.layers[0].name+'.png'));
 assert.ok(raw.equals(layer),'Flattened sprite pixels match their editor layer after PNG re-encoding');

 assert.deepEqual(mesh(d,0),mesh(d,Math.PI*2),'Drift loops without a seam');
 for(let frame=0;frame<FRAMES;frame++){
   const cell=renderCell(d,45,frame*Math.PI*2/FRAMES);
   assert.ok(cell.some(v=>v>0));
   for(let y=0;y<H;y++){
     const start=(Math.floor(frame/COLUMNS)*H+y)*(meta.width*4+1)+1+(frame%COLUMNS)*W*4;
     assert.deepEqual(raw.subarray(start,start+W*4),Buffer.from(cell.subarray(y*W*4,(y+1)*W*4)),'Shipped atlas matches the current sculpt');
   }
   calls=[];draw({enemy_definition:{atlas:d.name,visual_scale:d.visual_scale,spawn_duration:d.spawn_duration},spawn_left:0,x:400,y:300,drift_phase:(frame+.001)*Math.PI*2/FRAMES,hit_flash:0});
   assert.equal(calls.length,1,'One sprite draw including shadow');
   assert.deepEqual(calls[0].args.slice(2,6),[(frame%COLUMNS)*W,Math.floor(frame/COLUMNS)*H,W,H]);
 }
 assert.ok(d.drift_period>=2.4 && d.drift_period<=3.6,'Visible fragment cycle');
}
for(const zoom of [.72,1,1.28]){
 host.obj_camera.zoom=zoom;calls=[];
 draw({enemy_definition:{atlas:'husk',visual_scale:.88,spawn_duration:.65},spawn_left:0,x:400,y:300,drift_phase:0,hit_flash:.15});
 assert.equal(calls.length,2);assert.equal(blend,'normal','Hit feedback restores blend');
 const a=calls[0].args;assert.equal(a[6]+40*a[8],400);assert.equal(a[7]+104*a[9],300,'Ground anchor stays fixed at every zoom');
}
const html=fs.readFileSync('docs/blanks-motion.html','utf8');new Function(html.match(/<script>([\s\S]*?)<\/script>/)[1]);
for(const p of [0,.2,.5,.8,1]){
 calls=[];draw({enemy_definition:{atlas:'husk',visual_scale:.88,spawn_duration:.65},spawn_left:.65*(1-p),x:400,y:300,drift_phase:0,hit_flash:0});
 const a=calls[0].args;
 assert.ok(a.slice(2).every(Number.isFinite));
 assert.equal(a[6]+40*a[8],400);assert.equal(a[7]+104*a[9],300,'Materialization grows from its ground anchor');
 assert.ok(a[11]>=0&&a[11]<=1);
 if(p===0)assert.equal(a[11],0);if(p===1)assert.equal(a[11],1);
}
console.log('PASS: 144 unclipped hover frames, shipped PNG and metadata parity, cyclic geometry, one draw, fixed shadow anchor, hit blend and preview syntax.');
