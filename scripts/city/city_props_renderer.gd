extends Node2D

## Draws generated buildings and trees as lightweight, replaceable pixel-art placeholders.
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
	var building: Dictionary = {
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
	_props.append(building)
	queue_redraw()


func add_tree(world_position: Vector2, canopy_color: Color, size: float) -> void:
	var tree: Dictionary = {
		"kind": "tree",
		"position": world_position,
		"canopy_color": canopy_color,
		"size": size,
	}
	_props.append(tree)
	queue_redraw()


func _draw() -> void:
	var sorted_props: Array[Dictionary] = _props.duplicate()
	sorted_props.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return a["position"].y < b["position"].y
	)

	for prop: Dictionary in sorted_props:
		if prop["kind"] == "building":
			_draw_building(prop)
		else:
			_draw_tree(prop)


func _draw_building(prop: Dictionary) -> void:
	var center: Vector2 = prop["position"]
	var half_width: float = prop["width"] * 0.5
	var half_depth: float = prop["depth"] * 0.5
	var height: float = prop["height"]
	var wall: Color = prop["wall_color"]
	var roof: Color = prop["roof_color"]
	var lift: Vector2 = Vector2(0.0, -height)
	var outline: Color = Color("#243442")

	var back: Vector2 = center + Vector2(0.0, -half_depth)
	var right: Vector2 = center + Vector2(half_width, 0.0)
	var front: Vector2 = center + Vector2(0.0, half_depth)
	var left: Vector2 = center + Vector2(-half_width, 0.0)

	# Ground shadow and the two visible faces of the isometric building.
	_draw_diamond(
		center + Vector2(7.0, 7.0),
		half_width + 11.0,
		half_depth + 7.0,
		Color(0.04, 0.09, 0.10, 0.27)
	)
	_draw_polygon(PackedVector2Array([left, front, front + lift, left + lift]), wall.darkened(0.22))
	_draw_polygon(
		PackedVector2Array([front, right, right + lift, front + lift]), wall.darkened(0.39)
	)

	# Windows sit on the front-facing walls below the roof line.
	var window_light: Color = Color("#f4d796")
	var window_dark: Color = Color("#758c95")
	var window_color: Color = window_light if int(prop["seed"]) % 3 == 0 else window_dark
	var window_rows: int = 2 if height > 75.0 else 1
	for row: int in range(window_rows):
		var window_y: float = center.y - height * 0.66 + float(row) * 15.0
		for column: int in range(2):
			var left_x: float = center.x - half_width * 0.57 + float(column) * half_width * 0.48
			draw_rect(Rect2(Vector2(left_x, window_y), Vector2(5.0, 8.0)), outline)
			draw_rect(Rect2(Vector2(left_x + 1.0, window_y + 1.0), Vector2(3.0, 6.0)), window_color)
			var right_x: float = center.x + half_width * 0.06 + float(column) * half_width * 0.42
			draw_rect(Rect2(Vector2(right_x, window_y + 2.0), Vector2(5.0, 8.0)), outline)
			draw_rect(
				Rect2(Vector2(right_x + 1.0, window_y + 3.0), Vector2(3.0, 6.0)),
				window_color.darkened(0.16)
			)

	var roof_points: PackedVector2Array = PackedVector2Array(
		[back + lift, right + lift, front + lift, left + lift]
	)
	draw_colored_polygon(roof_points, roof)
	_draw_outline(
		PackedVector2Array([back + lift, right + lift, front + lift, left + lift, back + lift]),
		outline,
		2.0
	)

	# Rooftop accents vary with the building type.
	var variant: int = int(prop["variant"])
	if variant == 0:
		draw_rect(
			Rect2(Vector2(center.x - 7.0, center.y - height - 9.0), Vector2(14.0, 9.0)),
			wall.lightened(0.12)
		)
		draw_rect(
			Rect2(Vector2(center.x - 4.0, center.y - height - 13.0), Vector2(8.0, 4.0)),
			roof.darkened(0.08)
		)
	elif variant == 1:
		draw_rect(
			Rect2(Vector2(center.x - 3.0, center.y - height - 19.0), Vector2(6.0, 20.0)), outline
		)
		draw_rect(
			Rect2(Vector2(center.x - 1.0, center.y - height - 18.0), Vector2(2.0, 17.0)),
			Color("#d9edf0")
		)
	else:
		draw_rect(
			Rect2(Vector2(center.x - 10.0, center.y - height - 7.0), Vector2(20.0, 7.0)),
			wall.darkened(0.12)
		)

	# Edge accents make the shapes read cleanly at phone scale.
	_draw_outline(PackedVector2Array([left, front, front + lift]), outline, 2.0)
	_draw_outline(PackedVector2Array([front, right, right + lift]), outline, 2.0)


func _draw_tree(prop: Dictionary) -> void:
	var center: Vector2 = prop["position"]
	var size: float = prop["size"]
	var canopy: Color = prop["canopy_color"]
	var trunk: Color = Color("#744d38")
	var outline: Color = Color("#254338")

	_draw_diamond(
		center + Vector2(3.0, 4.0), size * 0.48, size * 0.20, Color(0.04, 0.09, 0.08, 0.27)
	)
	draw_rect(
		Rect2(Vector2(center.x - 4.0, center.y - size * 0.55), Vector2(8.0, size * 0.55)), outline
	)
	draw_rect(
		Rect2(Vector2(center.x - 2.0, center.y - size * 0.52), Vector2(5.0, size * 0.50)), trunk
	)

	var crown_y: float = center.y - size * 1.18
	draw_rect(
		Rect2(
			Vector2(center.x - size * 0.43, crown_y + size * 0.27),
			Vector2(size * 0.86, size * 0.45)
		),
		outline
	)
	draw_rect(
		Rect2(
			Vector2(center.x - size * 0.37, crown_y + size * 0.24),
			Vector2(size * 0.74, size * 0.43)
		),
		canopy.darkened(0.18)
	)
	draw_rect(
		Rect2(
			Vector2(center.x - size * 0.28, crown_y + size * 0.08),
			Vector2(size * 0.56, size * 0.34)
		),
		canopy
	)
	draw_rect(
		Rect2(Vector2(center.x - size * 0.16, crown_y), Vector2(size * 0.33, size * 0.23)),
		canopy.lightened(0.13)
	)
	draw_rect(
		Rect2(
			Vector2(center.x - size * 0.27, crown_y + size * 0.28),
			Vector2(size * 0.14, size * 0.09)
		),
		canopy.lightened(0.18)
	)


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


func _draw_polygon(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)


func _draw_outline(points: PackedVector2Array, color: Color, width: float) -> void:
	draw_polyline(points, color, width, false)
