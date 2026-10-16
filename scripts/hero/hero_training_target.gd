extends Node2D

var _max_health: float = 100.0
var _health: float = 100.0
var _respawn_timer: float = 0.0
var _flash_timer: float = 0.0
var _burn_timer: float = 0.0
var _burn_tick: float = 0.0
var _freeze_timer: float = 0.0
var _shock_timer: float = 0.0
var _knockback: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("hero_targets")
	z_index = 4
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(true)


func take_damage(
	amount: float, direction: Vector2 = Vector2.ZERO, element: String = "impact"
) -> void:
	if not visible or amount <= 0.0:
		return
	_health = maxf(0.0, _health - amount)
	_flash_timer = 0.18
	_knockback = direction.normalized() * minf(amount * 0.36, 20.0)
	if element == "fire":
		_burn_timer = 2.0
		_burn_tick = 0.0
	elif element == "ice":
		_freeze_timer = 1.6
	elif element == "lightning":
		_shock_timer = 0.55
	if _health <= 0.0:
		visible = false
		_respawn_timer = 4.0
		_burn_timer = 0.0
		_freeze_timer = 0.0
		_shock_timer = 0.0
		_knockback = Vector2.ZERO
	queue_redraw()


func get_health() -> float:
	return _health


func get_max_health() -> float:
	return _max_health


func is_destroyed() -> bool:
	return not visible


func get_effect_status() -> String:
	if _burn_timer > 0.0:
		return "burning"
	if _freeze_timer > 0.0:
		return "frozen"
	if _shock_timer > 0.0:
		return "shocked"
	return "normal"


func reset_target() -> void:
	_health = _max_health
	visible = true
	_burn_timer = 0.0
	_burn_tick = 0.0
	_freeze_timer = 0.0
	_shock_timer = 0.0
	_flash_timer = 0.0
	_knockback = Vector2.ZERO
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		_respawn_timer = maxf(0.0, _respawn_timer - delta)
		if _respawn_timer <= 0.0:
			_health = _max_health
			visible = true
		queue_redraw()
		return

	_flash_timer = maxf(0.0, _flash_timer - delta)
	_freeze_timer = maxf(0.0, _freeze_timer - delta)
	_shock_timer = maxf(0.0, _shock_timer - delta)
	_burn_timer = maxf(0.0, _burn_timer - delta)
	if _burn_timer > 0.0:
		_burn_tick += delta
		if _burn_tick >= 0.5:
			_burn_tick -= 0.5
			_health = maxf(0.0, _health - 4.0)
			if _health <= 0.0:
				visible = false
				_respawn_timer = 4.0
				_burn_timer = 0.0
				_freeze_timer = 0.0
				_shock_timer = 0.0
				_knockback = Vector2.ZERO
	_knockback = _knockback.move_toward(Vector2.ZERO, delta * 48.0)
	position += _knockback * delta
	queue_redraw()


func _draw() -> void:
	var wood: Color = Color("#bb8154")
	var outline: Color = Color("#342b33")
	if _freeze_timer > 0.0:
		wood = Color("#75cde5")
	elif _burn_timer > 0.0:
		wood = Color("#e67d46")
	elif _shock_timer > 0.0:
		wood = Color("#f3d35f")
	if _flash_timer > 0.0:
		wood = wood.lightened(0.45)

	draw_set_transform(Vector2(0.0, 4.0), 0.0, Vector2(1.7, 0.7))
	draw_circle(Vector2.ZERO, 11.0, Color(0.02, 0.04, 0.05, 0.36))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_line(Vector2(0.0, -8.0), Vector2(-12.0, 8.0), outline, 7.0, true)
	draw_line(Vector2(0.0, -8.0), Vector2(12.0, 8.0), outline, 7.0, true)
	draw_line(Vector2(-12.0, 8.0), Vector2(-16.0, 13.0), outline, 5.0, true)
	draw_line(Vector2(12.0, 8.0), Vector2(16.0, 13.0), outline, 5.0, true)
	draw_rect(Rect2(Vector2(-14.0, -33.0), Vector2(28.0, 21.0)), outline)
	draw_rect(Rect2(Vector2(-11.0, -30.0), Vector2(22.0, 16.0)), wood)
	draw_rect(Rect2(Vector2(-18.0, -28.0), Vector2(6.0, 18.0)), outline)
	draw_rect(Rect2(Vector2(12.0, -28.0), Vector2(6.0, 18.0)), outline)
	draw_circle(Vector2(0.0, -40.0), 10.0, outline)
	draw_circle(Vector2(0.0, -40.0), 7.0, Color("#d7a675"))
	draw_circle(Vector2(-3.0, -41.0), 1.5, Color("#2b3338"))
	draw_circle(Vector2(3.0, -41.0), 1.5, Color("#2b3338"))
	draw_rect(Rect2(Vector2(-18.0, -47.0), Vector2(36.0, 4.0)), Color("#27323a"))
	draw_rect(
		Rect2(Vector2(-17.0, -46.0), Vector2(34.0 * _health / _max_health, 2.0)), Color("#74d7aa")
	)
	if _burn_timer > 0.0:
		draw_circle(Vector2(0.0, -57.0), 3.0, Color("#ff9b4c"))
	elif _freeze_timer > 0.0:
		draw_line(Vector2(-5.0, -55.0), Vector2(5.0, -55.0), Color("#b5f0ff"), 2.0)
	elif _shock_timer > 0.0:
		draw_line(Vector2(-4.0, -58.0), Vector2(1.0, -53.0), Color("#fff29a"), 2.0)
		draw_line(Vector2(1.0, -53.0), Vector2(-2.0, -49.0), Color("#fff29a"), 2.0)
