extends SceneTree

const CityGenerator = preload("res://scripts/city/city_generator.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var city: Node2D = CityGenerator.new()
	root.add_child(city)
	city.call("generate", 15102026)
	await process_frame

	var ground: TileMapLayer = city.get_node_or_null("Ground") as TileMapLayer
	if ground == null:
		push_error("City smoke test failed: generated city has no Ground TileMapLayer.")
		quit(1)
		return

	if ground.get_used_cells().size() != 33 * 33:
		push_error("City smoke test failed: generated tile count is incorrect.")
		quit(1)
		return

	if int(city.call("get_citizen_count")) <= 0 or int(city.call("get_car_count")) <= 0:
		push_error("City smoke test failed: no citizens or cars were spawned.")
		quit(1)
		return

	print(
		(
			"City smoke test passed: %d tiles, %d citizens, %d cars."
			% [
				ground.get_used_cells().size(),
				city.call("get_citizen_count"),
				city.call("get_car_count")
			]
		)
	)
	quit(0)
