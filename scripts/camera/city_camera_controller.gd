extends Node

## Touch and mouse camera gestures for the city view.
@export var min_zoom: float = 0.28
@export var max_zoom: float = 1.15
@export var zoom_step: float = 1.12

var camera: Camera2D
var _touch_positions: Dictionary = {}
var _mouse_dragging: bool = false
var _previous_pinch_distance: float = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if camera == null:
		return

	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _mouse_dragging:
		camera.position -= event.relative / camera.zoom.x


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touch_positions[event.index] = event.position
		if _touch_positions.size() >= 2:
			_previous_pinch_distance = _pinch_distance()
	else:
		_touch_positions.erase(event.index)
		_previous_pinch_distance = 0.0


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not _touch_positions.has(event.index):
		_touch_positions[event.index] = event.position - event.relative

	var previous_position: Vector2 = _touch_positions[event.index]
	_touch_positions[event.index] = event.position

	if _touch_positions.size() == 1:
		camera.position -= (event.position - previous_position) / camera.zoom.x
		return

	if _touch_positions.size() >= 2:
		var current_distance: float = _pinch_distance()
		if _previous_pinch_distance > 0.0 and current_distance > 0.0:
			var zoom_ratio: float = current_distance / _previous_pinch_distance
			_set_zoom(camera.zoom.x * zoom_ratio)
		_previous_pinch_distance = current_distance


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_dragging = event.pressed
	elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_set_zoom(camera.zoom.x * zoom_step)
	elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_set_zoom(camera.zoom.x / zoom_step)


func _pinch_distance() -> float:
	if _touch_positions.size() < 2:
		return 0.0
	var touch_ids: Array = _touch_positions.keys()
	var first: Vector2 = _touch_positions[touch_ids[0]]
	var second: Vector2 = _touch_positions[touch_ids[1]]
	return first.distance_to(second)


func _set_zoom(value: float) -> void:
	var clamped_zoom: float = clampf(value, min_zoom, max_zoom)
	camera.zoom = Vector2(clamped_zoom, clamped_zoom)
