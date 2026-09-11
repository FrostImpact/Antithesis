const fs=require('node:fs'),assert=require('node:assert/strict');
const s={obj_world:{land_shelves:[[0,0,2,2],[2,0,4,2]],void_regions:[]},obj_game:{},instance_exists:()=>true,
 min:Math.min,max:Math.max,array_length:a=>a.length,array_push:(a,v)=>a.push(v),lerp:(a,b,t)=>a+(b-a)*t};
const api=new Function('s',`with(s){${fs.readFileSync('scripts/scr_map/scr_map.gml','utf8').replace(/\bmod\b/g,'%')};return {valid:map_point_on_surface,clip:map_clip_polygon};}`)(s);
assert.equal(api.valid(2,1,.34),true,'Adjacent shelves share a continuous placement surface');
assert.equal(api.valid(.2,1,.34),false,'Footprint cannot overhang the map edge');
s.obj_world.land_shelves[1][0]=2.05;assert.equal(api.valid(2,1,.34),false,'Small gaps remain non-placeable');
s.obj_world.land_shelves=[[0,0,8,8]];s.obj_world.void_regions=[[3,3,4,4]];
assert.equal(api.valid(3.5,3.5,.34),false);assert.equal(api.valid(2.6,3.5,.34),false,'The visible pit rim blocks placement');
assert.equal(api.valid(2.5,3.5,.34),true);
for(const zoom of [.72,1,1.28])for(const width of [20,50,100]){
 const hole=[[0,-width*zoom],[2*width*zoom,0],[0,width*zoom],[-2*width*zoom,0]];
 for(let i=0;i<2;i++){
  const a=hole[i],b=hole[i+1];const wall=[a,b,[b[0],b[1]+90*zoom],[a[0],a[1]+90*zoom]];
  const clipped=api.clip(wall,hole);assert.ok(clipped.length>=3);
  for(const p of clipped)for(let edge=0;edge<4;edge++){
   const c=hole[edge],d=hole[(edge+1)%4];
   assert.ok((d[0]-c[0])*(p[1]-c[1])-(d[1]-c[1])*(p[0]-c[0])>=-1e-8,'Every wall vertex stays inside the pit aperture');
  }
 }
}
assert.deepEqual(api.clip([[30,30],[40,30],[40,40]],[[0,0],[10,0],[10,10],[0,10]]),[]);
console.log('PASS: shelf joins, map edges, narrow gaps, pit collision/rim clearance and clipped walls at all zoom levels.');
