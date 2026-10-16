extends Node2D

var _tint: Color = Color.WHITE
var _max_radius: float = 56.0
var _duration: float = 0.38
var _life: float = 0.38
var _kind: String = "impact"


func configure(
	tint: Color, max_radius: float, kind: String = "impact", duration: float = 0.38
) -> void:
	_tint = tint
	_max_radius = max_radius
	_kind = kind
	_duration = maxf(duration, 0.05)
	_life = _duration
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_life = maxf(0.0, _life - delta)
	if _life <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress: float = 1.0 - _life / _duration
	var fade: float = 1.0 - progress
	var radius: float = lerpf(8.0, _max_radius, progress)
	var tint: Color = _tint
	tint.a *= fade
	if _kind == "teleport":
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, tint, 4.0, true)
		var inner_tint: Color = tint
		inner_tint.a *= 0.55
		draw_arc(Vector2.ZERO, radius * 0.55, 0.0, TAU, 24, inner_tint, 2.0, true)
		return

	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, tint, 4.0, true)
	for ray_index: int in range(8):
		var angle: float = TAU * float(ray_index) / 8.0
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(direction * (radius * 0.64), direction * (radius * 1.15), tint, 3.0, true)
