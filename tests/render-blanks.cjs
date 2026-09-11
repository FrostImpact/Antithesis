// Preview the exact atlas cells drawn by GameMaker; baking stays offline.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const art=require('../tools/bake-blanks.cjs');
const {variants,W,H,SCALE,FRAMES,DIRECTIONS,COLUMNS,ROWS,renderCell,png}=art;
const readGameMakerJson=file=>JSON.parse(fs.readFileSync(file,'utf8').replace(/,\s*([}\]])/g,'$1'));
const sheetW=1040,sheetH=660,sheet=new Uint8Array(sheetW*sheetH*4);
for(let i=0;i<sheet.length;i+=4){sheet[i]=173;sheet[i+1]=178;sheet[i+2]=176;sheet[i+3]=255;}
const images=[];
for(let row=0;row<2;row++)variants.forEach((d,index)=>{
 const cell=renderCell(d,45,row===0?0:Math.PI);
 const scale=2.4*d.visual_scale,x0=Math.round(180+index*330-40*scale),y0=Math.round(70+row*285+104*2.4-104*scale);
 const encoded=png(W,H,cell);
 images.push('<image x="'+x0+'" y="'+y0+'" width="'+W*scale+'" height="'+H*scale+'" href="data:image/png;base64,'+encoded.toString('base64')+'"/>');
 for(let y=0;y<Math.ceil(H*scale);y++)for(let x=0;x<Math.ceil(W*scale);x++){
   const source=(Math.min(H-1,Math.floor(y/scale))*W+Math.min(W-1,Math.floor(x/scale)))*4;
   const dest=((y0+y)*sheetW+x0+x)*4,alpha=cell[source+3]/255;
   for(let k=0;k<3;k++)sheet[dest+k]=Math.round(sheet[dest+k]*(1-alpha)+cell[source+k]*alpha);
 }
});
fs.mkdirSync('.build',{recursive:true});
fs.writeFileSync('.build/blanks-unlabelled.png',png(sheetW,sheetH,sheet));
fs.writeFileSync('docs/blanks.png',png(sheetW,sheetH,sheet));
fs.writeFileSync('docs/blanks.svg','<svg xmlns="http://www.w3.org/2000/svg" width="1040" height="660"><rect width="1040" height="660" fill="#adb2b0"/>'+images.join('')+'<g fill="#202629" font-family="sans-serif" font-size="18"><text x="30" y="30">BLANKS / VOID FRAGMENTS</text><text x="100" y="65">WISP / QUICK</text><text x="430" y="65">HUSK / BASELINE</text><text x="760" y="65">HULK / HEAVY</text><text x="30" y="645">VOID FRAGMENTS / LIGHTWEIGHT HOVER ANIMATION</text></g></svg>');
const urls=variants.map(d=>{
 const dir='sprites/spr_blank_'+d.name;
 const meta=readGameMakerJson(dir+'/spr_blank_'+d.name+'.yy');
 assert.equal(meta.width,W*COLUMNS);assert.equal(meta.height,H*ROWS);
 return '../'+dir+'/'+meta.frames[0].name+'.png';
});
const html=`<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Blanks — Enemy redesign</title>
<style>*{box-sizing:border-box}body{margin:0;background:#141819;color:#edf0e9;font:15px system-ui}main{max-width:1120px;margin:auto;padding:36px 28px}small{color:#adb3ae;letter-spacing:3px}h1{font-size:38px;font-weight:500;margin:12px 0}p{color:#adb3ae;line-height:1.6;max-width:780px}canvas{width:100%;display:block;background:#adb2b0;border-radius:6px;margin:28px 0 16px}nav{display:flex;flex-wrap:wrap;align-items:center;gap:24px}button{border:1px solid #5b6561;border-radius:4px;padding:9px 18px;background:#252d29;color:#edf0e9;cursor:pointer}label{display:flex;align-items:center;gap:10px}input{accent-color:#c8d6bc}section{display:grid;grid-template-columns:repeat(3,1fr);gap:28px;border-top:1px solid #343d37;margin-top:28px;padding-top:16px}h2{font-size:16px;font-weight:500}section p{font-size:13px}a{color:#d1dfc6}</style>
<main><small>ANTITHESIS / CHARACTER STUDY</small><h1>The Blanks, rebuilt.</h1><p>Fragments of the null realm. Broken mineral shells surround dim void cores, suspended just above the ground.</p><canvas width="1040" height="380" aria-label="Animated Wisp, Husk and Hulk enemies"></canvas>
<nav><button id="pause">Pause</button><label>Movement <input id="speed" type="range" min="0" max="1.5" step="0.1" value="1"></label><button id="ground">Dark ground</button></nav>
<section><article><h2>01 / WISP</h2><p>A narrow, torn splinter with a small exposed core. The lightest silhouette in the group.</p></article><article><h2>02 / HUSK</h2><p>A fractured diamond shell enclosing a dark seed. Opposing pale plates frame the central opening.</p></article><article><h2>03 / HULK</h2><p>A broad suspended monolith, split by a faint vertical rift. Detached stone chips hang beside its shell.</p></article></section>
<p>Flexing shell plates, visible sway, circling chips and a pulsing core, over 2.4–3.6 seconds. Each shell moves independently. Pause freezes the pose; Movement previews slow and root effects. These are the actual in-game sprite sheets.</p></main>
<script>
const urls=${JSON.stringify(urls)},scales=${JSON.stringify(variants.map(d=>d.visual_scale))},rates=${JSON.stringify(variants.map(d=>1/d.drift_period))};
const canvas=document.querySelector('canvas'),g=canvas.getContext('2d'),images=urls.map(src=>{const i=new Image();i.src=src;return i;});
let paused=false,last=0,dark=false;const phases=[0,0,0];
document.querySelector('#pause').onclick=e=>{paused=!paused;e.target.textContent=paused?'Play':'Pause';};
document.querySelector('#ground').onclick=e=>{dark=!dark;canvas.style.background=dark?'#252c29':'#adb2b0';e.target.textContent=dark?'Light ground':'Dark ground';};
function frame(now){const dt=Math.min(.05,(now-last)/1000);last=now;g.clearRect(0,0,1040,380);
images.forEach((img,i)=>{if(!paused)phases[i]=(phases[i]+dt*rates[i]*Number(document.querySelector('#speed').value)*${FRAMES})%${FRAMES};
const pose=Math.floor(phases[i]),s=scales[i]*3;
if(img.complete&&img.naturalWidth)g.drawImage(img,(pose%${COLUMNS})*${W},Math.floor(pose/${COLUMNS})*${H},${W},${H},180+i*330-40*s,290-104*s,${W}*s,${H}*s);
g.fillStyle=dark?'#edf0e9':'#242a27';g.font='14px system-ui';g.fillText(['WISP / SPLINTER','HUSK / SHELL','HULK / MONOLITH'][i],125+i*330,348);});requestAnimationFrame(frame);}requestAnimationFrame(frame);
</script></html>`;
fs.writeFileSync('docs/blanks-motion.html',html);
console.log('Generated Blank model sheet and motion study from the runtime atlas assets.');
