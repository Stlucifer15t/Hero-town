extends Control

signal axis_changed(axis: Vector2)

var _axis: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _touch_index: int = -1
var _radius: float = 56.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(160.0, 160.0)
	queue_redraw()


func clear_input() -> void:
	_dragging = false
	_touch_index = -1
	_axis = Vector2.ZERO
	axis_changed.emit(_axis)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_dragging = true
			_touch_index = touch.index
			_update_axis(touch.position)
			accept_event()
		else:
			if _touch_index == touch.index:
				clear_input()
			accept_event()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if _dragging and drag.index == _touch_index:
			_update_axis(drag.position)
			accept_event()
	elif event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mouse_button.pressed
			if _dragging:
				_update_axis(mouse_button.position)
			else:
				clear_input()
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var mouse_motion: InputEventMouseMotion = event
		_update_axis(mouse_motion.position)
		accept_event()


func _update_axis(pointer_position: Vector2) -> void:
	var center: Vector2 = size * 0.5
	_radius = minf(size.x, size.y) * 0.36
	var displacement: Vector2 = pointer_position - center
	_axis = displacement.limit_length(_radius) / maxf(_radius, 1.0)
	axis_changed.emit(_axis)
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.36
	draw_circle(center, radius + 13.0, Color(0.015, 0.035, 0.045, 0.52))
	draw_arc(center, radius + 13.0, 0.0, TAU, 64, Color(0.8, 0.87, 0.79, 0.38), 2.0, true)
	draw_circle(center, radius, Color(0.04, 0.12, 0.14, 0.30))
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.61, 0.78, 0.68, 0.21), 1.0, true)
	var knob_center: Vector2 = center + _axis * radius * 0.76
	draw_circle(knob_center, radius * 0.46, Color(0.66, 0.79, 0.71, 0.6))
	draw_arc(knob_center, radius * 0.46, 0.0, TAU, 48, Color(0.98, 0.88, 0.63, 0.8), 2.0, true)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(center.x - 26.0, center.y + radius + 16.0),
		"MOVE",
		HORIZONTAL_ALIGNMENT_CENTER,
		52.0,
		11,
		Color("#d9e2cf")
	)
