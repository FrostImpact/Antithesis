// Offline art source. Void fragments use 48 hover frames; runtime reads baked frames.
// No packages required: deterministic triangle rasterizer + Node PNG encoder.
const fs=require('node:fs');
const path=require('node:path');
const zlib=require('node:zlib');
const assert=require('node:assert/strict');
const ROOT=path.resolve(__dirname,'..');
const C={white:[234,234,229],side:[164,171,174],black:[12,14,18],dark:[35,40,45],edge:[91,99,102]};
const W=80,H=120,SCALE=1.25,FRAMES=48,DIRECTIONS=1,COLUMNS=12,ROWS=4;
const catalog=new Function(fs.readFileSync(path.join(ROOT,'scripts/scr_definitions/scr_definitions.gml'),'utf8')+';return build_enemy_catalog();')();
const variants=[{...catalog.fast,key:'fast',name:'wisp'},
 {...catalog.intrusion,key:'intrusion',name:'husk'},
 {...catalog.heavy,key:'heavy',name:'hulk'}];
const radians=a=>a*Math.PI/180;
const readGameMakerJson=file=>JSON.parse(fs.readFileSync(file,'utf8').replace(/,\s*([}\]])/g,'$1'));

const {mesh}=require('./blank-models.cjs');

function project(p,heading){
 const a=radians(heading+135),x=p[0]*Math.cos(a)-p[1]*Math.sin(a),y=p[0]*Math.sin(a)+p[1]*Math.cos(a);
 return [40+x*SCALE,104+(y*.510204-p[2])*SCALE,y+p[2]*.510204];
}
function renderCell(d,heading,phase){
 const ss=2,w=W*ss,h=H*ss,pixels=new Uint8Array(w*h*4),depth=new Float32Array(w*h).fill(-Infinity);
 // Ground shadow is part of the sprite, so it costs no extra runtime draw.
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){
   const q=((x/ss-40)/(d.width*1.35*SCALE))**2+((y/ss-104)/4)**2;
   if(q<1){const i=(y*w+x)*4;pixels[i]=5;pixels[i+1]=7;pixels[i+2]=9;pixels[i+3]=Math.round((1-q)*65);}
 }
 function tri(a,b,c,colour){
   const area=(b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]);if(Math.abs(area)<1e-8)return;
   const loX=Math.max(0,Math.floor(Math.min(a[0],b[0],c[0]))),hiX=Math.min(w-1,Math.ceil(Math.max(a[0],b[0],c[0])));
   const loY=Math.max(0,Math.floor(Math.min(a[1],b[1],c[1]))),hiY=Math.min(h-1,Math.ceil(Math.max(a[1],b[1],c[1])));
   for(let y=loY;y<=hiY;y++)for(let x=loX;x<=hiX;x++){
     const px=x+.5,py=y+.5,u=((b[0]-px)*(c[1]-py)-(b[1]-py)*(c[0]-px))/area;
     const v=((c[0]-px)*(a[1]-py)-(c[1]-py)*(a[0]-px))/area,t=1-u-v;
     if(u<-.00001||v<-.00001||t<-.00001)continue;
     const z=u*a[2]+v*b[2]+t*c[2],index=y*w+x;if(z<depth[index])continue;depth[index]=z;
     for(let k=0;k<3;k++)pixels[index*4+k]=Math.min(255,Math.round(colour[k]));pixels[index*4+3]=255;
   }
 }
 const faces=mesh(d,phase);
 for(const f of faces){const p=f.p.map(v=>{const q=project(v,heading);return [q[0]*ss,q[1]*ss,q[2]];});
   for(const v of p)assert.ok(v.every(Number.isFinite));
   for(let i=1;i<p.length-1;i++)tri(p[0],p[i],p[i+1],f.c);
 }
 const out=new Uint8Array(W*H*4);
 // Alpha-weighted downsampling avoids dark fringes when GameMaker filters.
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){
   let alpha=0,rgb=[0,0,0];
   for(let dy=0;dy<ss;dy++)for(let dx=0;dx<ss;dx++){const i=((y*ss+dy)*w+x*ss+dx)*4;alpha+=pixels[i+3];for(let k=0;k<3;k++)rgb[k]+=pixels[i+k]*pixels[i+3];}
   const i=(y*W+x)*4;for(let k=0;k<3;k++)out[i+k]=alpha?Math.round(rgb[k]/alpha):0;out[i+3]=Math.round(alpha/(ss*ss));
 }
 for(let x=0;x<W;x++){assert.equal(out[x*4+3],0,`${d.name}: top clipped at heading ${heading}`);assert.equal(out[((H-1)*W+x)*4+3],0,`${d.name}: bottom clipped at heading ${heading}`);}
 for(let y=0;y<H;y++){assert.equal(out[(y*W)*4+3],0,`${d.name}: left clipped`);assert.equal(out[(y*W+W-1)*4+3],0,`${d.name}: right clipped`);}
 return out;
}
const crcTable=Array.from({length:256},(_,n)=>{for(let k=0;k<8;k++)n=n&1?0xedb88320^(n>>>1):n>>>1;return n>>>0;});
function chunk(type,data){const t=Buffer.from(type),body=Buffer.concat([t,data]);let crc=0xffffffff;for(const b of body)crc=crcTable[(crc^b)&255]^(crc>>>8);
 const out=Buffer.alloc(data.length+12);out.writeUInt32BE(data.length);body.copy(out,4);out.writeUInt32BE((crc^0xffffffff)>>>0,out.length-4);return out;}
function png(w,h,rgba){const header=Buffer.alloc(13);header.writeUInt32BE(w);header.writeUInt32BE(h,4);header[8]=8;header[9]=6;
 const scan=Buffer.alloc((w*4+1)*h);for(let y=0;y<h;y++)Buffer.from(rgba.buffer,rgba.byteOffset+y*w*4,w*4).copy(scan,y*(w*4+1)+1);
 return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',header),chunk('IDAT',zlib.deflateSync(scan,{level:9})),chunk('IEND',Buffer.alloc(0))]);}
function bake(){
 for(let vi=0;vi<variants.length;vi++){
   const d=variants[vi],atlas=new Uint8Array(W*COLUMNS*H*ROWS*4);
   for(let heading=0;heading<DIRECTIONS;heading++)for(let frame=0;frame<FRAMES;frame++){
     const cell=renderCell(d,45,frame*Math.PI*2/FRAMES);
     for(let y=0;y<H;y++)atlas.set(cell.subarray(y*W*4,(y+1)*W*4),((Math.floor(frame/COLUMNS)*H+y)*W*COLUMNS+(frame%COLUMNS)*W)*4);
   }
   const sprite=`spr_blank_${d.name}`,dir=path.join(ROOT,'sprites',sprite),meta=readGameMakerJson(path.join(dir,sprite+'.yy'));
   const frame=meta.frames[0].name,layer=meta.layers[0].name,encoded=png(W*COLUMNS,H*ROWS,atlas);
   fs.mkdirSync(path.join(dir,'layers',frame),{recursive:true});
   fs.writeFileSync(path.join(dir,frame+'.png'),encoded);fs.writeFileSync(path.join(dir,'layers',frame,layer+'.png'),encoded);
   console.log(`${d.name}: ${DIRECTIONS*FRAMES} frames, ${encoded.length} compressed bytes; all frame edges clear`);
 }
}
if(require.main===module)bake();
module.exports={variants,mesh,project,renderCell,png,bake,W,H,SCALE,FRAMES,DIRECTIONS,COLUMNS,ROWS};
