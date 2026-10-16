# City art atlas

`city_building_atlas.png` is an original, project-specific pixel-art atlas created for Hero Town. Its AI-generated draft sprites were curated, background-masked, cropped, and packed into four transparent 224 × 224 atlas cells: townhouse, corner shop, apartment block, and mid-rise. It is not extracted from TheoTown and does not contain TheoTown textures or save data.

The runtime renders generic city buildings from this shared atlas; the Hero Association is a distinct, procedurally drawn landmark with its own crest and rooftop pennant. Ground tiles remain in the procedural TileMap atlas, now with whole-city grass, paving, water, and road texture variants. Player heroes and training targets are drawn from original runtime geometry, with suit palettes and power-specific trails, bursts, elemental bolts, and transformation cues. Keep atlas textures filtered with nearest-neighbor sampling for the pixel-art look.
