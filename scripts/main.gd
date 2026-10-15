extends Node2D

const CityGenerator = preload("res://scripts/city/city_generator.gd")
const CityCameraController = preload("res://scripts/camera/city_camera_controller.gd")
const CityHUD = preload("res://scripts/ui/city_hud.gd")
const CityStartMenu = preload("res://scripts/ui/city_start_menu.gd")

const CITY_SEED: int = 20261015
const DEFAULT_MAP_SIZE: int = 2
const STARTING_ZOOMS: Array[float] = [0.70, 0.64, 0.58, 0.52]

var _city: Node2D
var _camera: Camera2D
var _camera_controls: Node
var _hud: CanvasLayer
var _size_menu: Node
var _current_preset: int = DEFAULT_MAP_SIZE
var _city_number: int = 0


func _ready() -> void:
	_camera = Camera2D.new()
	_camera.name = "CityCamera"
	_camera.zoom = Vector2(STARTING_ZOOMS[DEFAULT_MAP_SIZE], STARTING_ZOOMS[DEFAULT_MAP_SIZE])
	add_child(_camera)
	_camera.make_current()

	_camera_controls = CityCameraController.new()
	_camera_controls.set("camera", _camera)
	_camera_controls.set("min_zoom", 0.12)
	add_child(_camera_controls)

	_hud = CityHUD.new()
	_hud.name = "CityHUD"
	_hud.call("set_city_stats", 0, 0, 0, "", Vector2i.ZERO)
	_hud.connect("new_city_requested", Callable(self, "_on_new_city_requested"))
	add_child(_hud)

	_open_city_size_menu(false)


func _on_new_city_requested() -> void:
	_open_city_size_menu(true)


func _open_city_size_menu(can_cancel: bool) -> void:
	if _size_menu != null and is_instance_valid(_size_menu):
		return
	var menu: Node = CityStartMenu.new()
	menu.call("configure", can_cancel, _current_preset)
	menu.connect("city_size_confirmed", Callable(self, "_on_city_size_confirmed"))
	menu.connect("cancelled", Callable(self, "_on_city_menu_cancelled"))
	_size_menu = menu
	add_child(menu)


func _on_city_size_confirmed(preset_index: int) -> void:
	_size_menu = null
	_start_new_city(preset_index)


func _on_city_menu_cancelled() -> void:
	_size_menu = null


func _start_new_city(preset_index: int) -> void:
	_current_preset = clampi(preset_index, 0, STARTING_ZOOMS.size() - 1)
	_city_number += 1
	if _city != null and is_instance_valid(_city):
		_city.queue_free()

	_city = CityGenerator.new()
	_city.name = "City"
	add_child(_city)
	_city.call("generate", CITY_SEED + _city_number, _current_preset)
	_camera.position = _city.call("get_map_center")
	_camera.zoom = Vector2(STARTING_ZOOMS[_current_preset], STARTING_ZOOMS[_current_preset])
	_hud.call(
		"set_city_stats",
		_city.call("get_citizen_count"),
		_city.call("get_car_count"),
		_city.call("get_city_block_count"),
		_city.call("get_map_size_name"),
		_city.call("get_map_block_dimensions")
	)
