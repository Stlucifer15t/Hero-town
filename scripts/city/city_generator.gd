extends Node2D

## Generates an original isometric island city inspired by TheoTown's Secaton community map.
const CityPropsRenderer = preload("res://scripts/city/city_props_renderer.gd")
const CityBuildingProfile = preload("res://scripts/city/city_building_profile.gd")
const CityCitizen = preload("res://scripts/city/city_citizen.gd")
const CityCar = preload("res://scripts/city/city_car.gd")

const TILE_SIZE: int = 64
const ROAD_SPACING: int = 8
const AVENUE_SPACING: int = ROAD_SPACING * 3
const CROSS_STREET_SPACING: int = ROAD_SPACING * 5

const MAP_PRESETS: Array[Dictionary] = [
	{
		"name": "District",
		"blocks_wide": 6,
		"blocks_long": 8,
		"description": "A compact island district to explore.",
	},
	{
		"name": "Borough",
		"blocks_wide": 9,
		"blocks_long": 12,
		"description": "A growing coastal town with several neighborhoods.",
	},
	{
		"name": "Large City",
		"blocks_wide": 12,
		"blocks_long": 18,
		"description": "A broad island city with a busy center and harbor.",
	},
	{
		"name": "Megacity",
		"blocks_wide": 16,
		"blocks_long": 24,
		"description": "The largest phone-friendly map, with room to expand.",
	},
]

const TILE_GRASS: int = 0
const TILE_SIDEWALK: int = 1
const TILE_ROAD_X: int = 2
const TILE_ROAD_Y: int = 3
const TILE_INTERSECTION: int = 4
const TILE_WATER: int = 5
const TILE_PARK: int = 6
const TILE_PARK_PATH: int = 7
const TILE_PROMENADE: int = 8
const TILE_AVENUE_X: int = 9
const TILE_AVENUE_Y: int = 10
const TILE_AVENUE_INTERSECTION: int = 11
const TILE_ARTERIAL: int = 12
const TILE_BRIDGE: int = 13
const TILE_DOCK: int = 14
const TILE_GRASS_VARIANT: int = 15
const TILE_PARK_VARIANT: int = 16
const TILE_WATER_VARIANT: int = 17
const TILE_SIDEWALK_VARIANT: int = 18
const TILE_COUNT: int = 19

var _rng := RandomNumberGenerator.new()
var _ground: TileMapLayer
var _props: Node2D
var _population: Node2D
var _traffic: Node2D
var _generated: bool = false
var _city_block_count: int = 0
var _citizen_count: int = 0
var _car_count: int = 0
var _size_index: int = 2
var _blocks_wide: int = 12
var _blocks_long: int = 18
var _map_width: int = 97
var _map_height: int = 145
var _visual_neighborhood_rect: Rect2i = Rect2i()
var _coast_left: Array[int] = []
var _coast_right: Array[int] = []
var _park_rect: Rect2i = Rect2i()
var _lake_rect: Rect2i = Rect2i()
var _city_blocks: Array[Vector2i] = []


static func get_map_presets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for preset: Dictionary in MAP_PRESETS:
		result.append(preset.duplicate(true))
	return result


static func get_map_preset(preset_index: int) -> Dictionary:
	var index: int = clampi(preset_index, 0, MAP_PRESETS.size() - 1)
	return MAP_PRESETS[index].duplicate(true)


func generate(seed_value: int, preset_index: int = 2) -> void:
	if _generated:
		return
	_generated = true
	_size_index = clampi(preset_index, 0, MAP_PRESETS.size() - 1)
	var preset: Dictionary = get_map_preset(_size_index)
	_blocks_wide = int(preset["blocks_wide"])
	_blocks_long = int(preset["blocks_long"])
	_map_width = _blocks_wide * ROAD_SPACING + 1
	_map_height = _blocks_long * ROAD_SPACING + 1
	var neighborhood_size := Vector2i(
		mini(_blocks_wide, 7) * ROAD_SPACING, mini(_blocks_long, 8) * ROAD_SPACING
	)
	var neighborhood_origin := Vector2i(
		int((_map_width - neighborhood_size.x) / 2), int((_map_height - neighborhood_size.y) / 2)
	)
	_visual_neighborhood_rect = Rect2i(neighborhood_origin, neighborhood_size)
	_rng.seed = seed_value

	_build_coastline()
	_build_park_layout()
	_build_ground()
	_build_city_blocks()
	_build_park_details()
	_build_harbor_details()
	_build_citizens()
	_build_cars()


func get_map_center() -> Vector2:
	if _ground == null:
		return Vector2.ZERO
	return _cell_to_world(Vector2i(_map_width / 2, _map_height / 2))


func get_map_dimensions() -> Vector2i:
	return Vector2i(_map_width, _map_height)


func get_map_block_dimensions() -> Vector2i:
	return Vector2i(_blocks_wide, _blocks_long)


func get_map_preset_index() -> int:
	return _size_index


func get_map_size_name() -> String:
	return str(MAP_PRESETS[_size_index]["name"])


func get_map_description() -> String:
	return str(MAP_PRESETS[_size_index]["description"])


func get_city_block_count() -> int:
	return _city_block_count


func get_citizen_count() -> int:
	return _citizen_count


func get_visual_neighborhood_bounds() -> Rect2i:
	return _visual_neighborhood_rect


func get_car_count() -> int:
	return _car_count


func get_park_bounds() -> Rect2i:
	return _park_rect


func get_park_center_cell() -> Vector2i:
	return _park_rect.position + _park_rect.size / 2


func _build_coastline() -> void:
	_coast_left.clear()
	_coast_right.clear()
	for y: int in range(_map_height):
		var t: float = float(y) / float(maxi(1, _map_height - 1))
		var end_taper: float = pow(maxf(sin(t * PI), 0.0), 0.72)
		var width_factor: float = 0.46 + 0.54 * end_taper
		var center_shift: float = sin(t * TAU * 0.92 + 0.4) * float(_map_width) * 0.065
		var coast_wave: float = (
			sin(t * TAU * 3.4 + 0.7) * float(_map_width) * 0.022
			+ sin(t * TAU * 7.8 + 1.8) * float(_map_width) * 0.012
		)
		var west_bay: float = exp(-pow((t - 0.29) / 0.072, 2.0)) * float(_map_width) * 0.16
		var east_bay: float = exp(-pow((t - 0.68) / 0.061, 2.0)) * float(_map_width) * 0.19
		var center_x: float = float(_map_width) * 0.5 + center_shift
		var half_width: float = float(_map_width) * width_factor * 0.5
		var left_edge: int = int(floor(center_x - half_width + coast_wave + west_bay))
		var right_edge: int = int(ceil(center_x + half_width + coast_wave - east_bay))
		_coast_left.append(clampi(left_edge, 0, _map_width - 1))
		_coast_right.append(clampi(right_edge, 0, _map_width - 1))


func _build_park_layout() -> void:
	var park_blocks_wide: int = clampi(int(roundf(float(_blocks_wide) * 0.22)), 1, _blocks_wide - 2)
	var park_blocks_long: int = clampi(int(roundf(float(_blocks_long) * 0.19)), 2, _blocks_long - 4)
	var park_center_x: float = float(_blocks_wide) * 0.58
	var park_block_x: int = int(roundf(park_center_x - float(park_blocks_wide) * 0.5))
	var park_block_y: int = int(roundf(float(_blocks_long) * 0.47 - float(park_blocks_long) * 0.5))
	park_block_y = clampi(park_block_y, 1, _blocks_long - park_blocks_long - 1)
	_park_rect = Rect2i(
		Vector2i(park_block_x * ROAD_SPACING, park_block_y * ROAD_SPACING),
		Vector2i(park_blocks_wide * ROAD_SPACING, park_blocks_long * ROAD_SPACING)
	)

	var lake_width: int = maxi(4, int(_park_rect.size.x / 3))
	var lake_height: int = maxi(3, int(_park_rect.size.y * 0.12))
	_lake_rect = Rect2i(
		Vector2i(
			_park_rect.position.x + int((_park_rect.size.x - lake_width) / 2),
			_park_rect.position.y + int(_park_rect.size.y * 0.39)
		),
		Vector2i(lake_width, lake_height)
	)


func _is_land(x: int, y: int) -> bool:
	if y < 0 or y >= _map_height or x < 0 or x >= _map_width:
		return false
	return x >= _coast_left[y] and x <= _coast_right[y]


func _is_in_park(x: int, y: int) -> bool:
	return _park_rect.has_point(Vector2i(x, y))


func _is_in_lake(x: int, y: int) -> bool:
	return _lake_rect.has_point(Vector2i(x, y))


func _is_park_path(x: int, y: int) -> bool:
	if not _is_in_park(x, y):
		return false
	var local_x: int = x - _park_rect.position.x
	var local_y: int = y - _park_rect.position.y
	if local_x <= 1 or local_x >= _park_rect.size.x - 2:
		return true
	if local_y <= 1 or local_y >= _park_rect.size.y - 2:
		return true
	if absf(float(local_x) - float(_park_rect.size.x) * 0.5) <= 1.0:
		return true
	if local_x == int(_park_rect.size.x * 0.25) or local_x == int(_park_rect.size.x * 0.75):
		return true
	return local_y % (ROAD_SPACING * 2) == 0


func _arterial_x_at(y: int) -> int:
	var t: float = float(y) / float(maxi(1, _map_height - 1))
	var curve: float = sin(t * PI * 2.35 + 0.45) * float(_map_width) * 0.16
	var x: int = int(roundf(float(_map_width) * 0.5 + curve))
	if _is_in_park(x, y):
		x = _park_rect.position.x - 3
	return x


func _secondary_arterial_x_at(y: int) -> int:
	var t: float = float(y) / float(maxi(1, _map_height - 1))
	var curve: float = cos(t * PI * 1.8 + 1.15) * float(_map_width) * 0.18
	var x: int = int(roundf(float(_map_width) * 0.5 + curve))
	if _is_in_park(x, y):
		x = _park_rect.position.x + _park_rect.size.x + 3
	return x


func _is_primary_arterial(x: int, y: int) -> bool:
	return x == _arterial_x_at(y) or x == _secondary_arterial_x_at(y)


func _is_ring_road(x: int, y: int) -> bool:
	var radius_x: float = maxf(1.0, float(_map_width) * 0.41)
	var radius_y: float = maxf(1.0, float(_map_height) * 0.41)
	var normalized_x: float = (float(x) - float(_map_width) * 0.5) / radius_x
	var normalized_y: float = (float(y) - float(_map_height) * 0.5) / radius_y
	var radius: float = sqrt(normalized_x * normalized_x + normalized_y * normalized_y)
	return absf(radius - 0.72) <= 0.018


func _is_dock_cell(x: int, y: int) -> bool:
	if y < 0 or y >= _map_height:
		return false
	var harbor_center_y: int = int(_map_height * 0.29)
	if abs(y - harbor_center_y) > 3:
		return false
	return x >= _coast_left[y] - 7 and x < _coast_left[y]


func _is_near_ring_road(x: int, y: int) -> bool:
	for offset_y: int in range(-1, 2):
		for offset_x: int in range(-1, 2):
			if _is_ring_road(x + offset_x, y + offset_y):
				return true
	return false


func _tile_for_cell(x: int, y: int) -> int:
	if _is_dock_cell(x, y):
		return TILE_DOCK
	if not _is_land(x, y):
		if y >= 0 and y < _map_height and y % CROSS_STREET_SPACING == 0:
			var left: int = _coast_left[y]
			var right: int = _coast_right[y]
			if x >= left - 5 and x <= right + 5:
				return TILE_BRIDGE
		return TILE_WATER
	if _is_in_lake(x, y):
		return TILE_WATER
	if _is_in_park(x, y):
		return TILE_PARK_PATH if _is_park_path(x, y) else TILE_PARK

	var road_x: bool = x % ROAD_SPACING == 0
	var road_y: bool = y % ROAD_SPACING == 0
	var is_arterial: bool = _is_primary_arterial(x, y)
	var on_ring_road: bool = _is_ring_road(x, y)
	var tile: int = TILE_GRASS
	if road_x and road_y:
		tile = (
			TILE_AVENUE_INTERSECTION
			if x % AVENUE_SPACING == 0 or y % CROSS_STREET_SPACING == 0
			else TILE_INTERSECTION
		)
	elif road_x:
		tile = TILE_AVENUE_Y if x % AVENUE_SPACING == 0 else TILE_ROAD_Y
	elif road_y:
		tile = TILE_AVENUE_X if y % CROSS_STREET_SPACING == 0 else TILE_ROAD_X
	elif is_arterial or on_ring_road:
		tile = TILE_ARTERIAL
	elif x % ROAD_SPACING == 1 or x % ROAD_SPACING == ROAD_SPACING - 1:
		tile = TILE_SIDEWALK
	elif y % ROAD_SPACING == 1 or y % ROAD_SPACING == ROAD_SPACING - 1:
		tile = TILE_SIDEWALK
	elif x <= _coast_left[y] + 2 or x >= _coast_right[y] - 2:
		tile = TILE_PROMENADE
	return tile


func _tile_art_variant(x: int, y: int, base_tile: int) -> int:
	var texture_roll: int = posmod(x * 37 + y * 73 + x * y * 11, 100)
	if base_tile == TILE_GRASS and texture_roll < 27:
		return TILE_GRASS_VARIANT
	if base_tile == TILE_PARK and texture_roll < 38:
		return TILE_PARK_VARIANT
	if base_tile == TILE_WATER and texture_roll < 30:
		return TILE_WATER_VARIANT
	if base_tile == TILE_SIDEWALK and texture_roll < 24:
		return TILE_SIDEWALK_VARIANT
	return base_tile


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

	for y: int in range(-2, _map_height + 2):
		for x: int in range(-2, _map_width + 2):
			var cell := Vector2i(x, y)
			var base_tile: int = _tile_for_cell(x, y)
			var art_tile: int = base_tile
			if _visual_neighborhood_rect.has_point(cell):
				art_tile = _tile_art_variant(x, y, base_tile)
			_ground.set_cell(cell, 0, Vector2i(art_tile, 0))

	_props = CityPropsRenderer.new()
	_props.name = "StaticProps"
	_props.z_index = -2
	add_child(_props)


func _make_tile_atlas() -> Image:
	var image := Image.create(TILE_SIZE * TILE_COUNT, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	_paint_iso_tile(image, TILE_GRASS, Color("#3e805f"), Color("#244c49"), 0)
	_paint_iso_tile(image, TILE_SIDEWALK, Color("#b1aa93"), Color("#55585a"), 1)
	_paint_iso_tile(image, TILE_ROAD_X, Color("#35434d"), Color("#202f3b"), 2)
	_paint_iso_tile(image, TILE_ROAD_Y, Color("#35434d"), Color("#202f3b"), 3)
	_paint_iso_tile(image, TILE_INTERSECTION, Color("#414d53"), Color("#202f3b"), 4)
	_paint_iso_tile(image, TILE_WATER, Color("#3c8290"), Color("#285764"), 5)
	_paint_iso_tile(image, TILE_PARK, Color("#4d9563"), Color("#2f684f"), 6)
	_paint_iso_tile(image, TILE_PARK_PATH, Color("#c0b18b"), Color("#776c58"), 7)
	_paint_iso_tile(image, TILE_PROMENADE, Color("#a7a38d"), Color("#575e5b"), 8)
	_paint_iso_tile(image, TILE_AVENUE_X, Color("#303f4a"), Color("#1d2d38"), 9)
	_paint_iso_tile(image, TILE_AVENUE_Y, Color("#303f4a"), Color("#1d2d38"), 10)
	_paint_iso_tile(image, TILE_AVENUE_INTERSECTION, Color("#3a4850"), Color("#1d2d38"), 11)
	_paint_iso_tile(image, TILE_ARTERIAL, Color("#39454b"), Color("#20313a"), 12)
	_paint_iso_tile(image, TILE_BRIDGE, Color("#55646a"), Color("#283941"), 13)
	_paint_iso_tile(image, TILE_DOCK, Color("#9a7756"), Color("#4e4b42"), 14)
	_paint_iso_tile(image, TILE_GRASS_VARIANT, Color("#477f5d"), Color("#2e5948"), 15)
	_paint_iso_tile(image, TILE_PARK_VARIANT, Color("#5a9b66"), Color("#397451"), 16)
	_paint_iso_tile(image, TILE_WATER_VARIANT, Color("#438b96"), Color("#2f6975"), 17)
	_paint_iso_tile(image, TILE_SIDEWALK_VARIANT, Color("#b9b096"), Color("#988f7a"), 18)
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
			elif detail_kind == 5:
				if (x + 2 * y) % 47 == 0:
					color = base_color.lightened(0.19)
				elif (x * 3 + y) % 71 == 0:
					color = base_color.darkened(0.15)
			elif detail_kind == 6:
				if (x * 7 + y * 11) % 61 == 0:
					color = base_color.lightened(0.16)
				elif (x + y * 3) % 79 == 0:
					color = base_color.darkened(0.15)
			elif detail_kind == 7 and (x % 14 == 0 or y % 14 == 0):
				color = base_color.lightened(0.12)
			elif detail_kind == 8 and (y % 11 == 0):
				color = base_color.lightened(0.08)
			elif detail_kind in [9, 10, 11, 12] and (x + y) % 67 == 0:
				color = base_color.lightened(0.06)
			elif detail_kind == 13 and (x + y) % 11 == 0:
				color = base_color.lightened(0.07)
			elif detail_kind == 14 and (x % 12 == 0 or y % 10 == 0):
				color = base_color.lightened(0.12)
			elif detail_kind == 15:
				if (x * 17 + y * 29) % 47 == 0:
					color = Color("#86a96a")
				elif (x + y * 3) % 71 == 0:
					color = Color("#376e51")
			elif detail_kind == 16:
				if (x * 11 + y * 19) % 97 == 0:
					color = Color("#dbd18a")
				elif (x * 7 + y * 13) % 89 == 0:
					color = Color("#8bbd73")
			elif detail_kind == 17:
				if (x + y * 2) % 31 == 0:
					color = base_color.lightened(0.16)
				elif (x * 2 + y) % 67 == 0:
					color = base_color.darkened(0.11)
			elif detail_kind == 18 and (x % 12 == 0 or y % 12 == 0):
				color = base_color.lightened(0.07)
			image.set_pixel(offset_x + x, y, color)

	if detail_kind == 2 or detail_kind == 9:
		_paint_road_dash(image, offset_x, 1)
	elif detail_kind == 3 or detail_kind == 10:
		_paint_road_dash(image, offset_x, -1)
	elif detail_kind == 4 or detail_kind == 11:
		_paint_road_dash(image, offset_x, 1)
		_paint_road_dash(image, offset_x, -1)
		_paint_crosswalk(image, offset_x)
	elif detail_kind == 12:
		_paint_road_dash(image, offset_x, 1)
		_paint_road_dash(image, offset_x, -1)
	elif detail_kind == 13:
		for stripe: int in range(-13, 14, 6):
			for thickness: int in range(-1, 2):
				_set_atlas_pixel(
					image, offset_x + 32 + stripe + thickness, 31 + stripe, Color("#abb4ad")
				)


func _paint_crosswalk(image: Image, offset_x: int) -> void:
	for stripe: int in range(-2, 3):
		for mark: int in range(-4, 5):
			_set_atlas_pixel(image, offset_x + 32 + stripe * 4, 23 + mark, Color("#d6d0b3"))


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


func _block_is_buildable(block_x: int, block_y: int) -> bool:
	var block_rect := Rect2i(Vector2i(block_x, block_y), Vector2i(ROAD_SPACING, ROAD_SPACING))
	if _park_rect.intersects(block_rect):
		return false
	var samples: Array[Vector2i] = [
		Vector2i(block_x + 2, block_y + 2),
		Vector2i(block_x + ROAD_SPACING - 2, block_y + 2),
		Vector2i(block_x + 2, block_y + ROAD_SPACING - 2),
		Vector2i(block_x + ROAD_SPACING - 2, block_y + ROAD_SPACING - 2),
		Vector2i(block_x + ROAD_SPACING / 2, block_y + ROAD_SPACING / 2),
	]
	for sample: Vector2i in samples:
		if not _is_land(sample.x, sample.y):
			return false
	return true


func _collect_city_blocks() -> void:
	_city_blocks.clear()
	_city_block_count = 0
	for block_y: int in range(0, _map_height - 1, ROAD_SPACING):
		for block_x: int in range(0, _map_width - 1, ROAD_SPACING):
			if _block_is_buildable(block_x, block_y):
				_city_blocks.append(Vector2i(block_x, block_y))
	_city_block_count = _city_blocks.size()


func _get_landmark_blocks() -> Dictionary:
	var chosen: Dictionary = {}
	if _city_blocks.is_empty():
		return chosen

	var landmark_targets: Array[Dictionary] = [
		{"kind": "station", "cell": Vector2i(_map_width / 2 + 8, int(_map_height * 0.24))},
		{"kind": "tower", "cell": Vector2i(_map_width / 2, int(_map_height * 0.53))},
		{"kind": "civic", "cell": Vector2i(_map_width / 2 - 8, int(_map_height * 0.75))},
	]
	for target: Dictionary in landmark_targets:
		var target_cell: Vector2i = target["cell"]
		var best_block: Vector2i = _city_blocks[0]
		var best_distance: float = INF
		for block: Vector2i in _city_blocks:
			if chosen.has(block):
				continue
			var block_center := Vector2(block.x + ROAD_SPACING * 0.5, block.y + ROAD_SPACING * 0.5)
			var distance: float = block_center.distance_to(Vector2(target_cell))
			if distance < best_distance:
				best_distance = distance
				best_block = block
		chosen[best_block] = str(target["kind"])
	return chosen


func _build_city_blocks() -> void:
	_collect_city_blocks()
	var landmark_blocks: Dictionary = _get_landmark_blocks()
	var wall_palette: Array[Color] = [
		Color("#c58469"),
		Color("#baaa83"),
		Color("#69959a"),
		Color("#9c789a"),
		Color("#c4c5b1"),
		Color("#7b92a0"),
		Color("#d29664"),
		Color("#8c9f83"),
	]
	var roof_palette: Array[Color] = [
		Color("#df9a69"),
		Color("#d7c691"),
		Color("#78b7aa"),
		Color("#be8ab1"),
		Color("#e0d8bb"),
		Color("#88a9ba"),
		Color("#b66f58"),
		Color("#c8a47c"),
	]
	var tree_palette: Array[Color] = [
		Color("#408b60"),
		Color("#5a9d63"),
		Color("#62965d"),
		Color("#398071"),
		Color("#70a65d"),
		Color("#3a795f"),
	]

	for block: Vector2i in _city_blocks:
		var min_x: int = block.x + 2
		var max_x: int = mini(block.x + ROAD_SPACING - 2, _map_width - 2)
		var min_y: int = block.y + 2
		var max_y: int = mini(block.y + ROAD_SPACING - 2, _map_height - 2)
		if landmark_blocks.has(block):
			_add_landmark(block, str(landmark_blocks[block]))
			continue

		var block_center := Vector2i(block.x + ROAD_SPACING / 2, block.y + ROAD_SPACING / 2)
		var in_visual_neighborhood: bool = _visual_neighborhood_rect.has_point(block_center)
		var occupied: Array[Vector2i] = []
		var building_count: int = CityBuildingProfile.roll_count(_rng, in_visual_neighborhood)
		var normalized_y: float = float(block_center.y) / float(_map_height)
		var is_skyline: bool = (
			absf(normalized_y - 0.52) < 0.19
			and absf(float(block_center.x) - float(_map_width) * 0.5) < float(_map_width) * 0.32
		)
		var minimum_building_distance: float = 2.8 if in_visual_neighborhood else 2.0

		for building_index: int in range(building_count):
			var cell: Vector2i = _pick_free_cell(
				min_x, max_x, min_y, max_y, occupied, minimum_building_distance
			)
			if cell.x < 0:
				continue
			occupied.append(cell)

			var palette_index: int = _rng.randi_range(0, wall_palette.size() - 1)
			var building_height: float = CityBuildingProfile.roll_height(
				_rng, in_visual_neighborhood, is_skyline, building_index
			)
			var building_footprint: Vector2 = CityBuildingProfile.roll_footprint(
				_rng, in_visual_neighborhood
			)
			_props.call(
				"add_building",
				_cell_to_world(cell),
				building_footprint.x,
				building_footprint.y,
				building_height,
				wall_palette[palette_index],
				roof_palette[palette_index],
				_rng.randi_range(0, 4),
				_rng.randi(),
				in_visual_neighborhood
			)

		var should_add_tree: bool = true
		if in_visual_neighborhood:
			should_add_tree = _rng.randf() < 0.46
		if should_add_tree:
			var tree_distance: float = 2.2 if in_visual_neighborhood else 1.7
			var tree_cell: Vector2i = _pick_free_cell(
				min_x, max_x, min_y, max_y, occupied, tree_distance
			)
			if tree_cell.x >= 0:
				occupied.append(tree_cell)
				var tree_color: Color = tree_palette[_rng.randi_range(0, tree_palette.size() - 1)]
				_props.call(
					"add_tree", _cell_to_world(tree_cell), tree_color, _rng.randf_range(24.0, 35.0)
				)
				var should_add_extra_tree: bool
				if in_visual_neighborhood:
					should_add_extra_tree = _rng.randf() < 0.16
				else:
					should_add_extra_tree = _rng.randf() < 0.30
				if should_add_extra_tree:
					var extra_tree_distance: float = 2.0 if in_visual_neighborhood else 1.7
					var extra_tree_cell: Vector2i = _pick_free_cell(
						min_x, max_x, min_y, max_y, occupied, extra_tree_distance
					)
					if extra_tree_cell.x >= 0:
						var extra_color: Color = tree_palette[_rng.randi_range(
							0, tree_palette.size() - 1
						)]
						_props.call(
							"add_tree",
							_cell_to_world(extra_tree_cell),
							extra_color,
							_rng.randf_range(23.0, 33.0)
						)


func _add_landmark(block: Vector2i, kind: String) -> void:
	var palette: Dictionary = {
		"station": {"wall": Color("#bd9a68"), "roof": Color("#536d70"), "height": 82.0},
		"tower": {"wall": Color("#7899a1"), "roof": Color("#c6d3d1"), "height": 244.0},
		"civic": {"wall": Color("#d1b985"), "roof": Color("#8f604d"), "height": 126.0},
	}
	var style: Dictionary = palette.get(kind, palette["civic"])
	var cell := Vector2i(block.x + ROAD_SPACING / 2, block.y + ROAD_SPACING / 2)
	_props.call(
		"add_landmark",
		_cell_to_world(cell),
		66.0 if kind != "tower" else 57.0,
		43.0 if kind != "tower" else 38.0,
		float(style["height"]),
		style["wall"],
		style["roof"],
		kind
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

	for _attempt: int in range(72):
		var candidate := Vector2i(_rng.randi_range(min_x, max_x), _rng.randi_range(min_y, max_y))
		if not _is_land(candidate.x, candidate.y) or _is_in_park(candidate.x, candidate.y):
			continue
		if _is_primary_arterial(candidate.x, candidate.y):
			continue
		if _is_near_ring_road(candidate.x, candidate.y):
			continue
		var is_free: bool = true
		for taken: Vector2i in occupied:
			if Vector2(candidate - taken).length() < minimum_distance:
				is_free = false
				break
		if is_free:
			return candidate
	return Vector2i(-1, -1)


func _build_park_details() -> void:
	var tree_palette: Array[Color] = [
		Color("#367c50"),
		Color("#4b9257"),
		Color("#679b5b"),
		Color("#3d866a"),
		Color("#78a45e"),
		Color("#2f7354"),
	]
	var park_area: int = _park_rect.size.x * _park_rect.size.y
	var target_tree_count: int = maxi(12, int(park_area / 7))
	var trees_added: int = 0
	var attempts: int = 0
	while trees_added < target_tree_count and attempts < target_tree_count * 12:
		attempts += 1
		var cell := Vector2i(
			_rng.randi_range(
				_park_rect.position.x + 2, _park_rect.position.x + _park_rect.size.x - 3
			),
			_rng.randi_range(
				_park_rect.position.y + 2, _park_rect.position.y + _park_rect.size.y - 3
			)
		)
		if _is_in_lake(cell.x, cell.y) or _is_park_path(cell.x, cell.y):
			continue
		_props.call(
			"add_tree",
			_cell_to_world(cell),
			tree_palette[_rng.randi_range(0, tree_palette.size() - 1)],
			_rng.randf_range(24.0, 36.0)
		)
		trees_added += 1

	var bench_count: int = maxi(3, int(target_tree_count / 14))
	for bench_index: int in range(bench_count):
		var bench_cell := Vector2i(
			(
				_park_rect.position.x + int(_park_rect.size.x * 0.25)
				if bench_index % 2 == 0
				else _park_rect.position.x + int(_park_rect.size.x * 0.75)
			),
			(
				_park_rect.position.y
				+ int(float(_park_rect.size.y) * float(bench_index + 1) / float(bench_count + 1))
			)
		)
		if _is_in_lake(bench_cell.x, bench_cell.y):
			bench_cell.y = _park_rect.position.y + 3
		_props.call("add_bench", _cell_to_world(bench_cell), Color("#ad7448"))
		if bench_index % 2 == 0:
			_props.call("add_street_lamp", _cell_to_world(bench_cell + Vector2i(2, 1)))

	var fountain_cell := Vector2i(
		_park_rect.position.x + _park_rect.size.x / 2,
		_park_rect.position.y + int(_park_rect.size.y * 0.78)
	)
	_props.call("add_fountain", _cell_to_world(fountain_cell))


func _build_harbor_details() -> void:
	var harbor_y: int = int(_map_height * 0.29)
	var harbor_left: int = _coast_left[harbor_y]
	var crane_cell := Vector2i(harbor_left - 4, harbor_y)
	_props.call("add_port_crane", _cell_to_world(crane_cell))
	_props.call(
		"add_shipping_container", _cell_to_world(crane_cell + Vector2i(2, 2)), Color("#c75f50")
	)
	_props.call(
		"add_shipping_container", _cell_to_world(crane_cell + Vector2i(-2, -2)), Color("#557a8b")
	)
	_props.call("add_harbor_boat", _cell_to_world(Vector2i(harbor_left - 5, harbor_y + 5)))


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
		Color("#d7ded0"),
		Color("#de8752"),
		Color("#79a8cb"),
	]
	var trouser_colors: Array[Color] = [
		Color("#26394f"),
		Color("#39434e"),
		Color("#55435b"),
		Color("#47584c"),
	]

	var pedestrian_blocks: Array[Vector2i] = []
	pedestrian_blocks.append_array(_city_blocks)
	for index: int in range(pedestrian_blocks.size() - 1, 0, -1):
		var swap_index: int = _rng.randi_range(0, index)
		var saved_block: Vector2i = pedestrian_blocks[index]
		pedestrian_blocks[index] = pedestrian_blocks[swap_index]
		pedestrian_blocks[swap_index] = saved_block
	var citizen_budget: int = mini(
		pedestrian_blocks.size(), clampi(int(roundf(float(_city_block_count) * 0.72)), 20, 128)
	)
	for block_index: int in range(citizen_budget):
		var block: Vector2i = pedestrian_blocks[block_index]
		var block_center := Vector2i(block.x + ROAD_SPACING / 2, block.y + ROAD_SPACING / 2)
		var in_visual_neighborhood: bool = _visual_neighborhood_rect.has_point(block_center)
		var route: PackedVector2Array = _make_block_sidewalk_route(block.x, block.y)
		if route.size() < 4:
			continue
		var citizen: Node2D = CityCitizen.new()
		citizen.name = "Citizen_%03d" % _citizen_count
		citizen.call(
			"configure",
			route,
			_rng.randf_range(34.0, 61.0),
			shirt_colors[_rng.randi_range(0, shirt_colors.size() - 1)],
			trouser_colors[_rng.randi_range(0, trouser_colors.size() - 1)],
			Color("#f0b88d") if _rng.randf() < 0.68 else Color("#9c654e"),
			Color("#382c35") if _rng.randf() < 0.78 else Color("#c88a52"),
			_rng.randf_range(0.0, _route_length(route)),
			in_visual_neighborhood
		)
		_population.add_child(citizen)
		_citizen_count += 1


func _make_block_sidewalk_route(block_x: int, block_y: int) -> PackedVector2Array:
	var left: int = block_x + 1
	var right: int = mini(block_x + ROAD_SPACING - 1, _map_width - 2)
	var top: int = block_y + 1
	var bottom: int = mini(block_y + ROAD_SPACING - 1, _map_height - 2)
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

	var car_colors: Array[Color] = [
		Color("#e7655b"),
		Color("#50a7a3"),
		Color("#e5b54d"),
		Color("#8089d4"),
		Color("#e6e1cc"),
		Color("#5b7189"),
		Color("#d67f9d"),
		Color("#78995b"),
		Color("#e0a445"),
		Color("#cb625c"),
	]
	var roof_colors: Array[Color] = [
		Color("#f2d590"),
		Color("#bde3dc"),
		Color("#f2e1a2"),
		Color("#d2d5f3"),
		Color("#9cb6bf"),
		Color("#b9c7d0"),
		Color("#f0c0cf"),
		Color("#c4d3bd"),
	]
	var total_cars: int = clampi(int(_city_block_count / 7), 10, 24)
	_car_count = total_cars

	for car_index: int in range(total_cars):
		var route: PackedVector2Array = _make_car_route(car_index % 3)
		var total_route_length: float = _route_length(route)
		var car: Node2D = CityCar.new()
		car.name = "Vehicle_%02d" % car_index
		var lane_offset: float = -6.0 if car_index % 2 == 0 else 6.0
		var vehicle_type: int = 0
		if car_index % 8 == 2:
			vehicle_type = 1
		elif car_index % 10 == 4:
			vehicle_type = 2
		elif car_index % 9 == 5:
			vehicle_type = 3
		var vehicle_color: Color = car_colors[car_index % car_colors.size()]
		if vehicle_type == 1:
			vehicle_color = Color("#e5b94d")
		elif vehicle_type == 2:
			vehicle_color = Color("#d7a842")
		elif vehicle_type == 3:
			vehicle_color = Color("#d5d5c8")
		car.call(
			"configure",
			route,
			_rng.randf_range(118.0, 184.0),
			lane_offset,
			vehicle_color,
			roof_colors[car_index % roof_colors.size()],
			total_route_length * float(car_index) / float(total_cars) + _rng.randf_range(0.0, 70.0),
			vehicle_type
		)
		_traffic.add_child(car)


func _make_car_route(route_variant: int) -> PackedVector2Array:
	var route := PackedVector2Array()
	var horizontal_margin_blocks: int = maxi(1, int(floor(float(_blocks_wide) * 0.28)))
	var vertical_margin_blocks: int = maxi(1, int(floor(float(_blocks_long) * 0.12)))
	var x0: int = horizontal_margin_blocks * ROAD_SPACING
	var x1: int = (_blocks_wide - horizontal_margin_blocks) * ROAD_SPACING
	var y0: int = vertical_margin_blocks * ROAD_SPACING
	var y1: int = (_blocks_long - vertical_margin_blocks) * ROAD_SPACING

	if route_variant == 1 and x1 - x0 > ROAD_SPACING * 2:
		x0 += ROAD_SPACING
		x1 -= ROAD_SPACING
		y0 += ROAD_SPACING
		y1 -= ROAD_SPACING
	elif route_variant == 2 and x1 - x0 > ROAD_SPACING * 3:
		x0 += ROAD_SPACING
		x1 -= ROAD_SPACING

	if x1 <= x0 or y1 <= y0:
		return route
	for x: int in range(x0, x1 + 1):
		route.append(_cell_to_world(Vector2i(x, y0)))
	for y: int in range(y0 + 1, y1 + 1):
		route.append(_cell_to_world(Vector2i(x1, y)))
	for x: int in range(x1 - 1, x0 - 1, -1):
		route.append(_cell_to_world(Vector2i(x, y1)))
	for y: int in range(y1 - 1, y0, -1):
		route.append(_cell_to_world(Vector2i(x0, y)))
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
