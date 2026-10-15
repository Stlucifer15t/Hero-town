extends Node2D

## A small procedural vehicle moving continuously along a closed city street route.
var _route: PackedVector2Array = PackedVector2Array()
var _speed: float = 150.0
var _segment_index: int = 0
var _distance_on_segment: float = 0.0
var _lane_offset: float = 0.0
var _body_color: Color = Color("#e75c57")
var _roof_color: Color = Color("#f4d889")
var _vehicle_type: int = 0


func configure(
	route: PackedVector2Array,
	speed: float,
	lane_offset: float,
	body_color: Color,
	roof_color: Color,
	start_distance: float,
	vehicle_type: int = 0
) -> void:
	_route = route
	_speed = speed
	_lane_offset = lane_offset
	_body_color = body_color
	_roof_color = roof_color
	_vehicle_type = vehicle_type
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
	match _vehicle_type:
		2:
			_draw_bus()
		3:
			_draw_delivery_van()
		_:
			_draw_sedan()


func _draw_sedan() -> void:
	var outline: Color = Color("#17232c")
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
	if _vehicle_type == 1:
		draw_rect(Rect2(Vector2(-3.0, -12.0), Vector2(8.0, 3.0)), Color("#243442"))
		draw_rect(Rect2(Vector2(-2.0, -11.0), Vector2(6.0, 1.0)), Color("#f8e2a5"))
		draw_rect(Rect2(Vector2(-12.0, 2.0), Vector2(24.0, 2.0)), Color("#f6cf52"))


func _draw_bus() -> void:
	var outline: Color = Color("#17232c")
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-24.0, -4.0),
				Vector2(0.0, -11.0),
				Vector2(24.0, -4.0),
				Vector2(25.0, 4.0),
				Vector2(0.0, 11.0),
				Vector2(-24.0, 4.0),
			]
		),
		Color(0.04, 0.08, 0.10, 0.34)
	)
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-23.0, -8.0),
				Vector2(-16.0, -12.0),
				Vector2(17.0, -12.0),
				Vector2(23.0, -7.0),
				Vector2(25.0, 0.0),
				Vector2(19.0, 8.0),
				Vector2(-18.0, 8.0),
				Vector2(-25.0, 3.0),
			]
		),
		outline
	)
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-21.0, -6.0),
				Vector2(-15.0, -10.0),
				Vector2(15.0, -10.0),
				Vector2(21.0, -6.0),
				Vector2(21.0, 2.0),
				Vector2(-19.0, 2.0),
			]
		),
		_body_color
	)
	for window_index: int in range(5):
		var window_x: float = -15.0 + float(window_index) * 7.0
		draw_rect(Rect2(Vector2(window_x, -8.0), Vector2(5.0, 6.0)), outline)
		draw_rect(Rect2(Vector2(window_x + 1.0, -7.0), Vector2(3.0, 4.0)), _roof_color)
	draw_rect(Rect2(Vector2(-22.0, -1.0), Vector2(42.0, 3.0)), Color("#f2ca59"))
	draw_rect(Rect2(Vector2(-18.0, 7.0), Vector2(7.0, 4.0)), outline)
	draw_rect(Rect2(Vector2(12.0, 7.0), Vector2(7.0, 4.0)), outline)
	draw_rect(Rect2(Vector2(-23.0, -3.0), Vector2(3.0, 3.0)), Color("#f7e3a3"))
	draw_rect(Rect2(Vector2(22.0, -3.0), Vector2(3.0, 3.0)), Color("#f26e5e"))


func _draw_delivery_van() -> void:
	var outline: Color = Color("#17232c")
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-19.0, -5.0),
				Vector2(4.0, -10.0),
				Vector2(19.0, -5.0),
				Vector2(20.0, 4.0),
				Vector2(2.0, 9.0),
				Vector2(-20.0, 3.0),
			]
		),
		Color(0.04, 0.08, 0.10, 0.34)
	)
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-19.0, -7.0),
				Vector2(-13.0, -11.0),
				Vector2(9.0, -11.0),
				Vector2(18.0, -5.0),
				Vector2(20.0, 2.0),
				Vector2(14.0, 8.0),
				Vector2(-14.0, 8.0),
				Vector2(-20.0, 3.0),
			]
		),
		outline
	)
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-17.0, -5.0),
				Vector2(-12.0, -9.0),
				Vector2(7.0, -9.0),
				Vector2(15.0, -4.0),
				Vector2(16.0, 2.0),
				Vector2(-16.0, 2.0),
			]
		),
		_body_color
	)
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-6.0, -8.0),
				Vector2(7.0, -8.0),
				Vector2(14.0, -4.0),
				Vector2(5.0, -3.0),
				Vector2(-6.0, -4.0),
			]
		),
		_roof_color
	)
	draw_rect(Rect2(Vector2(-12.0, 2.0), Vector2(17.0, 3.0)), _roof_color.darkened(0.10))
	draw_rect(Rect2(Vector2(-14.0, 7.0), Vector2(7.0, 4.0)), outline)
	draw_rect(Rect2(Vector2(10.0, 7.0), Vector2(7.0, 4.0)), outline)
	draw_rect(Rect2(Vector2(-18.0, -2.0), Vector2(3.0, 3.0)), Color("#f7e3a3"))
	draw_rect(Rect2(Vector2(17.0, -2.0), Vector2(3.0, 3.0)), Color("#f26e5e"))
