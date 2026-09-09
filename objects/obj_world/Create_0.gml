window_set_caption("Antithesis");
// Own the background at runtime so an editor-saved room layer cannot cover the path.
var background_layer=layer_get_id("Background");
if (background_layer!=-1) layer_set_visible(background_layer,false);
depth=50;
draw_set_circle_precision(48);
elapsed=0;
route = [[0,3],[1,3],[2,3],[3,3],[3,4],[3,5],[4,5],[5,5],[6,5],[6,4],[6,3],[6,2],[7,2],[8,2]];

// The realm has resolved into broad, connected strata. The hard angles are
// natural laws becoming visible, not masonry or manufactured panels.
land_shelves=[
    [-1.0,-0.8,9.0,6.8,44],
    [-1.72,1.15,0.3,5.25,58],
    [2.35,-1.48,6.35,0.35,67],
    [7.75,0.95,9.72,4.75,54],
    [2.05,5.65,6.85,7.55,72]
];
// A genuine absence in the terrain. Placement validation uses the same data.
void_regions=[[4.05,0.55,5.35,2.3]];

// Coherent cliff families frame the play space. Each root is one uninterrupted
// mass; the cluster silhouette matters more than surface detail.
var formations=[[-1.42,-0.18,0.86,148,0.2],[-0.72,-0.52,0.66,112,1.1],
    [-1.72,0.78,0.76,126,2.0],[-1.38,1.62,0.6,82,2.7],
    [5.62,-1.36,0.8,154,0.7],[6.42,-1.22,0.72,132,1.6],
    [7.18,-1.02,0.62,104,2.5],[8.05,-0.72,0.52,82,3.4],
    [9.18,0.15,0.66,108,4.1],[9.48,1.08,0.52,76,5.0]];
for(var i=0;i<array_length(formations);++i) {
    var p=formations[i];
    instance_create_depth(project_x(p[0],p[1]),project_y(p[0],p[1]),-project_y(p[0],p[1]),obj_terrain,
        {world_x:p[0],world_y:p[1],radius:p[2],elevation:p[3],shape_phase:p[4],terrain_style:"null_pillar"});
}

// Each point is physical world x/y/z. Connections race between them, hold as a
// constellation, then dissolve before a different region wakes up.
sky_constellations=[
    [[-1.3,-0.1,144],[-0.35,0.32,208],[0.62,-0.18,176],[1.62,0.28,230],[0.18,1.02,190]],
    [[5.82,-0.94,186],[6.78,-0.38,244],[7.72,-0.82,212],[8.82,-0.26,258],[7.35,0.42,196]],
    [[6.82,5.42,154],[7.52,6.04,218],[8.42,5.58,184],[9.02,6.36,232],[8.08,6.82,202]]
];
sky_constellation_links=[
    [[0,1],[1,2],[2,3],[1,4],[4,2]],
    [[0,1],[1,2],[2,3],[1,4],[4,3]],
    [[0,1],[1,2],[2,3],[1,4],[4,3]]
];


