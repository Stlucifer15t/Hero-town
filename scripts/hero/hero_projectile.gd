extends Node2D

const HeroPowerCatalog = preload("res://scripts/hero/hero_power_catalog.gd")
const HeroBurst = preload("res://scripts/hero/hero_burst.gd")

var _direction: Vector2 = Vector2.RIGHT
var _element: String = "fire"
var _damage: float = 28.0
var _speed: float = 430.0
var _remaining_range: float = 480.0
var _city: Node
var _tint: Color = Color("#ff824b")


func configure(
	origin: Vector2, direction: Vector2, element: String, damage: float, city: Node = null
) -> void:
	global_position = origin
	_direction = direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	_element = element
	_damage = damage
	_city = city
	_tint = Color(str(HeroPowerCatalog.get_element(element)["color"]))
	z_index = 5
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var travel: Vector2 = _direction * _speed * delta
	global_position += travel
	_remaining_range -= travel.length()
	if _city != null and is_instance_valid(_city):
		if not bool(_city.call("can_hero_occupy", global_position, true)):
			queue_free()
			return

	var hit_target: Node2D
	for target: Node2D in get_tree().get_nodes_in_group("hero_targets"):
		if not is_instance_valid(target) or not target.visible:
			continue
		if target.global_position.distance_squared_to(global_position) <= 28.0 * 28.0:
			hit_target = target
			break
	if hit_target != null:
		_apply_hit(hit_target)
		queue_free()
		return
	if _remaining_range <= 0.0:
		queue_free()
		return
	queue_redraw()


func _apply_hit(target: Node2D) -> void:
	target.call("take_damage", _damage, _direction, _element)
	if _element == "lightning":
		var nearest_target: Node2D
		var nearest_distance: float = 132.0
		for candidate: Node2D in get_tree().get_nodes_in_group("hero_targets"):
			if candidate == target or not is_instance_valid(candidate) or not candidate.visible:
				continue
			var distance: float = candidate.global_position.distance_to(target.global_position)
			if distance < nearest_distance:
				nearest_target = candidate
				nearest_distance = distance
		if nearest_target != null:
			nearest_target.call("take_damage", _damage * 0.62, _direction, "lightning")

	var burst := HeroBurst.new()
	burst.configure(_tint, 42.0, "impact", 0.24)
	get_parent().add_child(burst)
	burst.global_position = global_position


func _draw() -> void:
	var tail: Vector2 = -_direction * 20.0
	var tail_tint: Color = _tint
	tail_tint.a *= 0.55
	draw_line(tail, Vector2.ZERO, tail_tint, 9.0, true)
	draw_line(tail * 0.72, Vector2.ZERO, _tint, 4.0, true)
	if _element == "lightning":
		draw_line(Vector2(-3.0, 6.0), Vector2(4.0, -1.0), Color.WHITE, 2.0, true)
		draw_line(Vector2(4.0, -1.0), Vector2(-1.0, -5.0), Color.WHITE, 2.0, true)
	else:
		draw_circle(Vector2.ZERO, 6.5, _tint)
		draw_circle(Vector2.ZERO, 2.5, Color.WHITE)
