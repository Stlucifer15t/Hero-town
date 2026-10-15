extends Node2D

## Lightweight pixel-art props. All shapes are original procedural placeholders.
var _props: Array[Dictionary] = []


func clear() -> void:
	_props.clear()
	queue_redraw()


func add_building(
	world_position: Vector2,
	width: float,
	depth: float,
	height: float,
	wall_color: Color,
	roof_color: Color,
	variant: int,
	seed_value: int
) -> void:
	(
		_props
		. append(
			{
				"kind": "building",
				"position": world_position,
				"width": width,
				"depth": depth,
				"height": height,
				"wall_color": wall_color,
				"roof_color": roof_color,
				"variant": variant,
				"seed": seed_value,
			}
		)
	)
	queue_redraw()


func add_landmark(
	world_position: Vector2,
	width: float,
	depth: float,
	height: float,
	wall_color: Color,
	roof_color: Color,
	landmark_kind: String
) -> void:
	(
		_props
		. append(
			{
				"kind": "landmark",
				"position": world_position,
				"width": width,
				"depth": depth,
				"height": height,
				"wall_color": wall_color,
				"roof_color": roof_color,
				"variant": 4,
				"seed": landmark_kind.hash(),
				"landmark_kind": landmark_kind,
			}
		)
	)
	queue_redraw()


func add_tree(world_position: Vector2, canopy_color: Color, size: float) -> void:
	(
		_props
		. append(
			{
				"kind": "tree",
				"position": world_position,
				"canopy_color": canopy_color,
				"size": size,
			}
		)
	)
	queue_redraw()


func add_bench(world_position: Vector2, wood_color: Color) -> void:
	(
		_props
		. append(
			{
				"kind": "bench",
				"position": world_position,
				"wood_color": wood_color,
			}
		)
	)
	queue_redraw()


func add_fountain(world_position: Vector2) -> void:
	_props.append({"kind": "fountain", "position": world_position})
	queue_redraw()


func add_street_lamp(world_position: Vector2) -> void:
	_props.append({"kind": "street_lamp", "position": world_position})
	queue_redraw()


func _draw() -> void:
	var sorted_props: Array[Dictionary] = _props.duplicate()
	sorted_props.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return a["position"].y < b["position"].y
	)

	for prop: Dictionary in sorted_props:
		match str(prop["kind"]):
			"building", "landmark":
				_draw_building(prop)
			"tree":
				_draw_tree(prop)
			"bench":
				_draw_bench(prop)
			"fountain":
				_draw_fountain(prop)
			"street_lamp":
				_draw_street_lamp(prop)


func _draw_building(prop: Dictionary) -> void:
	var center: Vector2 = prop["position"]
	var half_width: float = float(prop["width"]) * 0.5
	var half_depth: float = float(prop["depth"]) * 0.5
	var height: float = float(prop["height"])
	var wall: Color = prop["wall_color"]
	var roof: Color = prop["roof_color"]
	var lift: Vector2 = Vector2(0.0, -height)
	var outline: Color = Color("#243442")

	var back: Vector2 = center + Vector2(0.0, -half_depth)
	var right: Vector2 = center + Vector2(half_width, 0.0)
	var front: Vector2 = center + Vector2(0.0, half_depth)
	var left: Vector2 = center + Vector2(-half_width, 0.0)

	_draw_diamond(
		center + Vector2(7.0, 7.0),
		half_width + 11.0,
		half_depth + 7.0,
		Color(0.04, 0.09, 0.10, 0.30)
	)
	draw_colored_polygon(
		PackedVector2Array([left, front, front + lift, left + lift]), wall.darkened(0.22)
	)
	draw_colored_polygon(
		PackedVector2Array([front, right, right + lift, front + lift]), wall.darkened(0.39)
	)

	var window_light: Color = Color("#f4d796")
	var window_dark: Color = Color("#718995")
	var seed_value: int = int(prop["seed"])
	var rows: int = clampi(int(height / 15.0), 2, 13)
	var columns: int = clampi(int(half_width / 10.0), 2, 3)
	var floor_gap: float = clampf((height - 24.0) / float(rows), 11.0, 16.0)
	for row: int in range(rows):
		var window_y: float = center.y - height + 8.0 + float(row) * floor_gap
		if window_y > center.y - 10.0:
			break
		for column: int in range(columns):
			var left_x: float = (
				center.x
				- half_width
				+ 5.0
				+ float(column) * (half_width - 12.0) / float(maxi(1, columns - 1))
			)
			var right_x: float = (
				center.x + 2.0 + float(column) * (half_width - 12.0) / float(maxi(1, columns - 1))
			)
			var window_color: Color = (
				window_light if (seed_value + row * 3 + column) % 7 == 0 else window_dark
			)
			_draw_window(Vector2(left_x, window_y), window_color)
			_draw_window(Vector2(right_x, window_y + 1.0), window_color.darkened(0.12))

	var roof_points := PackedVector2Array([back + lift, right + lift, front + lift, left + lift])
	draw_colored_polygon(roof_points, roof)
	_draw_outline(
		PackedVector2Array([back + lift, right + lift, front + lift, left + lift, back + lift]),
		outline,
		2.0
	)

	# Storefronts and awnings break up the repeated residential facades.
	if height < 150.0:
		var awning_color: Color = roof.lightened(0.08)
		draw_rect(
			Rect2(
				Vector2(center.x - half_width * 0.48, center.y - 13.0),
				Vector2(half_width * 0.48, 6.0)
			),
			awning_color
		)
		draw_rect(
			Rect2(Vector2(center.x + 1.0, center.y - 12.0), Vector2(half_width * 0.43, 5.0)),
			awning_color.darkened(0.10)
		)
		draw_rect(
			Rect2(Vector2(center.x - 5.0, center.y - 11.0), Vector2(7.0, 10.0)), Color("#243442")
		)
		draw_rect(
			Rect2(Vector2(center.x + 4.0, center.y - 10.0), Vector2(6.0, 9.0)), Color("#2b3d47")
		)

	var variant: int = int(prop["variant"])
	var landmark_kind: String = str(prop.get("landmark_kind", ""))
	if landmark_kind == "tower" or (landmark_kind.is_empty() and variant == 1):
		draw_rect(
			Rect2(Vector2(center.x - 3.0, center.y - height - 26.0), Vector2(6.0, 27.0)), outline
		)
		draw_rect(
			Rect2(Vector2(center.x - 1.0, center.y - height - 25.0), Vector2(2.0, 21.0)),
			Color("#d9edf0")
		)
	elif landmark_kind == "civic":
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(center.x - 15.0, center.y - height + 4.0),
					Vector2(center.x, center.y - height - 12.0),
					Vector2(center.x + 15.0, center.y - height + 4.0),
				]
			),
			roof.lightened(0.16)
		)
		draw_rect(Rect2(Vector2(center.x - 2.0, center.y - height - 20.0), Vector2(4.0, 9.0)), roof)
	elif landmark_kind == "station":
		draw_rect(
			Rect2(
				Vector2(center.x - half_width * 0.42, center.y - height + 8.0),
				Vector2(half_width * 0.84, 8.0)
			),
			Color("#e6c777")
		)
		draw_rect(
			Rect2(Vector2(center.x - 3.0, center.y - height + 9.0), Vector2(6.0, 6.0)),
			Color("#263a46")
		)
	elif variant == 0:
		draw_rect(
			Rect2(Vector2(center.x - 7.0, center.y - height - 9.0), Vector2(14.0, 9.0)),
			wall.lightened(0.12)
		)
		draw_rect(
			Rect2(Vector2(center.x - 4.0, center.y - height - 13.0), Vector2(8.0, 4.0)),
			roof.darkened(0.08)
		)
	elif variant == 2:
		draw_rect(
			Rect2(Vector2(center.x - 10.0, center.y - height - 7.0), Vector2(20.0, 7.0)),
			wall.darkened(0.12)
		)
	elif variant == 3:
		draw_rect(
			Rect2(Vector2(center.x - 11.0, center.y - height - 5.0), Vector2(22.0, 5.0)),
			Color("#8ec4b2")
		)
		draw_rect(
			Rect2(Vector2(center.x - 2.0, center.y - height - 10.0), Vector2(4.0, 5.0)),
			Color("#d6e3cf")
		)
	else:
		draw_rect(
			Rect2(
				Vector2(center.x - half_width * 0.40, center.y - height - 5.0),
				Vector2(half_width * 0.8, 5.0)
			),
			roof.darkened(0.08)
		)

	_draw_outline(PackedVector2Array([left, front, front + lift]), outline, 2.0)
	_draw_outline(PackedVector2Array([front, right, right + lift]), outline, 2.0)


func _draw_window(position: Vector2, glass_color: Color) -> void:
	draw_rect(Rect2(position, Vector2(5.0, 8.0)), Color("#243442"))
	draw_rect(Rect2(position + Vector2(1.0, 1.0), Vector2(3.0, 6.0)), glass_color)
	draw_rect(Rect2(position + Vector2(2.0, 1.0), Vector2(1.0, 6.0)), Color(0.12, 0.18, 0.22, 0.55))


func _draw_tree(prop: Dictionary) -> void:
	var center: Vector2 = prop["position"]
	var size: float = float(prop["size"])
	var canopy: Color = prop["canopy_color"]
	var trunk: Color = Color("#744d38")
	var outline: Color = Color("#254338")

	_draw_diamond(
		center + Vector2(3.0, 4.0), size * 0.48, size * 0.20, Color(0.04, 0.09, 0.08, 0.29)
	)
	draw_rect(
		Rect2(Vector2(center.x - 4.0, center.y - size * 0.58), Vector2(8.0, size * 0.58)), outline
	)
	draw_rect(
		Rect2(Vector2(center.x - 2.0, center.y - size * 0.54), Vector2(5.0, size * 0.50)), trunk
	)

	var crown_y: float = center.y - size * 1.18
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(center.x, crown_y),
				Vector2(center.x + size * 0.46, crown_y + size * 0.28),
				Vector2(center.x + size * 0.38, crown_y + size * 0.72),
				Vector2(center.x, crown_y + size * 0.92),
				Vector2(center.x - size * 0.40, crown_y + size * 0.68),
				Vector2(center.x - size * 0.46, crown_y + size * 0.30),
			]
		),
		outline
	)
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(center.x, crown_y + 3.0),
				Vector2(center.x + size * 0.38, crown_y + size * 0.30),
				Vector2(center.x + size * 0.31, crown_y + size * 0.65),
				Vector2(center.x, crown_y + size * 0.81),
				Vector2(center.x - size * 0.33, crown_y + size * 0.62),
				Vector2(center.x - size * 0.37, crown_y + size * 0.31),
			]
		),
		canopy.darkened(0.14)
	)
	draw_rect(
		Rect2(
			Vector2(center.x - size * 0.18, crown_y + size * 0.16),
			Vector2(size * 0.36, size * 0.37)
		),
		canopy
	)
	draw_rect(
		Rect2(
			Vector2(center.x - size * 0.11, crown_y + size * 0.07),
			Vector2(size * 0.22, size * 0.18)
		),
		canopy.lightened(0.18)
	)
	draw_rect(
		Rect2(
			Vector2(center.x - size * 0.34, crown_y + size * 0.38),
			Vector2(size * 0.15, size * 0.12)
		),
		canopy.lightened(0.14)
	)


func _draw_bench(prop: Dictionary) -> void:
	var center: Vector2 = prop["position"]
	var wood: Color = prop["wood_color"]
	_draw_diamond(center + Vector2(2.0, 4.0), 15.0, 5.0, Color(0.04, 0.08, 0.08, 0.25))
	draw_rect(Rect2(center + Vector2(-10.0, -9.0), Vector2(20.0, 4.0)), Color("#283b3e"))
	draw_rect(Rect2(center + Vector2(-11.0, -13.0), Vector2(22.0, 5.0)), wood.darkened(0.18))
	draw_rect(Rect2(center + Vector2(-10.0, -14.0), Vector2(20.0, 3.0)), wood)
	draw_rect(Rect2(center + Vector2(-8.0, -8.0), Vector2(3.0, 7.0)), Color("#3b4240"))
	draw_rect(Rect2(center + Vector2(5.0, -8.0), Vector2(3.0, 7.0)), Color("#3b4240"))


func _draw_fountain(prop: Dictionary) -> void:
	var center: Vector2 = prop["position"]
	_draw_diamond(center + Vector2(2.0, 5.0), 26.0, 12.0, Color(0.04, 0.08, 0.08, 0.26))
	draw_colored_polygon(
		PackedVector2Array(
			[
				center + Vector2(0.0, -17.0),
				center + Vector2(25.0, -5.0),
				center + Vector2(0.0, 7.0),
				center + Vector2(-25.0, -5.0),
			]
		),
		Color("#677d78")
	)
	draw_colored_polygon(
		PackedVector2Array(
			[
				center + Vector2(0.0, -13.0),
				center + Vector2(18.0, -5.0),
				center + Vector2(0.0, 3.0),
				center + Vector2(-18.0, -5.0),
			]
		),
		Color("#63b6c0")
	)
	draw_rect(Rect2(center + Vector2(-4.0, -24.0), Vector2(8.0, 12.0)), Color("#d4c99e"))
	draw_rect(Rect2(center + Vector2(-2.0, -30.0), Vector2(4.0, 8.0)), Color("#88d8da"))


func _draw_street_lamp(prop: Dictionary) -> void:
	var center: Vector2 = prop["position"]
	_draw_diamond(center + Vector2(2.0, 3.0), 6.0, 3.0, Color(0.04, 0.08, 0.08, 0.25))
	draw_rect(Rect2(center + Vector2(-2.0, -28.0), Vector2(4.0, 29.0)), Color("#354249"))
	draw_rect(Rect2(center + Vector2(-6.0, -32.0), Vector2(12.0, 5.0)), Color("#303c40"))
	draw_rect(Rect2(center + Vector2(-4.0, -31.0), Vector2(8.0, 3.0)), Color("#f1d992"))


func _draw_diamond(center: Vector2, half_width: float, half_depth: float, color: Color) -> void:
	draw_colored_polygon(
		PackedVector2Array(
			[
				center + Vector2(0.0, -half_depth),
				center + Vector2(half_width, 0.0),
				center + Vector2(0.0, half_depth),
				center + Vector2(-half_width, 0.0),
			]
		),
		color
	)


func _draw_outline(points: PackedVector2Array, color: Color, width: float) -> void:
	draw_polyline(points, color, width, false)
