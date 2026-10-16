extends Node2D

## A procedural pedestrian with a named, point-to-point daily destination.
enum JourneyPhase { OUTBOUND, DESTINATION_PAUSE, RETURNING, HOME_PAUSE }

var _route: PackedVector2Array = PackedVector2Array()
var _route_length: float = 0.0
var _speed: float = 46.0
var _segment_index: int = 0
var _distance_on_segment: float = 0.0
var _journey_phase: JourneyPhase = JourneyPhase.OUTBOUND
var _pause_timer: float = 0.0
var _destination_name: String = "Corner shop"
var _destination_kind: String = "local"
var _shirt_color: Color = Color("#38b8a0")
var _trouser_color: Color = Color("#27364e")
var _skin_color: Color = Color("#f1bb8a")
var _hair_color: Color = Color("#392e35")
var _walk_phase: float = 0.0
var _facing: float = 1.0
var _character_scale: float = 1.0


func _ready() -> void:
	var viewport_notifier := VisibleOnScreenNotifier2D.new()
	viewport_notifier.name = "ViewportActivity"
	viewport_notifier.rect = Rect2(Vector2(-28.0, -66.0), Vector2(56.0, 76.0))
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
	start_distance: float,
	neighborhood_art: bool = false,
	destination_name: String = "Corner shop",
	destination_kind: String = "local"
) -> void:
	_route = route
	_speed = speed
	_destination_name = destination_name
	_destination_kind = destination_kind
	_shirt_color = shirt_color
	_trouser_color = trouser_color
	_skin_color = skin_color
	_hair_color = hair_color
	_character_scale = 1.55 if neighborhood_art else 1.0
	_recalculate_route_length()
	_set_cursor_at_distance(start_distance)
	_set_position_from_cursor()
	add_to_group("city_citizens")


func _process(delta: float) -> void:
	if _route.size() < 2:
		return
	if (
		_journey_phase == JourneyPhase.DESTINATION_PAUSE
		or _journey_phase == JourneyPhase.HOME_PAUSE
	):
		_pause_timer = maxf(0.0, _pause_timer - delta)
		_walk_phase += delta * 2.0
		if _pause_timer <= 0.0:
			_journey_phase = (
				JourneyPhase.RETURNING
				if _journey_phase == JourneyPhase.DESTINATION_PAUSE
				else JourneyPhase.OUTBOUND
			)
		queue_redraw()
		return

	_walk_phase += delta * 9.0
	if _journey_phase == JourneyPhase.OUTBOUND:
		_advance_outbound(_speed * delta)
	else:
		_advance_homebound(_speed * delta)
	queue_redraw()


func get_character_scale() -> float:
	return _character_scale


func get_destination_name() -> String:
	return _destination_name


func get_destination_kind() -> String:
	return _destination_kind


func get_route_length() -> float:
	return _route_length


func get_route_point_count() -> int:
	return _route.size()


func get_journey_phase_name() -> String:
	match _journey_phase:
		JourneyPhase.OUTBOUND:
			return "to_destination"
		JourneyPhase.DESTINATION_PAUSE:
			return "at_destination"
		JourneyPhase.RETURNING:
			return "returning_home"
		_:
			return "at_home"


func is_heading_to_destination() -> bool:
	return _journey_phase == JourneyPhase.OUTBOUND


func _recalculate_route_length() -> void:
	_route_length = 0.0
	if _route.size() < 2:
		return
	for index: int in range(_route.size() - 1):
		_route_length += _route[index].distance_to(_route[index + 1])


func _set_cursor_at_distance(distance: float) -> void:
	_segment_index = 0
	_distance_on_segment = 0.0
	if _route.size() < 2:
		return

	var remaining_distance: float = clampf(distance, 0.0, _route_length)
	for index: int in range(_route.size() - 1):
		var segment_length: float = _route[index].distance_to(_route[index + 1])
		if remaining_distance <= segment_length or index == _route.size() - 2:
			_segment_index = index
			_distance_on_segment = minf(remaining_distance, segment_length)
			return
		remaining_distance -= segment_length


func _advance_outbound(distance: float) -> void:
	var remaining_distance: float = distance
	var guard: int = 0
	while remaining_distance > 0.001 and guard < _route.size() + 2:
		var segment_length: float = _route[_segment_index].distance_to(_route[_segment_index + 1])
		var left_on_segment: float = segment_length - _distance_on_segment
		if remaining_distance < left_on_segment:
			_distance_on_segment += remaining_distance
			remaining_distance = 0.0
		else:
			remaining_distance -= left_on_segment
			if _segment_index < _route.size() - 2:
				_segment_index += 1
				_distance_on_segment = 0.0
			else:
				_distance_on_segment = segment_length
				_journey_phase = JourneyPhase.DESTINATION_PAUSE
				_pause_timer = randf_range(3.0, 7.0)
				remaining_distance = 0.0
		guard += 1
	_set_position_from_cursor()


func _advance_homebound(distance: float) -> void:
	var remaining_distance: float = distance
	var guard: int = 0
	while remaining_distance > 0.001 and guard < _route.size() + 2:
		var segment_length: float = _route[_segment_index].distance_to(_route[_segment_index + 1])
		if remaining_distance < _distance_on_segment:
			_distance_on_segment -= remaining_distance
			remaining_distance = 0.0
		else:
			remaining_distance -= _distance_on_segment
			if _segment_index > 0:
				_segment_index -= 1
				_distance_on_segment = _route[_segment_index].distance_to(
					_route[_segment_index + 1]
				)
			else:
				_distance_on_segment = 0.0
				_journey_phase = JourneyPhase.HOME_PAUSE
				_pause_timer = randf_range(3.0, 8.0)
				remaining_distance = 0.0
		guard += 1
	_set_position_from_cursor()


func _set_position_from_cursor() -> void:
	if _route.size() < 2 or _segment_index >= _route.size() - 1:
		return
	var start: Vector2 = _route[_segment_index]
	var finish: Vector2 = _route[_segment_index + 1]
	var segment_length: float = start.distance_to(finish)
	if segment_length <= 0.001:
		position = start
		return
	var direction: Vector2 = finish - start
	if _journey_phase == JourneyPhase.RETURNING or _journey_phase == JourneyPhase.HOME_PAUSE:
		direction = -direction
	if absf(direction.x) > 0.01:
		_facing = signf(direction.x)
	position = start.lerp(finish, clampf(_distance_on_segment / segment_length, 0.0, 1.0))


func _destination_marker_color() -> Color:
	match _destination_kind:
		"hero_association":
			return Color("#f0ca66")
		"park":
			return Color("#91d18b")
		"station", "harbor":
			return Color("#86c9d2")
		_:
			return Color("#e3a47b")


func _draw_destination_marker(marker_y: float) -> void:
	if _journey_phase != JourneyPhase.OUTBOUND:
		return
	var outline: Color = Color("#17232c")
	draw_rect(Rect2(Vector2(-3.0, marker_y), Vector2(7.0, 7.0)), outline)
	draw_rect(Rect2(Vector2(-2.0, marker_y + 1.0), Vector2(5.0, 5.0)), _destination_marker_color())
	if _destination_kind == "hero_association":
		draw_rect(Rect2(Vector2(-1.0, marker_y + 2.0), Vector2(3.0, 3.0)), Color("#fff1c1"))


func _draw() -> void:
	if _character_scale > 1.0:
		_draw_neighborhood_pedestrian()
	else:
		_draw_original_pedestrian()


func _draw_neighborhood_pedestrian() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * _character_scale)
	var movement_weight: float = (
		0.0
		if (
			_journey_phase == JourneyPhase.DESTINATION_PAUSE
			or _journey_phase == JourneyPhase.HOME_PAUSE
		)
		else 1.0
	)
	var bob: float = absf(sin(_walk_phase)) * 1.2 * movement_weight
	var leg_swing: float = sin(_walk_phase) * 2.0 * movement_weight
	var arm_swing: float = cos(_walk_phase) * 1.4 * movement_weight
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
	_draw_destination_marker(-39.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_original_pedestrian() -> void:
	var movement_weight: float = (
		0.0
		if (
			_journey_phase == JourneyPhase.DESTINATION_PAUSE
			or _journey_phase == JourneyPhase.HOME_PAUSE
		)
		else 1.0
	)
	var bob: float = absf(sin(_walk_phase)) * 1.4 * movement_weight
	var leg_swing: float = sin(_walk_phase) * 2.0 * movement_weight
	var outline: Color = Color("#17232c")
	draw_colored_polygon(
		PackedVector2Array(
			[Vector2(-8.0, 1.0), Vector2(0.0, -2.0), Vector2(8.0, 1.0), Vector2(0.0, 4.0)]
		),
		Color(0.06, 0.10, 0.12, 0.35)
	)
	draw_rect(Rect2(Vector2(-4.0, -10.0 + bob), Vector2(8.0, 8.0)), outline)
	draw_rect(Rect2(Vector2(-3.0, -9.0 + bob), Vector2(6.0, 7.0)), _trouser_color)
	draw_rect(Rect2(Vector2(-3.0 + leg_swing, -3.0 + bob), Vector2(3.0, 6.0)), outline)
	draw_rect(Rect2(Vector2(1.0 - leg_swing, -3.0 + bob), Vector2(3.0, 6.0)), outline)
	draw_rect(
		Rect2(Vector2(-2.0 + leg_swing, -2.0 + bob), Vector2(2.0, 4.0)),
		_trouser_color.lightened(0.08)
	)
	draw_rect(
		Rect2(Vector2(2.0 - leg_swing, -2.0 + bob), Vector2(2.0, 4.0)),
		_trouser_color.lightened(0.08)
	)
	draw_rect(Rect2(Vector2(-5.0, -19.0 + bob), Vector2(10.0, 11.0)), outline)
	draw_rect(Rect2(Vector2(-4.0, -18.0 + bob), Vector2(8.0, 9.0)), _shirt_color)
	draw_rect(Rect2(Vector2(-3.0, -27.0 + bob), Vector2(7.0, 8.0)), outline)
	draw_rect(Rect2(Vector2(-2.0, -26.0 + bob), Vector2(5.0, 6.0)), _skin_color)
	draw_rect(Rect2(Vector2(-3.0, -28.0 + bob), Vector2(7.0, 3.0)), _hair_color)
	var eye_x: float = 1.0 if _facing > 0.0 else -2.0
	draw_rect(Rect2(Vector2(-3.0, -17.0 + bob), Vector2(2.0, 2.0)), _shirt_color.lightened(0.28))
	draw_rect(Rect2(Vector2(eye_x, -24.0 + bob), Vector2(1.0, 1.0)), outline)
	_draw_destination_marker(-34.0)
