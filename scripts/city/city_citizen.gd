extends Node2D

## A small procedural pedestrian that loops around a city-block sidewalk.
var _route: PackedVector2Array = PackedVector2Array()
var _speed: float = 46.0
var _segment_index: int = 0
var _distance_on_segment: float = 0.0
var _shirt_color: Color = Color("#38b8a0")
var _trouser_color: Color = Color("#27364e")
var _skin_color: Color = Color("#f1bb8a")
var _hair_color: Color = Color("#392e35")
var _walk_phase: float = 0.0
var _facing: float = 1.0


func _ready() -> void:
	var viewport_notifier := VisibleOnScreenNotifier2D.new()
	viewport_notifier.name = "ViewportActivity"
	viewport_notifier.rect = Rect2(Vector2(-24.0, -58.0), Vector2(48.0, 64.0))
	viewport_notifier.screen_entered.connect(_on_screen_entered)
	viewport_notifier.screen_exited.connect(_on_screen_exited)
	add_child(viewport_notifier)
	set_process(false)


func _on_screen_entered() -> void:
	set_process(true)


func _on_screen_exited() -> void:
	set_process(false)


func configure(
	route: PackedVector2Array,
	speed: float,
	shirt_color: Color,
	trouser_color: Color,
	skin_color: Color,
	hair_color: Color,
	start_distance: float
) -> void:
	_route = route
	_speed = speed
	_shirt_color = shirt_color
	_trouser_color = trouser_color
	_skin_color = skin_color
	_hair_color = hair_color
	_distance_on_segment = start_distance
	_advance(0.0)
	add_to_group("city_citizens")


func _process(delta: float) -> void:
	if _route.size() < 2:
		return
	_walk_phase += delta * 9.0
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
	var direction: Vector2 = next_point - _route[_segment_index]
	if absf(direction.x) > 0.01:
		_facing = signf(direction.x)
	var length: float = _route[_segment_index].distance_to(next_point)
	if length > 0.001:
		position = _route[_segment_index].lerp(next_point, _distance_on_segment / length)


func _draw() -> void:
	const CHARACTER_SCALE: float = 1.55
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * CHARACTER_SCALE)
	var bob: float = absf(sin(_walk_phase)) * 1.2
	var leg_swing: float = sin(_walk_phase) * 2.0
	var arm_swing: float = cos(_walk_phase) * 1.4
	var outline: Color = Color("#17232c")
	var shadow: Color = Color(0.06, 0.10, 0.12, 0.32)

	# Chunky silhouette and animated limbs make passers-by readable at phone zoom.
	draw_colored_polygon(
		PackedVector2Array(
			[Vector2(-8.0, 2.0), Vector2(0.0, -2.0), Vector2(9.0, 2.0), Vector2(0.0, 6.0)]
		),
		shadow
	)
	draw_rect(Rect2(Vector2(-4.0, -10.0 + bob), Vector2(8.0, 8.0)), outline)
	draw_rect(Rect2(Vector2(-3.0, -9.0 + bob), Vector2(6.0, 7.0)), _trouser_color)
	draw_rect(Rect2(Vector2(-4.0 + leg_swing, -3.0 + bob), Vector2(4.0, 7.0)), outline)
	draw_rect(Rect2(Vector2(0.0 - leg_swing, -3.0 + bob), Vector2(4.0, 7.0)), outline)
	draw_rect(
		Rect2(Vector2(-3.0 + leg_swing, -2.0 + bob), Vector2(3.0, 5.0)),
		_trouser_color.lightened(0.12)
	)
	draw_rect(
		Rect2(Vector2(1.0 - leg_swing, -2.0 + bob), Vector2(3.0, 5.0)),
		_trouser_color.lightened(0.06)
	)
	draw_rect(Rect2(Vector2(-5.0 + leg_swing, 2.0 + bob), Vector2(5.0, 2.0)), outline)
	draw_rect(Rect2(Vector2(0.0 - leg_swing, 2.0 + bob), Vector2(5.0, 2.0)), outline)

	# A small backpack and swinging arms give each person a stronger 3D silhouette.
	var backpack_x: float = -7.0 if _facing > 0.0 else 4.0
	draw_rect(Rect2(Vector2(backpack_x, -18.0 + bob), Vector2(4.0, 9.0)), outline)
	draw_rect(Rect2(Vector2(backpack_x + 1.0, -17.0 + bob), Vector2(2.0, 6.0)), Color("#82684e"))
	draw_rect(Rect2(Vector2(-7.0, -17.0 + bob + arm_swing), Vector2(4.0, 10.0)), outline)
	draw_rect(
		Rect2(Vector2(-6.0, -16.0 + bob + arm_swing), Vector2(2.0, 8.0)),
		_shirt_color.darkened(0.12)
	)
	draw_rect(Rect2(Vector2(3.0, -17.0 + bob - arm_swing), Vector2(4.0, 10.0)), outline)
	draw_rect(
		Rect2(Vector2(4.0, -16.0 + bob - arm_swing), Vector2(2.0, 8.0)),
		_shirt_color.lightened(0.04)
	)

	var torso_points := PackedVector2Array(
		[
			Vector2(-4.0, -20.0 + bob),
			Vector2(4.0, -20.0 + bob),
			Vector2(6.0, -17.0 + bob),
			Vector2(5.0, -9.0 + bob),
			Vector2(-5.0, -9.0 + bob),
			Vector2(-6.0, -17.0 + bob),
		]
	)
	draw_colored_polygon(torso_points, outline)
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-3.0, -19.0 + bob),
				Vector2(3.0, -19.0 + bob),
				Vector2(4.0, -16.0 + bob),
				Vector2(4.0, -10.0 + bob),
				Vector2(-4.0, -10.0 + bob),
				Vector2(-5.0, -16.0 + bob),
			]
		),
		_shirt_color
	)
	draw_rect(Rect2(Vector2(-1.0, -18.0 + bob), Vector2(2.0, 5.0)), _shirt_color.lightened(0.30))
	draw_rect(Rect2(Vector2(-4.0, -11.0 + bob), Vector2(8.0, 2.0)), _trouser_color.darkened(0.04))

	# Larger head, hair shape and eye read clearly without turning pedestrians into heroes.
	draw_rect(Rect2(Vector2(-4.0, -29.0 + bob), Vector2(9.0, 10.0)), outline)
	draw_rect(Rect2(Vector2(-3.0, -28.0 + bob), Vector2(7.0, 8.0)), _skin_color)
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-4.0, -27.0 + bob),
				Vector2(-3.0, -31.0 + bob),
				Vector2(2.0, -32.0 + bob),
				Vector2(5.0, -29.0 + bob),
				Vector2(4.0, -26.0 + bob),
				Vector2(1.0, -28.0 + bob),
				Vector2(-2.0, -26.0 + bob),
			]
		),
		_hair_color
	)
	var eye_x: float = 1.0 if _facing > 0.0 else -2.0
	draw_rect(Rect2(Vector2(eye_x, -24.0 + bob), Vector2(1.5, 1.5)), outline)
	draw_rect(Rect2(Vector2(-3.0, -23.0 + bob), Vector2(2.0, 1.0)), _skin_color.lightened(0.24))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
