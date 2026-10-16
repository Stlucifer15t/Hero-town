extends Node2D

const CityGenerator = preload("res://scripts/city/city_generator.gd")
const CityCameraController = preload("res://scripts/camera/city_camera_controller.gd")
const CityHUD = preload("res://scripts/ui/city_hud.gd")
const CityStartMenu = preload("res://scripts/ui/city_start_menu.gd")
const HeroCharacter = preload("res://scripts/hero/hero_character.gd")
const HeroCreationMenu = preload("res://scripts/hero/hero_creation_menu.gd")
const HeroTrainingTarget = preload("res://scripts/hero/hero_training_target.gd")

const CITY_SEED: int = 20261015
const DEFAULT_MAP_SIZE: int = 2
const STARTING_ZOOMS: Array[float] = [0.70, 0.64, 0.58, 0.52]

var _city: Node2D
var _camera: Camera2D
var _camera_controls: Node
var _hud: CanvasLayer
var _size_menu: Node
var _hero_menu: Node
var _hero: Node2D
var _hero_profile: Dictionary = {}
var _training_targets: Array[Node2D] = []
var _camera_focus_tween: Tween
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
	_hud.connect("hero_association_requested", Callable(self, "_on_hero_association_requested"))
	_hud.connect("hero_creation_requested", Callable(self, "_on_hero_creation_requested"))
	_hud.connect("power_requested", Callable(self, "_on_power_requested"))
	_hud.connect("strike_requested", Callable(self, "_on_strike_requested"))
	_hud.connect("movement_changed", Callable(self, "_on_movement_changed"))
	add_child(_hud)

	_open_hero_creation_menu(false)


func _process(delta: float) -> void:
	if _hero == null or not is_instance_valid(_hero):
		return
	if bool(_hero.call("is_moving")):
		var follow_weight: float = minf(1.0, delta * 7.0)
		_camera.position = _camera.position.lerp(_hero.global_position, follow_weight)
	var equipped_powers: Array = _hero.call("get_equipped_powers")
	for power_id: String in equipped_powers:
		_hud.call(
			"set_power_state",
			power_id,
			bool(_hero.call("is_power_active", power_id)),
			float(_hero.call("get_power_cooldown", power_id))
		)
	_hud.call("set_strike_cooldown", float(_hero.call("get_strike_cooldown")))
	_hud.call("set_hero_status", str(_hero.call("get_status_text")))


func _on_new_city_requested() -> void:
	_open_city_size_menu(true)


func _on_hero_association_requested() -> void:
	if _city == null or not is_instance_valid(_city):
		return
	if _camera_focus_tween != null and _camera_focus_tween.is_running():
		_camera_focus_tween.kill()
	var focus_position: Vector2 = _city.call("get_hero_association_position")
	_camera_focus_tween = create_tween()
	_camera_focus_tween.set_parallel(true)
	(
		_camera_focus_tween
		. tween_property(_camera, "position", focus_position, 0.65)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)
	var target_zoom: float = maxf(_camera.zoom.x, 0.76)
	(
		_camera_focus_tween
		. tween_property(_camera, "zoom", Vector2(target_zoom, target_zoom), 0.65)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)


func _on_hero_creation_requested() -> void:
	_open_hero_creation_menu(true)


func _on_hero_created(profile: Dictionary) -> void:
	_hero_profile = profile.duplicate(true)
	_hero_menu = null
	_hud.call("set_hero_profile", _hero_profile)
	if _hero != null and is_instance_valid(_hero):
		_hero.call("configure", _hero_profile, _city)
		_hero.call("set_controls_enabled", true)
		if _city == null:
			_open_city_size_menu(false)
		return
	if _city == null:
		_open_city_size_menu(false)


func _on_hero_menu_cancelled() -> void:
	_hero_menu = null
	if _hero != null and is_instance_valid(_hero):
		_hero.call("set_controls_enabled", true)


func _on_city_size_confirmed(preset_index: int) -> void:
	_size_menu = null
	_start_new_city(preset_index)


func _on_city_menu_cancelled() -> void:
	_size_menu = null
	if _hero != null and is_instance_valid(_hero):
		_hero.call("set_controls_enabled", true)


func _open_hero_creation_menu(can_cancel: bool) -> void:
	if _hero_menu != null and is_instance_valid(_hero_menu):
		return
	if _hero != null and is_instance_valid(_hero):
		_hero.call("set_controls_enabled", false)
	var menu: Node = HeroCreationMenu.new()
	menu.call("configure", can_cancel, _hero_profile)
	menu.connect("hero_created", Callable(self, "_on_hero_created"))
	menu.connect("cancelled", Callable(self, "_on_hero_menu_cancelled"))
	_hero_menu = menu
	add_child(menu)


func _open_city_size_menu(can_cancel: bool) -> void:
	if _size_menu != null and is_instance_valid(_size_menu):
		return
	if _hero_menu != null and is_instance_valid(_hero_menu):
		return
	if _hero != null and is_instance_valid(_hero):
		_hero.call("set_controls_enabled", false)
	var menu: Node = CityStartMenu.new()
	menu.call("configure", can_cancel, _current_preset)
	menu.connect("city_size_confirmed", Callable(self, "_on_city_size_confirmed"))
	menu.connect("cancelled", Callable(self, "_on_city_menu_cancelled"))
	_size_menu = menu
	add_child(menu)


func _on_power_requested(power_id: String) -> void:
	if _hero == null or not is_instance_valid(_hero):
		return
	_hero.call("activate_power", power_id)


func _on_strike_requested() -> void:
	if _hero != null and is_instance_valid(_hero):
		_hero.call("perform_strike")


func _on_movement_changed(axis: Vector2) -> void:
	if _hero != null and is_instance_valid(_hero):
		_hero.call("set_virtual_movement", axis)


func _start_new_city(preset_index: int) -> void:
	if _camera_focus_tween != null and _camera_focus_tween.is_running():
		_camera_focus_tween.kill()
	_current_preset = clampi(preset_index, 0, STARTING_ZOOMS.size() - 1)
	_city_number += 1
	if _city != null and is_instance_valid(_city):
		_city.queue_free()
	for target: Node2D in _training_targets:
		if is_instance_valid(target):
			target.queue_free()
	_training_targets.clear()

	_city = CityGenerator.new()
	_city.name = "City"
	add_child(_city)
	_city.call("generate", CITY_SEED + _city_number, _current_preset)

	if _hero == null or not is_instance_valid(_hero):
		_hero = HeroCharacter.new()
		_hero.name = "PlayerHero"
		add_child(_hero)
	_hero.call("configure", _hero_profile, _city)
	var spawn_data: Dictionary = _city.call("get_hero_spawn_data")
	_hero.global_position = spawn_data.get("spawn", _city.call("get_map_center"))
	_hero.call("set_controls_enabled", true)
	_spawn_training_targets(spawn_data.get("training_targets", []))

	_camera.position = _hero.global_position
	_camera.zoom = Vector2(STARTING_ZOOMS[_current_preset], STARTING_ZOOMS[_current_preset])
	_hud.call(
		"set_city_stats",
		_city.call("get_citizen_count"),
		_city.call("get_car_count"),
		_city.call("get_city_block_count"),
		_city.call("get_map_size_name"),
		_city.call("get_map_block_dimensions"),
		_city.call("get_hero_association_visitor_count")
	)
	_hud.call("set_hero_profile", _hero_profile)


func _spawn_training_targets(target_positions: Array) -> void:
	if _city == null or not is_instance_valid(_city):
		return
	for position_value: Variant in target_positions:
		if not position_value is Vector2:
			continue
		var target_position: Vector2 = position_value
		var target: Node2D = HeroTrainingTarget.new()
		target.name = "TrainingTarget_%02d" % _training_targets.size()
		add_child(target)
		target.global_position = target_position
		_training_targets.append(target)
