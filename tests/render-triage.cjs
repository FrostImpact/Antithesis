// Preview the production procedural model, without substituting an illustration.
const fs=require('node:fs');const path=require('node:path');
const root=path.resolve(__dirname,'..');
let colour=[0,0,0],points=[],polygons=[];
const host={clamp:(v,a,b)=>Math.max(a,Math.min(b,v)),lerp:(a,b,t)=>a+(b-a)*t,
  max:Math.max,sqrt:Math.sqrt,sin:Math.sin,dsin:v=>Math.sin(v*Math.PI/180),dcos:v=>Math.cos(v*Math.PI/180),
  make_colour_rgb:(...v)=>v,merge_colour:(a,b,t)=>a.map((v,i)=>Math.round(v+(b[i]-v)*t)),c_black:[0,0,0],pr_trianglefan:0,
  array_length:a=>a.length,array_push:(a,v)=>a.push(v),array_sort:(a,f)=>a.sort(f),sign:Math.sign,
  draw_set_colour:c=>colour=c,draw_primitive_begin:()=>points=[],draw_vertex:(x,y)=>points.push([x,y]),
  draw_primitive_end:()=>polygons.push({colour,points})};
const source=fs.readFileSync(path.join(root,'scripts/scr_defender/scr_defender.gml'),'utf8').replace(/\bmod\b/g,'%');
const draw=new Function('s',`with(s){${source};return draw_triage;}`)(host);
draw(180,455,320,0,0,0,0,0,7);
draw(580,455,320,1,0,1,1,0,7);
draw(990,455,140,2,0,0,0,0,7);
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="1240" height="560" viewBox="0 0 1240 560"><rect width="1240" height="560" fill="#13171c"/><g stroke-linejoin="round">${polygons.map(p=>`<polygon fill="rgb(${p.colour})" points="${p.points.map(v=>v.join(',')).join(' ')}"/>`).join('')}</g><g fill="#e8e0d6" font-family="sans-serif"><text x="32" y="38" font-size="23">TRIAGE / REFERENCE MODEL STUDY</text><text x="100" y="510">REST</text><text x="520" y="510">SANCTUARY</text><text x="920" y="510">REAR</text><text x="32" y="544" font-size="12" fill="#8c9aa8">Production geometry · rose cloth / articulated applicator / medical vials / folded hood</text></g></svg>`;
fs.writeFileSync(path.join(root,'docs/triage-design.svg'),svg);
if(process.argv.includes('--polygons')) fs.writeFileSync(path.join(root,'docs/triage-preview-polygons.json'),JSON.stringify(polygons));
console.log('Rendered docs/triage-design.svg from production GML.');
