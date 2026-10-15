extends Node2D

## A tiny car moving continuously along a closed road route.
var _route: PackedVector2Array = PackedVector2Array()
var _speed: float = 150.0
var _segment_index: int = 0
var _distance_on_segment: float = 0.0
var _lane_offset: float = 0.0
var _body_color: Color = Color("#e75c57")
var _roof_color: Color = Color("#f4d889")


func configure(
	route: PackedVector2Array,
	speed: float,
	lane_offset: float,
	body_color: Color,
	roof_color: Color,
	start_distance: float
) -> void:
	_route = route
	_speed = speed
	_lane_offset = lane_offset
	_body_color = body_color
	_roof_color = roof_color
	_distance_on_segment = start_distance
	_advance(0.0)
	add_to_group("city_cars")


func _process(delta: float) -> void:
	if _route.size() < 2:
		return
	_advance(_speed * delta)
	queue_redraw()


func _advance(distance: float) -> void:
	if _route.size() < 2:
		return

	var remaining_distance: float = distance
	var guard: int = 0
	while guard < 128:
		var next_index: int = (_segment_index + 1) % _route.size()
		var segment_length: float = _route[_segment_index].distance_to(_route[next_index])
		if segment_length <= 0.001:
			_segment_index = next_index
			_distance_on_segment = 0.0
			guard += 1
			continue

		var left_on_segment: float = segment_length - _distance_on_segment
		if remaining_distance < left_on_segment:
			_distance_on_segment += remaining_distance
			remaining_distance = 0.0
		else:
			remaining_distance -= left_on_segment
			_segment_index = next_index
			_distance_on_segment = 0.0
			guard += 1

		if remaining_distance <= 0.001:
			break

	var next_point: Vector2 = _route[(_segment_index + 1) % _route.size()]
	var segment: Vector2 = next_point - _route[_segment_index]
	var final_segment_length: float = segment.length()
	if final_segment_length <= 0.001:
		return

	var direction: Vector2 = segment / final_segment_length
	var side: Vector2 = Vector2(-direction.y, direction.x)
	position = _route[_segment_index].lerp(next_point, _distance_on_segment / final_segment_length)
	position += side * _lane_offset
	rotation = direction.angle()


func _draw() -> void:
	# Shadow and body are drawn in the car's local forward direction (+X).
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-15.0, -4.0),
				Vector2(0.0, -9.0),
				Vector2(16.0, -4.0),
				Vector2(17.0, 3.0),
				Vector2(0.0, 8.0),
				Vector2(-16.0, 3.0)
			]
		),
		Color(0.04, 0.08, 0.10, 0.32)
	)

	var outline: Color = Color("#17232c")
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-16.0, -5.0),
				Vector2(-9.0, -9.0),
				Vector2(9.0, -9.0),
				Vector2(16.0, -4.0),
				Vector2(18.0, 0.0),
				Vector2(14.0, 6.0),
				Vector2(-12.0, 6.0),
				Vector2(-18.0, 2.0)
			]
		),
		outline
	)
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-14.0, -4.0),
				Vector2(-8.0, -7.0),
				Vector2(8.0, -7.0),
				Vector2(14.0, -3.0),
				Vector2(14.0, 1.0),
				Vector2(-12.0, 1.0)
			]
		),
		_body_color
	)
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-6.0, -6.0),
				Vector2(-3.0, -8.0),
				Vector2(5.0, -8.0),
				Vector2(9.0, -5.0),
				Vector2(7.0, -2.0),
				Vector2(-6.0, -2.0)
			]
		),
		_roof_color
	)
	draw_rect(Rect2(Vector2(-14.0, -1.0), Vector2(4.0, 2.0)), Color("#f4e6a8"))
	draw_rect(Rect2(Vector2(12.0, -1.0), Vector2(4.0, 2.0)), Color("#f26e5e"))
	draw_rect(Rect2(Vector2(-12.0, 5.0), Vector2(5.0, 3.0)), outline)
	draw_rect(Rect2(Vector2(9.0, 5.0), Vector2(5.0, 3.0)), outline)
