extends Node2D

const HeroPowerCatalog = preload("res://scripts/hero/hero_power_catalog.gd")
const HeroProjectile = preload("res://scripts/hero/hero_projectile.gd")
const HeroBurst = preload("res://scripts/hero/hero_burst.gd")

const BASE_MOVE_SPEED: float = 112.0
const SPEED_MULTIPLIER: float = 2.15
const FLIGHT_MULTIPLIER: float = 1.30
const BEAST_MULTIPLIER: float = 1.18

var _city: Node
var _profile: Dictionary = {}
var _hero_name: String = "Nova"
var _suit_color: Color = Color("#45bcae")
var _cape_color: Color = Color("#e7645d")
var _element: String = "fire"
var _equipped_powers: Array[String] = []
var _virtual_axis: Vector2 = Vector2.ZERO
var _facing_grid: Vector2i = Vector2i(1, 0)
var _last_world_direction: Vector2 = Vector2.RIGHT
var _cooldowns: Dictionary = {}
var _speed_active: bool = false
var _flight_active: bool = false
var _beast_active: bool = false
var _controls_enabled: bool = true
var _strike_cooldown: float = 0.0
var _flight_phase: float = 0.0
var _impact_timer: float = 0.0
var _speed_trail_timer: float = 0.0
var _action_flash: float = 0.0


func _ready() -> void:
	z_index = 3
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(true)
	queue_redraw()


func configure(profile: Dictionary, city: Node) -> void:
	_profile = profile.duplicate(true)
	_city = city
	_hero_name = str(_profile.get("name", "Nova")).strip_edges()
	if _hero_name.is_empty():
		_hero_name = "Nova"
	_suit_color = Color(str(_profile.get("suit_color", "#45bcae")))
	_cape_color = Color(str(_profile.get("cape_color", "#e7645d")))
	_element = str(_profile.get("element", "fire"))
	var requested_powers: Array = _profile.get("powers", [])
	_equipped_powers = HeroPowerCatalog.sanitize_loadout(requested_powers)
	_cooldowns.clear()
	_strike_cooldown = 0.0
	_impact_timer = 0.0
	_action_flash = 0.0
	_speed_active = false
	_flight_active = false
	_beast_active = false
	_virtual_axis = Vector2.ZERO
	queue_redraw()


func set_city(city: Node) -> void:
	_city = city


func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled
	if not enabled:
		_virtual_axis = Vector2.ZERO


func set_virtual_movement(axis: Vector2) -> void:
	_virtual_axis = axis.limit_length(1.0)


func get_hero_name() -> String:
	return _hero_name


func get_equipped_powers() -> Array[String]:
	return _equipped_powers.duplicate()


func has_power(power_id: String) -> bool:
	return _equipped_powers.has(power_id)


func is_moving() -> bool:
	return _get_movement_axis().length_squared() > 0.01


func is_power_active(power_id: String) -> bool:
	match power_id:
		"speed":
			return _speed_active
		"flight":
			return _flight_active
		"beast":
			return _beast_active
	return false


func get_power_cooldown(power_id: String) -> float:
	return maxf(0.0, float(_cooldowns.get(power_id, 0.0)))


func get_strike_cooldown() -> float:
	return maxf(0.0, _strike_cooldown)


func get_status_text() -> String:
	var status: Array[String] = []
	if _flight_active:
		status.append("FLYING")
	if _speed_active:
		status.append("SPEED ON")
	if _beast_active:
		status.append("BEAST FORM")
	if status.is_empty():
		status.append("READY")
	return "%s · %s" % [_hero_name.to_upper(), " · ".join(status)]


func activate_power(power_id: String) -> bool:
	if not _controls_enabled or not has_power(power_id):
		return false
	var is_toggle_power: bool = power_id in ["speed", "flight", "beast"]
	if get_power_cooldown(power_id) > 0.0 and not (is_toggle_power and is_power_active(power_id)):
		return false

	var power: Dictionary = HeroPowerCatalog.get_power(power_id)
	if power.is_empty():
		return false
	match power_id:
		"elemental":
			_launch_elemental()
		"super_strength":
			_activate_strength()
		"speed":
			_speed_active = not _speed_active
		"teleportation":
			if not _teleport_forward():
				return false
		"beast":
			_beast_active = not _beast_active
		"flight":
			_flight_active = not _flight_active
			_spawn_burst(global_position, Color("#a9d2ff"), "teleport", 44.0)
		_:
			return false

	var cooldown: float = float(power.get("cooldown", 0.5))
	if _speed_active and power_id not in ["speed", "flight", "beast"]:
		cooldown *= 0.58
	_cooldowns[power_id] = cooldown
	_action_flash = 0.22
	queue_redraw()
	return true


func perform_strike() -> bool:
	if not _controls_enabled or _strike_cooldown > 0.0:
		return false
	var damage: float = 14.0
	var radius: float = 52.0
	if has_power("super_strength"):
		damage = 24.0
		radius = 64.0
	if _beast_active:
		damage *= 1.65
		radius *= 1.30
	_damage_targets(radius, damage, "impact", true)
	_strike_cooldown = 0.78 * (0.48 if _speed_active else 1.0)
	_impact_timer = 0.22
	_action_flash = 0.18
	queue_redraw()
	return true


func _process(delta: float) -> void:
	for power_id: Variant in _cooldowns.keys():
		_cooldowns[power_id] = maxf(0.0, float(_cooldowns[power_id]) - delta)
	_strike_cooldown = maxf(0.0, _strike_cooldown - delta)
	_impact_timer = maxf(0.0, _impact_timer - delta)
	_action_flash = maxf(0.0, _action_flash - delta)
	_flight_phase += delta * 4.5

	var axis: Vector2 = _get_movement_axis()
	if axis.length_squared() > 0.01:
		axis = axis.limit_length(1.0)
		_update_facing(axis)
		var world_direction: Vector2 = _grid_axis_to_world(axis).normalized()
		_last_world_direction = world_direction
		var multiplier: float = 1.0
		if _speed_active:
			multiplier *= SPEED_MULTIPLIER
		if _flight_active:
			multiplier *= FLIGHT_MULTIPLIER
		if _beast_active:
			multiplier *= BEAST_MULTIPLIER
		_move_by_world_offset(world_direction * BASE_MOVE_SPEED * multiplier * delta)
		if _speed_active:
			_speed_trail_timer -= delta
			if _speed_trail_timer <= 0.0:
				_speed_trail_timer = 0.065
		else:
			_speed_trail_timer = 0.0
	else:
		_speed_trail_timer = 0.0
	queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _controls_enabled or not event.pressed or event.echo:
		return
	var power_slot: int = -1
	match event.keycode:
		KEY_1:
			power_slot = 0
		KEY_2:
			power_slot = 1
		KEY_3:
			power_slot = 2
		KEY_SPACE:
			perform_strike()
			return
	if power_slot >= 0 and power_slot < _equipped_powers.size():
		activate_power(_equipped_powers[power_slot])


func _get_movement_axis() -> Vector2:
	if not _controls_enabled:
		return Vector2.ZERO
	var move_right: bool = Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	var move_left: bool = Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var move_down: bool = Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	var move_up: bool = Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var keyboard_axis := Vector2(
		(1.0 if move_right else 0.0) - (1.0 if move_left else 0.0),
		(1.0 if move_down else 0.0) - (1.0 if move_up else 0.0)
	)
	return (keyboard_axis + _virtual_axis).limit_length(1.0)


func _update_facing(axis: Vector2) -> void:
	if absf(axis.x) >= absf(axis.y):
		_facing_grid = Vector2i(1 if axis.x >= 0.0 else -1, 0)
	else:
		_facing_grid = Vector2i(0, 1 if axis.y >= 0.0 else -1)


func _grid_axis_to_world(axis: Vector2) -> Vector2:
	return Vector2(axis.x - axis.y, (axis.x + axis.y) * 0.25)


func _facing_world_direction() -> Vector2:
	return _grid_axis_to_world(Vector2(_facing_grid)).normalized()


func _move_by_world_offset(offset: Vector2) -> void:
	if _try_move_to(global_position + offset):
		return
	var horizontal_offset := Vector2(offset.x, 0.0)
	var vertical_offset := Vector2(0.0, offset.y)
	var moved: bool = false
	if absf(horizontal_offset.x) > 0.001:
		moved = _try_move_to(global_position + horizontal_offset)
	if absf(vertical_offset.y) > 0.001:
		moved = _try_move_to(global_position + vertical_offset) or moved
	if not moved:
		queue_redraw()


func _try_move_to(candidate: Vector2) -> bool:
	if _city == null or not is_instance_valid(_city):
		global_position = candidate
		return true
	if not bool(_city.call("can_hero_occupy", candidate, _flight_active)):
		return false
	global_position = candidate
	return true


func _launch_elemental() -> void:
	var projectile := HeroProjectile.new()
	projectile.configure(
		global_position + _facing_world_direction() * 22.0,
		_facing_world_direction(),
		_element,
		32.0,
		_city
	)
	if get_parent() != null:
		get_parent().add_child(projectile)


func _activate_strength() -> void:
	_impact_timer = 0.48
	_spawn_burst(global_position, Color("#f2c75c"), "impact", 108.0, 0.42)
	var damage: float = 58.0 if _beast_active else 46.0
	var radius: float = 102.0 if _beast_active else 86.0
	_damage_targets(radius, damage, "impact", false)


func _teleport_forward() -> bool:
	var direction: Vector2 = _facing_world_direction()
	var distance: float = 208.0
	var destination: Vector2 = global_position + direction * distance
	if _city == null or not is_instance_valid(_city):
		_spawn_burst(global_position, Color("#bd9aff"), "teleport", 55.0)
		global_position = destination
		_spawn_burst(global_position, Color("#bd9aff"), "teleport", 55.0)
		return true

	var landing: Vector2 = Vector2.ZERO
	var found_landing: bool = false
	for attempt: int in range(18):
		var candidate_distance: float = distance - float(attempt) * 12.0
		if candidate_distance < 84.0:
			continue
		var candidate: Vector2 = global_position + direction * candidate_distance
		if bool(_city.call("can_hero_occupy", candidate, _flight_active)):
			landing = candidate
			found_landing = true
			break
	if not found_landing:
		return false
	_spawn_burst(global_position, Color("#bd9aff"), "teleport", 55.0)
	global_position = landing
	_spawn_burst(global_position, Color("#bd9aff"), "teleport", 55.0)
	return true


func _damage_targets(radius: float, damage: float, element: String, directional: bool) -> void:
	var aim: Vector2 = _facing_world_direction()
	for target: Node2D in get_tree().get_nodes_in_group("hero_targets"):
		if not is_instance_valid(target) or not target.visible:
			continue
		var offset: Vector2 = target.global_position - global_position
		if offset.length() > radius:
			continue
		if directional and offset.length_squared() > 1.0 and offset.normalized().dot(aim) < -0.25:
			continue
		target.call("take_damage", damage, aim, element)


func _spawn_burst(
	world_position: Vector2, tint: Color, kind: String, radius: float, duration: float = 0.38
) -> void:
	if get_parent() == null:
		return
	var burst := HeroBurst.new()
	burst.configure(tint, radius, kind, duration)
	get_parent().add_child(burst)
	burst.global_position = world_position


func _draw() -> void:
	var suit: Color = _suit_color
	var cape: Color = _cape_color
	if _flight_active:
		var shadow_tint := Color(0.02, 0.04, 0.05, 0.32)
		draw_set_transform(Vector2(0.0, 18.0), 0.0, Vector2(1.55, 0.65))
		draw_circle(Vector2.ZERO, 11.0, shadow_tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_set_transform(Vector2(0.0, 13.0), 0.0, Vector2(1.4, 0.62))
		draw_circle(Vector2.ZERO, 10.0, Color(0.02, 0.04, 0.05, 0.34))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if _speed_active and is_moving():
		var trail_color: Color = suit
		trail_color.a = 0.42
		for trail_index: int in range(3):
			var trail_offset: Vector2 = -_last_world_direction * float(22 + trail_index * 12)
			draw_line(
				trail_offset, trail_offset - _last_world_direction * 10.0, trail_color, 3.0, true
			)

	var hover_height: float = 0.0
	if _flight_active:
		hover_height = 9.0 + sin(_flight_phase) * 3.0
	var body_scale: float = 1.24 if _beast_active else 1.0
	draw_set_transform(Vector2(0.0, -hover_height), 0.0, Vector2.ONE * body_scale)
	if _flight_active:
		var aura := Color("#a9d2ff")
		aura.a = 0.75
		draw_arc(
			Vector2(0.0, -13.0), 25.0 + sin(_flight_phase) * 2.0, 0.0, TAU, 28, aura, 2.0, true
		)

	var outline: Color = Color("#202b37")
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-6.0, -15.0),
				Vector2(-16.0, -4.0),
				Vector2(-10.0, 8.0),
				Vector2(0.0, 3.0),
				Vector2(10.0, 8.0),
				Vector2(16.0, -4.0),
				Vector2(6.0, -15.0),
			]
		),
		outline
	)
	draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(-5.0, -14.0),
				Vector2(-12.0, -4.0),
				Vector2(-8.0, 4.0),
				Vector2(0.0, 0.0),
				Vector2(8.0, 4.0),
				Vector2(12.0, -4.0),
				Vector2(5.0, -14.0),
			]
		),
		suit
	)
	draw_rect(Rect2(Vector2(-10.0, -2.0), Vector2(20.0, 3.0)), Color("#f4df9b"))
	draw_line(Vector2(-9.0, 5.0), Vector2(-12.0, 13.0), outline, 6.0, true)
	draw_line(Vector2(9.0, 5.0), Vector2(12.0, 13.0), outline, 6.0, true)
	draw_line(Vector2(-12.0, 13.0), Vector2(-16.0, 14.0), suit, 4.0, true)
	draw_line(Vector2(12.0, 13.0), Vector2(16.0, 14.0), suit, 4.0, true)
	draw_line(Vector2(-12.0, -10.0), Vector2(-17.0, -3.0), outline, 6.0, true)
	draw_line(Vector2(12.0, -10.0), Vector2(17.0, -3.0), outline, 6.0, true)
	draw_line(Vector2(-11.0, -10.0), Vector2(-15.0, -4.0), suit.lightened(0.12), 3.0, true)
	draw_line(Vector2(11.0, -10.0), Vector2(15.0, -4.0), suit.lightened(0.12), 3.0, true)
	draw_circle(Vector2(0.0, -20.0), 9.0, outline)
	draw_circle(Vector2(0.0, -20.0), 7.0, Color("#d9a782"))
	draw_rect(Rect2(Vector2(-7.0, -26.0), Vector2(14.0, 3.0)), cape.darkened(0.12))
	draw_circle(Vector2(-3.0, -21.0), 1.4, Color("#263a4b"))
	draw_circle(Vector2(3.0, -21.0), 1.4, Color("#263a4b"))
	if _beast_active:
		draw_colored_polygon(
			PackedVector2Array([Vector2(-7.0, -26.0), Vector2(-12.0, -36.0), Vector2(-1.0, -29.0)]),
			Color("#b85a46")
		)
		draw_colored_polygon(
			PackedVector2Array([Vector2(7.0, -26.0), Vector2(12.0, -36.0), Vector2(1.0, -29.0)]),
			Color("#b85a46")
		)
		draw_line(Vector2(-10.0, 2.0), Vector2(-15.0, 8.0), Color("#f6d4a3"), 2.0, true)
		draw_line(Vector2(10.0, 2.0), Vector2(15.0, 8.0), Color("#f6d4a3"), 2.0, true)
	if _action_flash > 0.0:
		var flash := Color("#fff0b2")
		flash.a = _action_flash / 0.22
		draw_arc(Vector2(0.0, -11.0), 24.0, 0.0, TAU, 24, flash, 2.5, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if _impact_timer > 0.0:
		var progress: float = 1.0 - _impact_timer / 0.48
		var impact_color := Color("#f2c75c")
		impact_color.a = 1.0 - progress
		draw_arc(Vector2.ZERO, lerpf(22.0, 102.0, progress), 0.0, TAU, 36, impact_color, 3.0, true)
