extends Node3D

const HeroPowerCatalog = preload("res://scripts/hero/hero_power_catalog.gd")
const ParkWorld3D = preload("res://scripts/game3d/park_world_3d.gd")
const HeroPlayer3D = preload("res://scripts/game3d/hero_player_3d.gd")
const HeroPreviewBuilder = preload("res://scripts/game3d/hero_preview_builder.gd")
const VirtualJoystick3D = preload("res://scripts/game3d/virtual_joystick_3d.gd")

const SHORT_POWER_NAMES: Dictionary = {
	"elemental": "BOLT",
	"super_strength": "SMASH",
	"speed": "SPEED",
	"teleportation": "BLINK",
	"beast": "BEAST",
	"flight": "FLIGHT",
}
const SUIT_PRESETS: Array[Dictionary] = [
	{"name": "TIDAL", "suit": "#45bcae", "cape": "#e7645d"},
	{"name": "NOVA", "suit": "#527fe5", "cape": "#edcb69"},
	{"name": "EMBER", "suit": "#df674f", "cape": "#f3c85a"},
	{"name": "NIGHT", "suit": "#554c83", "cape": "#bd9aff"},
	{"name": "MOSS", "suit": "#568b61", "cape": "#e2d8b2"},
	{"name": "STORM", "suit": "#d7dde6", "cape": "#6aa7d3"},
]
const DEFAULT_PROFILE: Dictionary = {
	"name": "Nova",
	"suit_color": "#45bcae",
	"cape_color": "#e7645d",
	"element": "fire",
	"powers": ["elemental", "flight", "super_strength"],
}

var _park: Node3D
var _hero: CharacterBody3D
var _camera: Camera3D
var _canvas: CanvasLayer
var _ui_root: Control
var _status_label: Label
var _title_overlay: Control
var _creator_overlay: Control
var _gameplay_root: Control
var _name_field: LineEdit
var _element_picker: OptionButton
var _element_row: HBoxContainer
var _loadout_label: Label
var _creator_status_label: Label
var _create_button: Button
var _preview_hero: CharacterBody3D
var _preview_name_label: Label
var _preview_color_label: Label
var _power_cards: Dictionary = {}
var _preset_buttons: Array[Button] = []
var _action_buttons: Dictionary = {}
var _action_style_cache: Dictionary = {}
var _selected_powers: Array[String] = []
var _selected_preset: int = 0
var _selected_element: String = "fire"
var _profile: Dictionary = DEFAULT_PROFILE.duplicate(true)
var _gameplay_active: bool = false
var _return_to_game_after_edit: bool = false
var _elapsed: float = 0.0


func _ready() -> void:
	_build_camera()
	_park = ParkWorld3D.new() as Node3D
	_park.name = "HeroTownPark"
	add_child(_park)
	_hero = HeroPlayer3D.new() as CharacterBody3D
	_hero.name = "PlayerHero"
	add_child(_hero)
	_hero.call("configure", _profile, _park.call("get_park_bounds"))
	_hero.global_position = _park.call("get_player_spawn")
	_build_ui()
	_show_title_screen()
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	_update_camera(delta)
	_update_hud()


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "HeroTownCamera"
	_camera.fov = 59.0
	_camera.near = 0.08
	_camera.far = 220.0
	_camera.current = true
	add_child(_camera)
	_camera.position = Vector3(0.0, 4.8, 28.0)
	_camera.look_at(Vector3(0.0, 1.1, -16.0), Vector3.UP)


func _update_camera(delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	var target_position: Vector3
	var look_target: Vector3
	if _gameplay_active and _hero != null and is_instance_valid(_hero):
		var facing: Vector3 = _hero.call("get_facing_direction")
		var behind: Vector3 = -facing.normalized()
		target_position = _hero.global_position + behind * 9.2 + Vector3.UP * 4.1
		look_target = _hero.global_position + facing * 4.8 + Vector3.UP * 1.15
		_camera.fov = lerpf(_camera.fov, 63.0, minf(delta * 2.0, 1.0))
	else:
		var drift: float = sin(_elapsed * 0.13) * 0.7
		target_position = Vector3(drift, 4.15, 28.0)
		look_target = Vector3(-drift * 0.24, 1.4, -20.0)
		_camera.fov = lerpf(_camera.fov, 56.0, minf(delta * 1.5, 1.0))
	_camera.position = _camera.position.lerp(target_position, minf(delta * 2.6, 1.0))
	_camera.look_at(look_target, Vector3.UP)


func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.name = "PortraitGameUI"
	_canvas.layer = 10
	add_child(_canvas)
	_ui_root = Control.new()
	_ui_root.name = "UIRoot"
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_PASS
	_canvas.add_child(_ui_root)
	_build_location_card()
	_build_status_card()
	_build_title_overlay()
	_build_gameplay_hud()


func _build_location_card() -> void:
	var location_panel := PanelContainer.new()
	location_panel.name = "LocationCard"
	location_panel.position = Vector2(24.0, 26.0)
	location_panel.custom_minimum_size = Vector2(365.0, 142.0)
	location_panel.add_theme_stylebox_override(
		"panel", _panel_style(Color(0.025, 0.055, 0.075, 0.76), Color(0.82, 0.9, 0.84, 0.3), 2)
	)
	_ui_root.add_child(location_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 11)
	location_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	margin.add_child(column)
	var time_label := Label.new()
	time_label.text = "●  A NORMAL AFTERNOON"
	time_label.add_theme_font_size_override("font_size", 12)
	time_label.add_theme_color_override("font_color", Color("#dbe6ca"))
	column.add_child(time_label)
	var location_label := Label.new()
	location_label.text = "LOCATION"
	location_label.add_theme_font_size_override("font_size", 12)
	location_label.add_theme_color_override("font_color", Color("#d0ddda"))
	column.add_child(location_label)
	var title := Label.new()
	title.text = "HERO TOWN PARK"
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color("#f4f2df"))
	column.add_child(title)
	var location_subtitle := Label.new()
	location_subtitle.text = "HERO TOWN  ·  WATERFRONT DISTRICT"
	location_subtitle.add_theme_font_size_override("font_size", 11)
	location_subtitle.add_theme_color_override("font_color", Color("#b7c8c4"))
	column.add_child(location_subtitle)


func _build_status_card() -> void:
	var panel := PanelContainer.new()
	panel.name = "HeroStatusCard"
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -212.0
	panel.offset_right = -22.0
	panel.offset_top = 26.0
	panel.offset_bottom = 80.0
	panel.add_theme_stylebox_override(
		"panel", _panel_style(Color(0.025, 0.055, 0.075, 0.72), Color(0.82, 0.9, 0.84, 0.3), 2)
	)
	_ui_root.add_child(panel)
	_status_label = Label.new()
	_status_label.text = "NOVA  ·  HERO IN TRAINING"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color("#d4e5cf"))
	panel.add_child(_status_label)


func _build_title_overlay() -> void:
	_title_overlay = Control.new()
	_title_overlay.name = "StartMenu"
	_title_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	_ui_root.add_child(_title_overlay)

	var panel := PanelContainer.new()
	panel.name = "TitleCard"
	panel.anchor_left = 0.045
	panel.anchor_right = 0.955
	panel.anchor_top = 0.75
	panel.anchor_bottom = 0.975
	panel.add_theme_stylebox_override(
		"panel", _panel_style(Color(0.025, 0.055, 0.075, 0.83), Color(0.9, 0.82, 0.55, 0.62), 2)
	)
	_title_overlay.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)
	var title := Label.new()
	title.text = "HERO TOWN"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("#f5f1dd"))
	column.add_child(title)
	var copy := Label.new()
	copy.text = "A living city. A new hero. Your story starts here."
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_font_size_override("font_size", 14)
	copy.add_theme_color_override("font_color", Color("#c0d2ca"))
	column.add_child(copy)
	var create_hero_button := _make_button("CREATE YOUR HERO", Vector2(0.0, 58.0), true)
	create_hero_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_hero_button.pressed.connect(_show_creator)
	column.add_child(create_hero_button)
	var footer := Label.new()
	footer.text = "TOUCH TO PLAY  ·  WASD / ARROWS ON DESKTOP"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 10)
	footer.add_theme_color_override("font_color", Color("#a9c1b9"))
	column.add_child(footer)


func _build_gameplay_hud() -> void:
	_gameplay_root = Control.new()
	_gameplay_root.name = "PatrolHUD"
	_gameplay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gameplay_root.mouse_filter = Control.MOUSE_FILTER_PASS
	_ui_root.add_child(_gameplay_root)
	_gameplay_root.visible = false

	var hero_button := _make_button("HERO", Vector2(82.0, 44.0), false)
	hero_button.anchor_left = 1.0
	hero_button.anchor_right = 1.0
	hero_button.offset_left = -104.0
	hero_button.offset_right = -22.0
	hero_button.offset_top = 91.0
	hero_button.offset_bottom = 135.0
	hero_button.add_theme_font_size_override("font_size", 12)
	hero_button.pressed.connect(_show_creator)
	_gameplay_root.add_child(hero_button)

	var park_info := PanelContainer.new()
	park_info.name = "ParkInfo"
	park_info.position = Vector2(24.0, 179.0)
	park_info.custom_minimum_size = Vector2(340.0, 40.0)
	park_info.add_theme_stylebox_override(
		"panel", _panel_style(Color(0.025, 0.055, 0.075, 0.62), Color(0.82, 0.9, 0.84, 0.2), 1)
	)
	_gameplay_root.add_child(park_info)
	var park_info_label := Label.new()
	park_info_label.text = "PARK VISITORS  ·  TRAINING GROUNDS"
	park_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	park_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	park_info_label.add_theme_font_size_override("font_size", 10)
	park_info_label.add_theme_color_override("font_color", Color("#d1dbcc"))
	park_info.add_child(park_info_label)

	var joystick: Control = VirtualJoystick3D.new()
	joystick.name = "MovementJoystick"
	joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.offset_left = 20.0
	joystick.offset_top = -190.0
	joystick.offset_right = 180.0
	joystick.offset_bottom = -30.0
	joystick.connect("axis_changed", Callable(self, "_on_joystick_axis_changed"))
	_gameplay_root.add_child(joystick)

	var action_panel := PanelContainer.new()
	action_panel.name = "PowerControls"
	action_panel.anchor_left = 1.0
	action_panel.anchor_right = 1.0
	action_panel.anchor_top = 1.0
	action_panel.anchor_bottom = 1.0
	action_panel.offset_left = -382.0
	action_panel.offset_right = -18.0
	action_panel.offset_top = -142.0
	action_panel.offset_bottom = -28.0
	action_panel.add_theme_stylebox_override(
		"panel", _panel_style(Color(0.025, 0.055, 0.075, 0.78), Color(0.82, 0.9, 0.84, 0.28), 2)
	)
	_gameplay_root.add_child(action_panel)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	action_panel.add_child(buttons)
	_action_buttons["container"] = buttons
	var strike_button := _make_button("STRIKE\nSPACE", Vector2(78.0, 88.0), true)
	strike_button.add_theme_font_size_override("font_size", 11)
	strike_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strike_button.pressed.connect(_on_strike_pressed)
	buttons.add_child(strike_button)
	_action_buttons["strike"] = strike_button


func _show_title_screen() -> void:
	_gameplay_active = false
	_hero.call("set_gameplay_enabled", false)
	_title_overlay.visible = true
	_gameplay_root.visible = false
	_status_label.text = "%s  ·  HERO IN TRAINING" % str(_profile.get("name", "NOVA")).to_upper()


func _show_creator() -> void:
	if _creator_overlay != null and is_instance_valid(_creator_overlay):
		return
	_return_to_game_after_edit = _gameplay_active
	_hero.call("set_gameplay_enabled", false)
	var creator := Control.new()
	creator.name = "HeroCreator"
	creator.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	creator.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(creator)
	_creator_overlay = creator
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.008, 0.025, 0.04, 0.61)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	creator.add_child(dimmer)
	var panel := PanelContainer.new()
	panel.name = "HeroCreatorPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 24.0
	panel.offset_top = 190.0
	panel.offset_right = -24.0
	panel.offset_bottom = -190.0
	panel.add_theme_stylebox_override(
		"panel", _panel_style(Color("#10242deF"), Color("#dbc986"), 2)
	)
	creator.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	column.add_child(header)
	var title_copy := VBoxContainer.new()
	title_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_copy.add_theme_constant_override("separation", 0)
	header.add_child(title_copy)
	var title := Label.new()
	title.text = "CREATE YOUR HERO"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("#f4f2df"))
	title_copy.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Build a look, choose three powers, then patrol the park."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color("#aec4bd"))
	title_copy.add_child(subtitle)
	if _return_to_game_after_edit:
		var close_button := _make_button("CLOSE", Vector2(70.0, 42.0), false)
		close_button.add_theme_font_size_override("font_size", 10)
		close_button.pressed.connect(_cancel_creator)
		header.add_child(close_button)

	var preview_preset: Dictionary = SUIT_PRESETS[_find_preset(
		str(_profile.get("suit_color", "#45bcae"))
	)]
	var preview: Dictionary = HeroPreviewBuilder.add_preview(column, _profile, preview_preset)
	_preview_hero = preview["hero"] as CharacterBody3D
	_preview_name_label = preview["name_label"] as Label
	_preview_color_label = preview["color_label"] as Label
	var name_label := Label.new()
	name_label.text = "CALLSIGN"
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color("#cfdbcf"))
	column.add_child(name_label)
	_name_field = LineEdit.new()
	_name_field.placeholder_text = "Enter a hero name"
	_name_field.text = str(_profile.get("name", "Nova"))
	_name_field.max_length = 18
	_name_field.custom_minimum_size.y = 44.0
	_name_field.add_theme_font_size_override("font_size", 16)
	_name_field.add_theme_stylebox_override("normal", _input_style())
	_name_field.add_theme_color_override("font_color", Color("#f4f2df"))
	column.add_child(_name_field)
	_name_field.text_changed.connect(_on_name_text_changed)

	var power_heading := HBoxContainer.new()
	column.add_child(power_heading)
	var power_label := Label.new()
	power_label.text = "CHOOSE YOUR POWERS"
	power_label.add_theme_font_size_override("font_size", 11)
	power_label.add_theme_color_override("font_color", Color("#d8d0a4"))
	power_heading.add_child(power_label)
	_loadout_label = Label.new()
	_loadout_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_loadout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_loadout_label.add_theme_font_size_override("font_size", 10)
	_loadout_label.add_theme_color_override("font_color", Color("#b7c8bc"))
	power_heading.add_child(_loadout_label)

	var scroll := ScrollContainer.new()
	scroll.name = "PowerCardScroller"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 380.0
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "PowerCardGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	_power_cards.clear()
	for power: Dictionary in HeroPowerCatalog.get_all_powers():
		var power_id: String = str(power["id"])
		var card := Button.new()
		card.name = "PowerCard_%s" % power_id
		card.custom_minimum_size = Vector2(282.0, 116.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_color_override("font_color", Color("#f4f2df"))
		card.pressed.connect(_on_power_card_pressed.bind(power_id))
		grid.add_child(card)
		var card_margin := MarginContainer.new()
		card_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card_margin.add_theme_constant_override("margin_left", 10)
		card_margin.add_theme_constant_override("margin_top", 7)
		card_margin.add_theme_constant_override("margin_right", 8)
		card_margin.add_theme_constant_override("margin_bottom", 7)
		card_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(card_margin)
		var copy := VBoxContainer.new()
		copy.add_theme_constant_override("separation", 2)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_margin.add_child(copy)
		var title_label := Label.new()
		title_label.name = "PowerTitle"
		title_label.add_theme_font_size_override("font_size", 13)
		title_label.add_theme_color_override("font_color", Color(str(power["color"])))
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_child(title_label)
		var tagline := Label.new()
		tagline.text = str(power["tagline"])
		tagline.add_theme_font_size_override("font_size", 11)
		tagline.add_theme_color_override("font_color", Color("#e0e3d4"))
		tagline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_child(tagline)
		var description := Label.new()
		description.text = str(power["description"])
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 10)
		description.add_theme_color_override("font_color", Color("#aebfba"))
		description.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_child(description)
		_power_cards[power_id] = card

	var element_row := HBoxContainer.new()
	element_row.add_theme_constant_override("separation", 8)
	column.add_child(element_row)
	_element_row = element_row
	var element_label := Label.new()
	element_label.text = "ELEMENT"
	element_label.custom_minimum_size.x = 70.0
	element_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	element_label.add_theme_font_size_override("font_size", 10)
	element_label.add_theme_color_override("font_color", Color("#d3dfd6"))
	element_row.add_child(element_label)
	_element_picker = OptionButton.new()
	_element_picker.custom_minimum_size = Vector2(138.0, 38.0)
	_element_picker.add_theme_font_size_override("font_size", 11)
	_element_picker.add_theme_stylebox_override("normal", _input_style())
	for element: Dictionary in HeroPowerCatalog.get_all_elements():
		_element_picker.add_item(str(element["name"]))
	_element_picker.item_selected.connect(_on_element_selected)
	element_row.add_child(_element_picker)
	var element_hint := Label.new()
	element_hint.text = "Fire burns  ·  Ice freezes  ·  Lightning chains"
	element_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	element_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	element_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	element_hint.add_theme_font_size_override("font_size", 10)
	element_hint.add_theme_color_override("font_color", Color("#aebfba"))
	element_row.add_child(element_hint)

	var appearance_heading := Label.new()
	appearance_heading.text = "SUIT + CAPE"
	appearance_heading.add_theme_font_size_override("font_size", 10)
	appearance_heading.add_theme_color_override("font_color", Color("#d3dfd6"))
	column.add_child(appearance_heading)
	var palette := HBoxContainer.new()
	palette.add_theme_constant_override("separation", 5)
	column.add_child(palette)
	_preset_buttons.clear()
	for preset_index: int in range(SUIT_PRESETS.size()):
		var preset: Dictionary = SUIT_PRESETS[preset_index]
		var swatch := _make_button(str(preset["name"]), Vector2(0.0, 38.0), false)
		swatch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		swatch.add_theme_font_size_override("font_size", 9)
		swatch.add_theme_color_override("font_color", Color(str(preset["suit"])))
		swatch.pressed.connect(_on_preset_pressed.bind(preset_index))
		palette.add_child(swatch)
		_preset_buttons.append(swatch)

	_creator_status_label = Label.new()
	_creator_status_label.text = "SELECT 1–3 POWERS TO EQUIP"
	_creator_status_label.add_theme_font_size_override("font_size", 10)
	_creator_status_label.add_theme_color_override("font_color", Color("#c6d2c4"))
	column.add_child(_creator_status_label)
	_create_button = _make_button("BEGIN PATROL", Vector2(0.0, 54.0), true)
	_create_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_create_button.pressed.connect(_commit_hero_profile)
	column.add_child(_create_button)

	_selected_powers = HeroPowerCatalog.sanitize_loadout(
		_profile.get("powers", ["elemental", "flight"])
	)
	_selected_element = str(_profile.get("element", "fire"))
	_selected_preset = _find_preset(str(_profile.get("suit_color", "#45bcae")))
	_element_picker.select(_element_index(_selected_element))
	_render_creator()


func _render_creator() -> void:
	if _loadout_label != null:
		_loadout_label.text = "%d / 3 EQUIPPED" % _selected_powers.size()
	for power: Dictionary in HeroPowerCatalog.get_all_powers():
		var power_id: String = str(power["id"])
		var card: Button = _power_cards.get(power_id) as Button
		if card == null:
			continue
		var equipped_index: int = _selected_powers.find(power_id)
		var title_label: Label = card.find_child("PowerTitle", true, false) as Label
		if title_label != null:
			var key_text: String = str(equipped_index + 1) if equipped_index >= 0 else "—"
			title_label.text = "%s  ·  %s" % [key_text, str(power["name"])]
		var accent := Color(str(power["color"]))
		card.add_theme_stylebox_override("normal", _card_style(equipped_index >= 0, accent))
		card.add_theme_stylebox_override("hover", _card_style(true, accent))
	for preset_index: int in range(_preset_buttons.size()):
		var preset_button: Button = _preset_buttons[preset_index]
		var suit_color := Color(str(SUIT_PRESETS[preset_index]["suit"]))
		preset_button.add_theme_stylebox_override(
			"normal", _palette_style(suit_color, preset_index == _selected_preset)
		)
		preset_button.add_theme_stylebox_override("hover", _palette_style(suit_color, true))
	if _element_row != null:
		_element_row.visible = _selected_powers.has("elemental")
	if _creator_status_label != null:
		_creator_status_label.text = "%d / 3 POWERS EQUIPPED" % _selected_powers.size()
		if _selected_powers.is_empty():
			_creator_status_label.text = "CHOOSE AT LEAST ONE POWER"
		elif _selected_powers.has("elemental"):
			_creator_status_label.text += "  ·  %s AFFINITY" % _selected_element.to_upper()
	if _create_button != null:
		_create_button.disabled = _selected_powers.is_empty()
	if _name_field != null:
		var live_profile: Dictionary = _build_profile_from_fields()
		_hero.call("configure", live_profile, _park.call("get_park_bounds"))
		if _preview_hero != null and is_instance_valid(_preview_hero):
			_preview_hero.call("configure", live_profile, Vector2(2.0, 2.0))
		if _preview_name_label != null:
			_preview_name_label.text = str(live_profile["name"]).to_upper()
		if _preview_color_label != null:
			var preset_name: String = str(SUIT_PRESETS[_selected_preset]["name"])
			_preview_color_label.text = "%s SUIT  ·  %s CAPE" % [preset_name, preset_name]


func _build_profile_from_fields() -> Dictionary:
	var preset: Dictionary = SUIT_PRESETS[_selected_preset]
	var name_value: String = "Nova"
	if _name_field != null and not _name_field.text.strip_edges().is_empty():
		name_value = _name_field.text.strip_edges()
	return {
		"name": name_value,
		"suit_color": str(preset["suit"]),
		"cape_color": str(preset["cape"]),
		"powers": _selected_powers.duplicate(),
		"element": _selected_element,
	}


func _commit_hero_profile() -> void:
	_profile = _build_profile_from_fields()
	_hero.call("configure", _profile, _park.call("get_park_bounds"))
	if not _return_to_game_after_edit:
		_hero.global_position = _park.call("get_player_spawn")
	_gameplay_active = true
	_hero.call("set_gameplay_enabled", true)
	_title_overlay.visible = false
	_gameplay_root.visible = true
	_creator_overlay.queue_free()
	_creator_overlay = null
	_status_label.text = _hero.call("get_status_text")
	_rebuild_action_power_buttons()
	_update_hud()


func _cancel_creator() -> void:
	if _creator_overlay != null and is_instance_valid(_creator_overlay):
		_creator_overlay.queue_free()
	_creator_overlay = null
	_hero.call("configure", _profile, _park.call("get_park_bounds"))
	if _return_to_game_after_edit:
		_hero.call("set_gameplay_enabled", true)
	else:
		_show_title_screen()


func _rebuild_action_power_buttons() -> void:
	var buttons_container: HBoxContainer = _action_buttons.get("container") as HBoxContainer
	if buttons_container == null:
		return
	var strike_button: Button = _action_buttons.get("strike") as Button
	_action_buttons.clear()
	_action_buttons["container"] = buttons_container
	_action_buttons["strike"] = strike_button
	for child: Node in buttons_container.get_children():
		if child == _action_buttons.get("strike"):
			continue
		child.queue_free()
	var equipped_powers: Array = _hero.call("get_equipped_powers")
	for power_index: int in range(equipped_powers.size()):
		var power_id: String = str(equipped_powers[power_index])
		var data: Dictionary = HeroPowerCatalog.get_power(power_id)
		var color := Color(str(data.get("color", "#d3dcce")))
		var title: String = _short_power_name(power_id)
		var slot_key: String = str(power_index + 1)
		var button := _make_button("%s\n%s" % [title, slot_key], Vector2(70.0, 88.0), false)
		button.name = "PowerAction_%s" % power_id
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 10)
		button.set_meta("slot_key", slot_key)
		button.add_theme_stylebox_override("normal", _action_style(false, color))
		button.add_theme_stylebox_override("hover", _action_style(true, color))
		button.pressed.connect(_on_power_pressed.bind(power_id))
		buttons_container.add_child(button)
		_action_buttons[power_id] = button


func _update_hud() -> void:
	if _hero == null or not is_instance_valid(_hero):
		return
	if _gameplay_active:
		_status_label.text = _hero.call("get_status_text")
	else:
		_status_label.text = (
			"%s  ·  HERO IN TRAINING" % str(_profile.get("name", "Nova")).to_upper()
		)
	var strike_button: Button = _action_buttons.get("strike") as Button
	if strike_button != null:
		var strike_cooldown: float = _hero.call("get_strike_cooldown")
		var strike_text: String = (
			"STRIKE\n%.1f" % strike_cooldown if strike_cooldown > 0.05 else "STRIKE\nSPACE"
		)
		if strike_button.text != strike_text:
			strike_button.text = strike_text
	for power_id: String in _hero.call("get_equipped_powers"):
		var button: Button = _action_buttons.get(power_id) as Button
		if button == null:
			continue
		var data: Dictionary = HeroPowerCatalog.get_power(power_id)
		var active: bool = _hero.call("is_power_active", power_id)
		var cooldown: float = _hero.call("get_power_cooldown", power_id)
		var power_name: String = _short_power_name(power_id)
		var display_text: String
		if active:
			display_text = "%s\nON" % power_name
		elif cooldown > 0.05:
			display_text = "%s\n%.1f" % [power_name, cooldown]
		else:
			display_text = "%s\n%s" % [power_name, str(button.get_meta("slot_key", ""))]
		if button.text != display_text:
			button.text = display_text
		if not button.has_meta("power_active") or bool(button.get_meta("power_active")) != active:
			button.add_theme_stylebox_override(
				"normal", _action_style(active, Color(str(data.get("color", "#d3dcce"))))
			)
			button.set_meta("power_active", active)


func _on_power_pressed(power_id: String) -> void:
	if _hero != null and is_instance_valid(_hero):
		_hero.call("activate_power", power_id)


func _on_strike_pressed() -> void:
	if _hero != null and is_instance_valid(_hero):
		_hero.call("perform_strike")


func _on_joystick_axis_changed(axis: Vector2) -> void:
	if _hero != null and is_instance_valid(_hero):
		_hero.call("set_virtual_movement", axis)


func _on_name_text_changed(_new_text: String) -> void:
	_render_creator()


func _on_power_card_pressed(power_id: String) -> void:
	if _selected_powers.has(power_id):
		_selected_powers.erase(power_id)
	else:
		if _selected_powers.size() >= 3:
			_creator_status_label.text = "LOADOUT FULL  ·  REMOVE A POWER FIRST"
			return
		_selected_powers.append(power_id)
	_render_creator()


func _on_element_selected(index: int) -> void:
	var elements: Array[Dictionary] = HeroPowerCatalog.get_all_elements()
	if index >= 0 and index < elements.size():
		_selected_element = str(elements[index]["id"])
		_render_creator()


func _on_preset_pressed(index: int) -> void:
	_selected_preset = clampi(index, 0, SUIT_PRESETS.size() - 1)
	_render_creator()


func _find_preset(color: String) -> int:
	for index: int in range(SUIT_PRESETS.size()):
		if str(SUIT_PRESETS[index]["suit"]) == color:
			return index
	return 0


func _element_index(element_id: String) -> int:
	var elements: Array[Dictionary] = HeroPowerCatalog.get_all_elements()
	for index: int in range(elements.size()):
		if str(elements[index]["id"]) == element_id:
			return index
	return 0


func _short_power_name(power_id: String) -> String:
	return str(SHORT_POWER_NAMES.get(power_id, power_id.to_upper()))


func _make_button(text_value: String, minimum_size: Vector2, primary: bool) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", Color("#f3f1df"))
	button.add_theme_color_override("font_hover_color", Color("#fff7d7"))
	button.add_theme_font_size_override("font_size", 13 if primary else 11)
	(
		button
		. add_theme_stylebox_override(
			"normal",
			_button_style(primary, false),
		)
	)
	button.add_theme_stylebox_override("hover", _button_style(primary, true))
	button.add_theme_stylebox_override("pressed", _button_style(primary, true))
	return button


func _button_style(primary: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#315c52") if primary else Color("#142b34")
	if hovered:
		style.bg_color = Color("#3e7060") if primary else Color("#1d4148")
	style.border_color = Color("#dec883") if primary else Color("#7ea69c")
	style.set_border_width_all(2 if primary else 1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style


func _panel_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(15)
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 10
	return style


func _input_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0b1c25")
	style.border_color = Color("#63847f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style


func _card_style(selected: bool, accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#24443f") if selected else Color("#142a33")
	style.border_color = accent.lightened(0.22) if selected else Color("#49636a")
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(11)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style


func _palette_style(suit_color: Color, selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = suit_color.darkened(0.66)
	style.border_color = Color("#e3cf8d") if selected else suit_color.darkened(0.12)
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 3.0
	style.content_margin_right = 3.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style


func _action_style(active: bool, accent: Color) -> StyleBoxFlat:
	var cache_key: String = "%s:%s" % [str(accent), str(active)]
	if _action_style_cache.has(cache_key):
		return _action_style_cache[cache_key]
	var style := StyleBoxFlat.new()
	style.bg_color = (
		Color(accent.r * 0.22, accent.g * 0.24, accent.b * 0.22, 0.95)
		if active
		else Color("#11252f")
	)
	style.border_color = accent.lightened(0.12) if active else Color("#657f80")
	style.set_border_width_all(2 if active else 1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 3.0
	style.content_margin_right = 3.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	_action_style_cache[cache_key] = style
	return style
