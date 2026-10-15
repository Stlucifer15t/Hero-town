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
		var expected_dimensions := Vector2i(9 * 8 + 1, 24 * 8 + 1)
		if dimensions != expected_dimensions:
			failure = "Large city map dimensions are incorrect: %s." % dimensions

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
		and (int(city.call("get_citizen_count")) <= 0 or int(city.call("get_car_count")) < 12)
	):
		failure = "Large city map did not spawn its citizens and vehicles."

	if failure.is_empty():
		var park_bounds: Rect2i = city.call("get_park_bounds")
		var park_tile_found: bool = false
		var road_tile_found: bool = false
		var water_tile_found: bool = false
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
		if not park_tile_found or not road_tile_found or not water_tile_found:
			failure = "Large city is missing its park, street grid, or surrounding water."

	var large_block_count: int = int(city.call("get_city_block_count")) if city != null else 0
	var mega_dimensions := Vector2i.ZERO
	if failure.is_empty():
		var mega_city: Node2D = CityGenerator.new()
		root.add_child(mega_city)
		mega_city.call("generate", 15102028, 3)
		await process_frame
		mega_dimensions = mega_city.call("get_map_dimensions")
		var mega_ground: TileMapLayer = mega_city.get_node_or_null("Ground") as TileMapLayer
		if mega_dimensions != Vector2i(11 * 8 + 1, 30 * 8 + 1):
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
		if small_dimensions != Vector2i(5 * 8 + 1, 12 * 8 + 1):
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
