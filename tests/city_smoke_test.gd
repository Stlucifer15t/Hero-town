extends SceneTree

const CityGenerator = preload("res://scripts/city/city_generator.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failure: String = ""
	var presets: Array[Dictionary] = CityGenerator.get_map_presets()
	if presets.size() != 4:
		failure = "Expected four selectable city map sizes."

	var city: Node2D
	var ground: TileMapLayer
	var dimensions := Vector2i.ZERO
	var actual_tile_count: int = 0
	var visual_neighborhood_bounds := Rect2i()
	if failure.is_empty():
		city = CityGenerator.new()
		root.add_child(city)
		city.call("generate", 15102026, 2)
		await process_frame
		ground = city.get_node_or_null("Ground") as TileMapLayer
		if ground == null:
			failure = "Generated city has no Ground TileMapLayer."

	if failure.is_empty():
		dimensions = city.call("get_map_dimensions")
		var expected_dimensions := Vector2i(12 * 8 + 1, 18 * 8 + 1)
		if dimensions != expected_dimensions:
			failure = "Large city map dimensions are incorrect: %s." % dimensions
		visual_neighborhood_bounds = city.call("get_visual_neighborhood_bounds")
		if failure.is_empty() and visual_neighborhood_bounds.size != Vector2i(56, 64):
			failure = "The rich visual treatment is not scoped to one 7 × 8-block neighborhood."

	if failure.is_empty():
		var expected_tile_count: int = (dimensions.x + 4) * (dimensions.y + 4)
		actual_tile_count = ground.get_used_cells().size()
		if actual_tile_count != expected_tile_count:
			failure = (
				"Large city tile count is incorrect: expected %d, got %d."
				% [expected_tile_count, actual_tile_count]
			)

	if failure.is_empty() and int(city.call("get_city_block_count")) < 50:
		failure = "Large city map did not generate enough buildable city blocks."
	if (
		failure.is_empty()
		and (
			int(city.call("get_citizen_count")) <= 0
			or int(city.call("get_citizen_count")) > 128
			or int(city.call("get_car_count")) < 12
			or int(city.call("get_car_count")) > 24
		)
	):
		failure = "Large city actor counts are outside the mobile-safe budget."

	if failure.is_empty():
		var static_props: Node = city.get_node_or_null("StaticProps")
		if static_props == null:
			failure = "Generated city has no consolidated static-props renderer."
		elif static_props.call("get_building_atlas_size") != Vector2i(896, 224):
			failure = "Generated city is missing its shared building sprite atlas."
		else:
			var building_render_counts: Vector2i = static_props.call("get_building_render_counts")
			if building_render_counts.x <= 0 or building_render_counts.y <= 0:
				failure = "Neighborhood sprite buildings were not kept inside a limited city slice."

	if failure.is_empty():
		var population: Node = city.get_node_or_null("Population")
		var large_walker_found: bool = false
		var original_walker_found: bool = false
		if population != null:
			for citizen: Node in population.get_children():
				var character_scale: float = citizen.call("get_character_scale")
				if is_equal_approx(character_scale, 1.55):
					large_walker_found = true
				elif is_equal_approx(character_scale, 1.0):
					original_walker_found = true
		if not large_walker_found or not original_walker_found:
			failure = "Larger walkers were not localized to the neighborhood prototype."

	if failure.is_empty():
		var park_bounds: Rect2i = city.call("get_park_bounds")
		var park_tile_found: bool = false
		var road_tile_found: bool = false
		var water_tile_found: bool = false
		var arterial_tile_found: bool = false
		var dock_tile_found: bool = false
		var grass_variant_found: bool = false
		var park_variant_found: bool = false
		var water_variant_found: bool = false
		var sidewalk_variant_found: bool = false
		var outside_variant_found: bool = false
		for y: int in range(park_bounds.position.y, park_bounds.position.y + park_bounds.size.y):
			for x: int in range(
				park_bounds.position.x, park_bounds.position.x + park_bounds.size.x
			):
				if ground.get_cell_atlas_coords(Vector2i(x, y)).x == CityGenerator.TILE_PARK:
					park_tile_found = true
		for cell: Vector2i in ground.get_used_cells():
			var tile_id: int = ground.get_cell_atlas_coords(cell).x
			if (
				tile_id == CityGenerator.TILE_INTERSECTION
				or tile_id == CityGenerator.TILE_AVENUE_INTERSECTION
			):
				road_tile_found = true
			if tile_id == CityGenerator.TILE_WATER:
				water_tile_found = true
			if tile_id == CityGenerator.TILE_ARTERIAL:
				arterial_tile_found = true
			if tile_id == CityGenerator.TILE_DOCK:
				dock_tile_found = true
			var is_visual_neighborhood_cell: bool = visual_neighborhood_bounds.has_point(cell)
			if tile_id == CityGenerator.TILE_GRASS_VARIANT:
				grass_variant_found = grass_variant_found or is_visual_neighborhood_cell
				outside_variant_found = outside_variant_found or not is_visual_neighborhood_cell
			if tile_id == CityGenerator.TILE_PARK_VARIANT:
				park_variant_found = park_variant_found or is_visual_neighborhood_cell
				outside_variant_found = outside_variant_found or not is_visual_neighborhood_cell
			if tile_id == CityGenerator.TILE_WATER_VARIANT:
				water_variant_found = water_variant_found or is_visual_neighborhood_cell
				outside_variant_found = outside_variant_found or not is_visual_neighborhood_cell
			if tile_id == CityGenerator.TILE_SIDEWALK_VARIANT:
				sidewalk_variant_found = sidewalk_variant_found or is_visual_neighborhood_cell
				outside_variant_found = outside_variant_found or not is_visual_neighborhood_cell
		if (
			not park_tile_found
			or not road_tile_found
			or not water_tile_found
			or not arterial_tile_found
			or not dock_tile_found
			or not grass_variant_found
			or not park_variant_found
			or not water_variant_found
			or not sidewalk_variant_found
			or outside_variant_found
		):
			failure = "Ground textures escaped the neighborhood slice or city districts are missing."

	var large_block_count: int = int(city.call("get_city_block_count")) if city != null else 0
	var mega_dimensions := Vector2i.ZERO
	if failure.is_empty():
		var mega_city: Node2D = CityGenerator.new()
		root.add_child(mega_city)
		mega_city.call("generate", 15102028, 3)
		await process_frame
		mega_dimensions = mega_city.call("get_map_dimensions")
		var mega_ground: TileMapLayer = mega_city.get_node_or_null("Ground") as TileMapLayer
		if mega_dimensions != Vector2i(16 * 8 + 1, 24 * 8 + 1):
			failure = "The largest selectable map size is incorrect."
		elif (
			mega_ground == null
			or (
				mega_ground.get_used_cells().size()
				!= ((mega_dimensions.x + 4) * (mega_dimensions.y + 4))
			)
		):
			failure = "The largest selectable map did not fully generate its coastline and tiles."
		elif int(mega_city.call("get_city_block_count")) <= large_block_count:
			failure = "The largest map did not generate more city blocks than the large map."

	var small_dimensions := Vector2i.ZERO
	if failure.is_empty():
		var small_city: Node2D = CityGenerator.new()
		root.add_child(small_city)
		small_city.call("generate", 15102027, 0)
		await process_frame
		small_dimensions = small_city.call("get_map_dimensions")
		if small_dimensions != Vector2i(6 * 8 + 1, 8 * 8 + 1):
			failure = "The smallest selectable map size is incorrect."
		elif int(small_city.call("get_city_block_count")) <= 0:
			failure = "The smallest selectable map generated no city blocks."

	if not failure.is_empty():
		push_error("City smoke test failed: " + failure)
		quit(1)
		return

	print(
		(
			(
				"City smoke test passed: %d large-map tiles, %d city blocks, "
				+ "%d citizens, %d vehicles; small map %d × %d tiles."
			)
			% [
				actual_tile_count,
				city.call("get_city_block_count"),
				city.call("get_citizen_count"),
				city.call("get_car_count"),
				small_dimensions.x,
				small_dimensions.y,
			]
		)
	)
	quit(0)
