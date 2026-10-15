extends RefCounted


static func roll_count(rng: RandomNumberGenerator, in_visual_neighborhood: bool) -> int:
	return rng.randi_range(2, 4) if in_visual_neighborhood else rng.randi_range(3, 5)


static func roll_footprint(rng: RandomNumberGenerator, in_visual_neighborhood: bool) -> Vector2:
	if in_visual_neighborhood:
		return Vector2(rng.randf_range(46.0, 68.0), rng.randf_range(30.0, 48.0))
	return Vector2(rng.randf_range(35.0, 56.0), rng.randf_range(24.0, 38.0))


static func roll_height(
	rng: RandomNumberGenerator, in_visual_neighborhood: bool, is_skyline: bool, building_index: int
) -> float:
	var height: float
	if in_visual_neighborhood:
		height = rng.randf_range(64.0, 118.0)
		if not is_skyline and rng.randf() < 0.36:
			height = rng.randf_range(43.0, 71.0)
		elif is_skyline and building_index == 0:
			height = rng.randf_range(154.0, 226.0)
		elif is_skyline and rng.randf() < 0.36:
			height = rng.randf_range(122.0, 168.0)
		elif rng.randf() < 0.12:
			height = rng.randf_range(120.0, 152.0)
	else:
		height = rng.randf_range(43.0, 105.0)
		if is_skyline and building_index == 0:
			height = rng.randf_range(126.0, 226.0)
		elif is_skyline and rng.randf() < 0.33:
			height = rng.randf_range(94.0, 156.0)
		elif rng.randf() < 0.15:
			height = rng.randf_range(78.0, 132.0)
	return height
