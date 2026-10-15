extends Node2D

## Builds the placeholder isometric map, block props, pedestrians, and traffic.
const CityPropsRenderer = preload("res://scripts/city/city_props_renderer.gd")
const CityCitizen = preload("res://scripts/city/city_citizen.gd")
const CityCar = preload("res://scripts/city/city_car.gd")

const TILE_SIZE: int = 64
const MAP_SIZE: int = 33
const ROAD_SPACING: int = 8

const TILE_GRASS: int = 0
const TILE_SIDEWALK: int = 1
const TILE_ROAD_X: int = 2
const TILE_ROAD_Y: int = 3
const TILE_INTERSECTION: int = 4
const TILE_COUNT: int = 5

const CAR_COUNT: int = 7

var _rng := RandomNumberGenerator.new()
var _ground: TileMapLayer
var _props: Node2D
var _population: Node2D
var _traffic: Node2D
var _generated: bool = false
var _citizen_count: int = 0
var _car_count: int = 0


func generate(seed_value: int) -> void:
	if _generated:
		return
	_generated = true
	_rng.seed = seed_value

	_build_ground()
	_build_city_blocks()
	_build_citizens()
	_build_cars()


func get_map_center() -> Vector2:
	if _ground == null:
		return Vector2.ZERO
	return _cell_to_world(Vector2i(MAP_SIZE / 2, MAP_SIZE / 2))


func get_citizen_count() -> int:
	return _citizen_count


func get_car_count() -> int:
	return _car_count


func _build_ground() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tile_set.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN

	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(_make_tile_atlas())
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for tile_index: int in range(TILE_COUNT):
		atlas.create_tile(Vector2i(tile_index, 0))
	tile_set.add_source(atlas, 0)

	_ground = TileMapLayer.new()
	_ground.name = "Ground"
	_ground.tile_set = tile_set
	_ground.z_index = -10
	_ground.scale = Vector2(1.0, 0.5)
	_ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_ground)

	for y: int in range(MAP_SIZE):
		for x: int in range(MAP_SIZE):
			var cell := Vector2i(x, y)
			_ground.set_cell(cell, 0, Vector2i(_tile_for_cell(x, y), 0))

	_props = CityPropsRenderer.new()
	_props.name = "StaticProps"
	_props.z_index = -2
	add_child(_props)


func _make_tile_atlas() -> Image:
	var image := Image.create(TILE_SIZE * TILE_COUNT, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	_paint_iso_tile(image, TILE_GRASS, Color("#3a795d"), Color("#244c49"), 0)
	_paint_iso_tile(image, TILE_SIDEWALK, Color("#9a9b83"), Color("#46565a"), 1)
	_paint_iso_tile(image, TILE_ROAD_X, Color("#35434d"), Color("#202f3b"), 2)
	_paint_iso_tile(image, TILE_ROAD_Y, Color("#35434d"), Color("#202f3b"), 3)
	_paint_iso_tile(image, TILE_INTERSECTION, Color("#3c4b54"), Color("#202f3b"), 4)
	return image


func _paint_iso_tile(
	image: Image, tile_index: int, base_color: Color, edge_color: Color, detail_kind: int
) -> void:
	var offset_x: int = tile_index * TILE_SIZE
	for y: int in range(TILE_SIZE):
		var half_width: int = int(floor(32.0 - absf(float(y) - 31.5)))
		var left: int = maxi(0, 32 - half_width)
		var right_exclusive: int = mini(TILE_SIZE, 33 + half_width)
		for x: int in range(left, right_exclusive):
			var edge_distance: int = mini(
				mini(x - left, right_exclusive - 1 - x), mini(y, TILE_SIZE - 1 - y)
			)
			var color: Color = base_color
			if edge_distance <= 1:
				color = edge_color
			elif detail_kind == 0:
				var fleck: int = (x * 19 + y * 13 + tile_index * 7) % 101
				if fleck == 0:
					color = base_color.lightened(0.25)
				elif fleck == 1:
					color = base_color.darkened(0.20)
				elif (x + y * 2) % 37 == 0:
					color = Color("#75a76b")
				elif (x * 3 + y) % 53 == 0:
					color = Color("#2e684f")
			elif detail_kind == 1 and (x % 16 == 0 or y % 16 == 0):
				color = base_color.lightened(0.08)
			image.set_pixel(offset_x + x, y, color)

	if detail_kind == 2:
		_paint_road_dash(image, offset_x, 1)
	elif detail_kind == 3:
		_paint_road_dash(image, offset_x, -1)
	elif detail_kind == 4:
		_paint_road_dash(image, offset_x, 1)
		_paint_road_dash(image, offset_x, -1)
		for stripe: int in range(-2, 3):
			for mark: int in range(0, 4):
				_set_atlas_pixel(image, offset_x + 32 + stripe * 3 + mark, 23, Color("#b8b59a"))


func _paint_road_dash(image: Image, offset_x: int, slope: int) -> void:
	for step: int in range(-5, 6):
		var px: int = offset_x + 32 + step
		var py: int = 32 + step * slope
		for thickness: int in range(-1, 2):
			var x: int = px + thickness
			var y: int = py + thickness * slope
			_set_atlas_pixel(image, x, y, Color("#d9cb88"))


func _set_atlas_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < image.get_width() and y >= 0 and y < TILE_SIZE:
		image.set_pixel(x, y, color)


func _tile_for_cell(x: int, y: int) -> int:
	var road_x: bool = x % ROAD_SPACING == 0
	var road_y: bool = y % ROAD_SPACING == 0
	if road_x and road_y:
		return TILE_INTERSECTION
	if road_x:
		return TILE_ROAD_Y
	if road_y:
		return TILE_ROAD_X
	if x % ROAD_SPACING == 1 or x % ROAD_SPACING == ROAD_SPACING - 1:
		return TILE_SIDEWALK
	if y % ROAD_SPACING == 1 or y % ROAD_SPACING == ROAD_SPACING - 1:
		return TILE_SIDEWALK
	return TILE_GRASS


func _build_city_blocks() -> void:
	var wall_palette: Array[Color] = [
		Color("#c58469"),
		Color("#baaa83"),
		Color("#69959a"),
		Color("#9c789a"),
		Color("#c4c5b1"),
		Color("#7b92a0")
	]
	var roof_palette: Array[Color] = [
		Color("#df9a69"),
		Color("#d7c691"),
		Color("#78b7aa"),
		Color("#be8ab1"),
		Color("#e0d8bb"),
		Color("#88a9ba")
	]
	var tree_palette: Array[Color] = [
		Color("#408b60"), Color("#5a9d63"), Color("#62965d"), Color("#398071")
	]

	for block_y: int in range(0, MAP_SIZE - 1, ROAD_SPACING):
		for block_x: int in range(0, MAP_SIZE - 1, ROAD_SPACING):
			var min_x: int = block_x + 2
			var max_x: int = mini(block_x + ROAD_SPACING - 2, MAP_SIZE - 2)
			var min_y: int = block_y + 2
			var max_y: int = mini(block_y + ROAD_SPACING - 2, MAP_SIZE - 2)
			var occupied: Array[Vector2i] = []
			var building_count: int = 2 if _rng.randf() < 0.78 else 3

			for building_index: int in range(building_count):
				var cell: Vector2i = _pick_free_cell(min_x, max_x, min_y, max_y, occupied, 2.3)
				if cell.x < 0:
					continue
				occupied.append(cell)

				var palette_index: int = _rng.randi_range(0, wall_palette.size() - 1)
				var center_distance: float = (
					Vector2(cell.x - MAP_SIZE * 0.5, cell.y - MAP_SIZE * 0.5).length()
				)
				var building_height: float = _rng.randf_range(47.0, 105.0)
				if center_distance < 6.0 and building_index == 0:
					building_height = _rng.randf_range(122.0, 176.0)
				_props.call(
					"add_building",
					_cell_to_world(cell),
					_rng.randf_range(38.0, 55.0),
					_rng.randf_range(25.0, 37.0),
					building_height,
					wall_palette[palette_index],
					roof_palette[palette_index],
					_rng.randi_range(0, 2),
					_rng.randi()
				)

			var tree_count: int = _rng.randi_range(1, 2)
			for _tree_index: int in range(tree_count):
				var tree_cell: Vector2i = _pick_free_cell(min_x, max_x, min_y, max_y, occupied, 1.8)
				if tree_cell.x < 0:
					continue
				occupied.append(tree_cell)
				var tree_color: Color = tree_palette[_rng.randi_range(0, tree_palette.size() - 1)]
				_props.call(
					"add_tree", _cell_to_world(tree_cell), tree_color, _rng.randf_range(27.0, 37.0)
				)


func _pick_free_cell(
	min_x: int,
	max_x: int,
	min_y: int,
	max_y: int,
	occupied: Array[Vector2i],
	minimum_distance: float
) -> Vector2i:
	if min_x > max_x or min_y > max_y:
		return Vector2i(-1, -1)

	for _attempt: int in range(48):
		var candidate := Vector2i(_rng.randi_range(min_x, max_x), _rng.randi_range(min_y, max_y))
		var is_free: bool = true
		for taken: Vector2i in occupied:
			var grid_distance: float = Vector2(candidate - taken).length()
			if grid_distance < minimum_distance:
				is_free = false
				break
		if is_free:
			return candidate
	return Vector2i(-1, -1)


func _build_citizens() -> void:
	_population = Node2D.new()
	_population.name = "Population"
	_population.z_index = 2
	add_child(_population)

	var shirt_colors: Array[Color] = [
		Color("#e77d64"),
		Color("#52b7a3"),
		Color("#d7ad53"),
		Color("#777fd0"),
		Color("#e18bab"),
		Color("#d7ded0")
	]
	var trouser_colors: Array[Color] = [
		Color("#26394f"), Color("#39434e"), Color("#55435b"), Color("#47584c")
	]
	var sidewalk_routes: Array[PackedVector2Array] = []

	for block_y: int in range(0, MAP_SIZE - 1, ROAD_SPACING):
		for block_x: int in range(0, MAP_SIZE - 1, ROAD_SPACING):
			sidewalk_routes.append(_make_block_sidewalk_route(block_x, block_y))

	for route_index: int in range(sidewalk_routes.size()):
		var pedestrians_in_block: int = 1 if _rng.randf() < 0.65 else 2
		for pedestrian_index: int in range(pedestrians_in_block):
			var citizen: Node2D = CityCitizen.new()
			citizen.name = "Citizen_%02d" % _citizen_count
			citizen.call(
				"configure",
				sidewalk_routes[route_index],
				_rng.randf_range(38.0, 57.0),
				shirt_colors[_rng.randi_range(0, shirt_colors.size() - 1)],
				trouser_colors[_rng.randi_range(0, trouser_colors.size() - 1)],
				Color("#f0b88d") if _rng.randf() < 0.68 else Color("#9c654e"),
				Color("#382c35") if _rng.randf() < 0.78 else Color("#c88a52"),
				_rng.randf_range(0.0, _route_length(sidewalk_routes[route_index]))
			)
			_population.add_child(citizen)
			_citizen_count += 1


func _make_block_sidewalk_route(block_x: int, block_y: int) -> PackedVector2Array:
	var left: int = block_x + 1
	var right: int = mini(block_x + ROAD_SPACING - 1, MAP_SIZE - 2)
	var top: int = block_y + 1
	var bottom: int = mini(block_y + ROAD_SPACING - 1, MAP_SIZE - 2)
	var cells: Array[Vector2i] = []

	for x: int in range(left, right + 1):
		cells.append(Vector2i(x, top))
	for y: int in range(top + 1, bottom + 1):
		cells.append(Vector2i(right, y))
	for x: int in range(right - 1, left - 1, -1):
		cells.append(Vector2i(x, bottom))
	for y: int in range(bottom - 1, top, -1):
		cells.append(Vector2i(left, y))

	var route := PackedVector2Array()
	for cell: Vector2i in cells:
		route.append(_cell_to_world(cell))
	return route


func _build_cars() -> void:
	_traffic = Node2D.new()
	_traffic.name = "Traffic"
	_traffic.z_index = 4
	add_child(_traffic)

	var route: PackedVector2Array = _make_car_route()
	var car_colors: Array[Color] = [
		Color("#e7655b"),
		Color("#50a7a3"),
		Color("#e5b54d"),
		Color("#8089d4"),
		Color("#e6e1cc"),
		Color("#5b7189"),
		Color("#d67f9d")
	]
	var roof_colors: Array[Color] = [
		Color("#f2d590"),
		Color("#bde3dc"),
		Color("#f2e1a2"),
		Color("#d2d5f3"),
		Color("#9cb6bf"),
		Color("#b9c7d0"),
		Color("#f0c0cf")
	]
	var total_route_length: float = _route_length(route)

	for car_index: int in range(CAR_COUNT):
		var car: Node2D = CityCar.new()
		car.name = "Car_%02d" % car_index
		var lane_offset: float = -7.0 if car_index % 2 == 0 else 7.0
		car.call(
			"configure",
			route,
			_rng.randf_range(132.0, 178.0),
			lane_offset,
			car_colors[car_index % car_colors.size()],
			roof_colors[car_index % roof_colors.size()],
			total_route_length * float(car_index) / float(CAR_COUNT) + _rng.randf_range(0.0, 55.0)
		)
		_traffic.add_child(car)
		_car_count += 1


func _make_car_route() -> PackedVector2Array:
	var route := PackedVector2Array()
	var min_road: int = ROAD_SPACING
	var max_road: int = MAP_SIZE - ROAD_SPACING - 1

	for x: int in range(min_road, max_road + 1):
		route.append(_cell_to_world(Vector2i(x, min_road)))
	for y: int in range(min_road + 1, max_road + 1):
		route.append(_cell_to_world(Vector2i(max_road, y)))
	for x: int in range(max_road - 1, min_road - 1, -1):
		route.append(_cell_to_world(Vector2i(x, max_road)))
	for y: int in range(max_road - 1, min_road, -1):
		route.append(_cell_to_world(Vector2i(min_road, y)))
	return route


func _route_length(route: PackedVector2Array) -> float:
	if route.size() < 2:
		return 0.0
	var total: float = 0.0
	for index: int in range(route.size()):
		total += route[index].distance_to(route[(index + 1) % route.size()])
	return total


func _cell_to_world(cell: Vector2i) -> Vector2:
	var tile_position: Vector2 = _ground.map_to_local(cell)
	return Vector2(tile_position.x, tile_position.y * _ground.scale.y)
