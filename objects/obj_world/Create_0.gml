window_set_caption("Antithesis");
// Own the background at runtime so an editor-saved room layer cannot cover the path.
var background_layer=layer_get_id("Background");
if (background_layer!=-1) layer_set_visible(background_layer,false);
depth=50;
draw_set_circle_precision(48);
elapsed=0;
// These arrays come from marker instances placed directly in Room1. Route node
// image indices define travel order; surface/void scales define their extents.
route=map_collect_route();
land_shelves=map_collect_regions(obj_map_surface,MapRegionKind.Surface);
void_regions=map_collect_regions(obj_map_void,MapRegionKind.Void);
map_spawn_terrain();

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


