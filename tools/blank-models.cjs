// Offline sculpts for the void-fragment enemies. No skeletons or limb animation.
const C={ivory:[224,228,220],pale:[246,246,234],slate:[105,115,116],edge:[153,167,165],
 dark:[24,31,35],void:[8,13,17],core:[184,212,207]};
function mesh(d,phase){
 phase=((phase%(Math.PI*2))+Math.PI*2)%(Math.PI*2);
 const faces=[],fast=d.name==='wisp',heavy=d.name==='hulk';
 const drift=Math.sin(phase)*(fast?3.7:heavy?2.4:3.1),breath=Math.cos(phase)*1.2;
 const sway=Math.sin(phase)*(fast?1.8:heavy?.7:1.2);
 const roll=Math.sin(phase)*(fast?.12:heavy?.055:.085);
 let shellIndex=0;
 const shade=(c,n)=>c.map(v=>Math.min(255,Math.round(v*n)));
 function face(p,c){faces.push({p:p.map(v=>[
   v[0]*Math.cos(roll)-(v[2]-30)*Math.sin(roll)+sway,v[1],
   30+v[0]*Math.sin(roll)+(v[2]-30)*Math.cos(roll)+drift]),c});}
 function plate(points,thick,c){
   // Each solid plate drifts as one piece, slightly out of phase with the core.
   const offset=phase+shellIndex++*.85;
   const side=Math.sign(points.reduce((sum,p)=>sum+p[0],0));
   const spread=Math.sin(offset)*(heavy?1.8:2.6);
   const centre=points.reduce((sum,p)=>sum.map((v,i)=>v+p[i]/points.length),[0,0,0]);
   const hinge=Math.sin(offset)*(heavy?.12:.2);
   points=points.map(p=>{
     const dx=p[0]-centre[0],dz=p[2]-centre[2];
     return [centre[0]+dx*Math.cos(hinge)-dz*Math.sin(hinge)+side*spread,
       p[1]+Math.sin(offset)*1.5,centre[2]+dx*Math.sin(hinge)+dz*Math.cos(hinge)+Math.cos(offset)*1.9];
   });
   const back=points.map(p=>[p[0],p[1]+thick,p[2]]);
   face(points,c);face(back,shade(c,.65));
   for(let i=0;i<points.length;i++)face([points[i],back[i],back[(i+1)%points.length],points[(i+1)%points.length]],shade(c,.76));
 }
 function crystal(x,y,z,w,depth,h,c,tilt=0){
   if(c===glow){
     const pulse=1+Math.cos(phase*2)*.22;w*=pulse;h*=pulse;
   }else if(w<=3){
     // Small fragments circle their resting positions, never the whole enemy.
     const orbit=phase+x*.13;
     x+=Math.sin(orbit)*2.8;y+=Math.cos(orbit)*2;z+=Math.cos(orbit)*2;
   }
   const belt=[[x-w,y,z],[x,y-depth,z+1],[x+w,y,z],[x,y+depth,z-1]],
     top=[x+tilt,y,h+z],bottom=[x-tilt*.4,y-.4,z-h*.8];
   for(let i=0;i<4;i++){
     face([belt[i],belt[(i+1)%4],top],shade(c,[.9,1,.58,.72][i]));
     face([belt[(i+1)%4],belt[i],bottom],shade(c,[.65,.76,.45,.55][i]));
   }
 }
 const glow=C.core.map(v=>Math.round(v*(.82+Math.cos(phase)*.25)));
 if(fast){
   // A small torn splinter: knife silhouette, an exposed dark seed and two fins.
   crystal(0,0,30,5,4,19,C.void,6);
   plate([[-9-breath,-4,24],[-3,-4,48],[4,-4,43],[-1,-4,29]],3,C.ivory);
   plate([[3,-3,26],[8+breath,-3,40],[13,-3,27],[1,-3,12]],2,C.slate);
   crystal(1,-5,31,2,1.4,5,glow,1);
   crystal(-7,2,18,2,1.5,6,C.edge,-2);
   crystal(4,0,7,1.4,1.3,2.5,C.dark);
 }else if(heavy){
   // A suspended broken monolith. Large stone plates enclose a vertical rift.
   crystal(0,1,31,13,8,23,C.void,-2);
   plate([[-18-breath,-6,29],[-14,-6,54],[-4,-6,59],[-5,-6,38],[-11,-6,22]],7,C.ivory);
   plate([[5,-7,55],[16+breath,-7,48],[19,-7,26],[10,-7,17],[5,-7,35]],8,C.slate);
   plate([[-10,-9,21],[-2,-9,28],[6,-9,23],[10,-9,12],[-3,-9,8]],4,C.ivory);
   plate([[-9,6,53],[8,6,58],[16,6,38],[3,6,28],[-12,6,32]],5,C.edge);
   crystal(0,-9,35,2.2,1.3,13,glow,-.7);
   crystal(-23,0,24,3,2.5,8,C.dark,-2);
   crystal(23,1,34,2.5,2,6,C.ivory,2);
   crystal(-7,0,4.5,1.6,1.6,2.3,C.slate);
 }else{
   // A hollow, fractured diamond shell. Its opening stays readable at game scale.
   crystal(0,1,31,7,5,14,C.void);
   plate([[-15-breath,-5,32],[-1,-5,54],[2,-5,44],[-7,-5,30]],4,C.ivory);
   plate([[3,-4,51],[16+breath,-4,33],[9,-4,27],[4,-4,39]],5,C.slate);
   plate([[15,-5,29],[1,-5,10],[-2,-5,20],[7,-5,34]],4,C.ivory);
   plate([[-4,-5,23],[-12,-5,34],[-16,-5,26],[-3,-5,13]],4,C.slate);
   crystal(0,-6,32,2.7,1.6,6,glow);
   crystal(-18,1,16,1.8,1.5,4,C.edge,-1);
   crystal(12,0,10,1.5,1.4,3,C.dark,1);
 }
 return faces;
}
module.exports={mesh};
