extends Node2D

const CityGenerator = preload("res://scripts/city/city_generator.gd")
const CityCameraController = preload("res://scripts/camera/city_camera_controller.gd")
const CityHUD = preload("res://scripts/ui/city_hud.gd")

const CITY_SEED: int = 20261015
const STARTING_ZOOM: float = 0.55

var _city: Node2D
var _camera: Camera2D


func _ready() -> void:
	_city = CityGenerator.new()
	_city.name = "City"
	add_child(_city)
	_city.call("generate", CITY_SEED)

	_camera = Camera2D.new()
	_camera.name = "CityCamera"
	_camera.position = _city.call("get_map_center")
	_camera.zoom = Vector2(STARTING_ZOOM, STARTING_ZOOM)
	add_child(_camera)
	_camera.make_current()

	var camera_controls: Node = CityCameraController.new()
	camera_controls.set("camera", _camera)
	add_child(camera_controls)

	var hud: CanvasLayer = CityHUD.new()
	hud.call("set_city_stats", _city.call("get_citizen_count"), _city.call("get_car_count"))
	add_child(hud)
