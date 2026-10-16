extends CanvasLayer

signal new_city_requested
signal hero_association_requested
signal hero_creation_requested
signal power_requested(power_id: String)
signal strike_requested
signal movement_changed(axis: Vector2)

const HeroPowerCatalog = preload("res://scripts/hero/hero_power_catalog.gd")

var _stats_label: Label
var _hero_association_label: Label
var _hero_status_label: Label
var _power_container: HBoxContainer
var _strike_button: Button
var _power_buttons: Dictionary = {}
var _power_data: Dictionary = {}
var _move_buttons: Dictionary = {}
var _move_pressed: Dictionary = {}
var _citizen_count: int = 0
var _car_count: int = 0
var _block_count: int = 0
var _hero_association_visitors: int = 0
var _size_name: String = ""
var _size_dimensions: Vector2i = Vector2i.ZERO
var _hero_name: String = "Nova"
var _element: String = "fire"


func _ready() -> void:
	layer = 5
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	_add_title_panel(root)
	_add_top_right_controls(root)
	_add_movement_panel(root)
	_add_power_panel(root)
	_add_stats_panel(root)


func set_city_stats(
	citizen_count: int,
	car_count: int,
	block_count: int,
	size_name: String,
	size_dimensions: Vector2i,
	hero_association_visitors: int = 0
) -> void:
	_citizen_count = citizen_count
	_car_count = car_count
	_block_count = block_count
	_hero_association_visitors = hero_association_visitors
	_size_name = size_name
	_size_dimensions = size_dimensions
	if _stats_label != null:
		_stats_label.text = _stats_text()
	if _hero_association_label != null:
		_hero_association_label.text = _hero_association_text()


func set_hero_profile(profile: Dictionary) -> void:
	_hero_name = str(profile.get("name", "Nova"))
	_element = str(profile.get("element", "fire")).to_upper()
	for child: Node in _power_container.get_children():
		if child != _strike_button:
			child.queue_free()
	_power_buttons.clear()
	_power_buttons["strike"] = _strike_button
	_power_data.clear()
	var requested_powers: Array = profile.get("powers", [])
	var powers: Array[String] = HeroPowerCatalog.sanitize_loadout(requested_powers)
	for power_index: int in range(powers.size()):
		var power_id: String = powers[power_index]
		var data: Dictionary = HeroPowerCatalog.get_power(power_id)
		if data.is_empty():
			continue
		data["slot_key"] = str(power_index + 1)
		_power_data[power_id] = data
		var button := Button.new()
		button.name = "PowerAction_%s" % power_id
		button.custom_minimum_size = Vector2(98.0, 60.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 10)
		button.add_theme_color_override("font_color", Color("#f4f3dc"))
		button.add_theme_stylebox_override("normal", _make_button_style(false))
		button.add_theme_stylebox_override("hover", _make_button_style(true))
		button.pressed.connect(_on_power_pressed.bind(power_id))
		_power_container.add_child(button)
		_power_buttons[power_id] = button
		_update_power_button(power_id, false, 0.0)
	if _hero_status_label != null:
		var affinity: String = _element if powers.has("elemental") else "NO ELEMENT"
		_hero_status_label.text = (
			"%s  ·  %d POWERS  ·  %s"
			% [
				_hero_name.to_upper(),
				powers.size(),
				affinity,
			]
		)


func set_hero_status(status: String) -> void:
	if _hero_status_label != null:
		_hero_status_label.text = status


func set_power_state(power_id: String, active: bool, cooldown: float) -> void:
	_update_power_button(power_id, active, cooldown)


func set_strike_cooldown(cooldown: float) -> void:
	var button: Button = _power_buttons.get("strike") as Button
	if button == null:
		return
	if cooldown > 0.05:
		button.text = "STRIKE\n%.1fs" % cooldown
		button.disabled = true
	else:
		button.text = "STRIKE\nSPACE"
		button.disabled = false


func _add_title_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(24.0, 22.0)
	panel.custom_minimum_size = Vector2(318.0, 132.0)
	panel.add_theme_stylebox_override(
		"panel", _make_panel_style(Color("#10202be8"), Color("#82c9bd55"))
	)
	root.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	panel.add_child(column)

	var title := Label.new()
	title.text = "HERO TOWN"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#f4f3dc"))
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Island city · Hero Association HQ"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("#91b5b5"))
	column.add_child(subtitle)

	_hero_association_label = Label.new()
	_hero_association_label.add_theme_font_size_override("font_size", 11)
	_hero_association_label.add_theme_color_override("font_color", Color("#e9ca7d"))
	_hero_association_label.text = _hero_association_text()
	column.add_child(_hero_association_label)

	_hero_status_label = Label.new()
	_hero_status_label.text = "CREATE A HERO TO BEGIN"
	_hero_status_label.add_theme_font_size_override("font_size", 11)
	_hero_status_label.add_theme_color_override("font_color", Color("#9eddd1"))
	column.add_child(_hero_status_label)


func _add_top_right_controls(root: Control) -> void:
	var controls := HBoxContainer.new()
	controls.anchor_left = 1.0
	controls.anchor_right = 1.0
	controls.offset_left = -488.0
	controls.offset_right = -24.0
	controls.offset_top = 24.0
	controls.offset_bottom = 74.0
	controls.add_theme_constant_override("separation", 7)
	controls.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(controls)

	var hq_button := Button.new()
	hq_button.text = "HERO HQ"
	hq_button.custom_minimum_size = Vector2(98.0, 48.0)
	hq_button.add_theme_stylebox_override("normal", _make_button_style(true))
	hq_button.add_theme_stylebox_override("hover", _make_button_style(true))
	hq_button.add_theme_color_override("font_color", Color("#f4e5b4"))
	hq_button.add_theme_font_size_override("font_size", 12)
	hq_button.pressed.connect(_on_hero_association_pressed)
	controls.add_child(hq_button)

	var hero_button := Button.new()
	hero_button.text = "HERO"
	hero_button.custom_minimum_size = Vector2(76.0, 48.0)
	hero_button.add_theme_stylebox_override("normal", _make_button_style(false))
	hero_button.add_theme_stylebox_override("hover", _make_button_style(true))
	hero_button.add_theme_color_override("font_color", Color("#f4f3dc"))
	hero_button.add_theme_font_size_override("font_size", 12)
	hero_button.pressed.connect(_on_hero_creation_pressed)
	controls.add_child(hero_button)

	var new_city_button := Button.new()
	new_city_button.text = "NEW CITY"
	new_city_button.custom_minimum_size = Vector2(98.0, 48.0)
	new_city_button.add_theme_stylebox_override("normal", _make_button_style(false))
	new_city_button.add_theme_stylebox_override("hover", _make_button_style(true))
	new_city_button.add_theme_color_override("font_color", Color("#f4f3dc"))
	new_city_button.add_theme_font_size_override("font_size", 12)
	new_city_button.pressed.connect(_on_new_city_pressed)
	controls.add_child(new_city_button)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(102.0, 48.0)
	badge.add_theme_stylebox_override(
		"panel", _make_panel_style(Color("#10202be8"), Color("#77d7ab66"))
	)
	controls.add_child(badge)

	var label := Label.new()
	label.text = "●  ACTIVE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#92e3b8"))
	badge.add_child(label)


func _add_movement_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 24.0
	panel.offset_right = 234.0
	panel.offset_top = -184.0
	panel.offset_bottom = -20.0
	panel.add_theme_stylebox_override(
		"panel", _make_panel_style(Color("#10202be8"), Color("#82c9bd55"))
	)
	root.add_child(panel)

	var pad := Control.new()
	pad.custom_minimum_size = Vector2(194.0, 146.0)
	panel.add_child(pad)
	_add_direction_button(pad, "N", "north", Vector2(70.0, 0.0))
	_add_direction_button(pad, "W", "west", Vector2(20.0, 43.0))
	_add_direction_button(pad, "E", "east", Vector2(120.0, 43.0))
	_add_direction_button(pad, "S", "south", Vector2(70.0, 86.0))

	var hint := Label.new()
	hint.text = "MOVE  ·  WASD / ARROWS"
	hint.position = Vector2(7.0, 129.0)
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color("#a4beb7"))
	pad.add_child(hint)


func _add_direction_button(
	parent: Control, label_text: String, direction: String, position: Vector2
) -> void:
	var button := Button.new()
	button.text = label_text
	button.position = position
	button.custom_minimum_size = Vector2(46.0, 38.0)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("#e7eee4"))
	button.add_theme_stylebox_override("normal", _make_button_style(false))
	button.add_theme_stylebox_override("hover", _make_button_style(true))
	button.button_down.connect(_on_direction_down.bind(direction))
	button.button_up.connect(_on_direction_up.bind(direction))
	parent.add_child(button)
	_move_buttons[direction] = button
	_move_pressed[direction] = false


func _add_power_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -474.0
	panel.offset_right = -24.0
	panel.offset_top = -164.0
	panel.offset_bottom = -82.0
	panel.add_theme_stylebox_override(
		"panel", _make_panel_style(Color("#10202be8"), Color("#82c9bd55"))
	)
	root.add_child(panel)

	_power_container = HBoxContainer.new()
	_power_container.add_theme_constant_override("separation", 6)
	_panel_add_container(panel, _power_container)
	_add_strike_button()


func _panel_add_container(panel: PanelContainer, container: Control) -> void:
	panel.add_child(container)


func _add_strike_button() -> void:
	if _power_container == null:
		return
	_strike_button = Button.new()
	_strike_button.name = "StrikeAction"
	_strike_button.text = "STRIKE\nSPACE"
	_strike_button.custom_minimum_size = Vector2(92.0, 60.0)
	_strike_button.add_theme_font_size_override("font_size", 10)
	_strike_button.add_theme_color_override("font_color", Color("#f4e5b4"))
	_strike_button.add_theme_stylebox_override("normal", _make_button_style(true))
	_strike_button.add_theme_stylebox_override("hover", _make_button_style(true))
	_strike_button.pressed.connect(_on_strike_pressed)
	_power_container.add_child(_strike_button)
	_power_buttons["strike"] = _strike_button


func _add_stats_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -472.0
	panel.offset_right = -24.0
	panel.offset_top = -72.0
	panel.offset_bottom = -20.0
	panel.add_theme_stylebox_override(
		"panel", _make_panel_style(Color("#10202bdc"), Color("#82c9bd44"))
	)
	root.add_child(panel)

	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_size_override("font_size", 11)
	_stats_label.add_theme_color_override("font_color", Color("#d7e3d7"))
	_stats_label.text = _stats_text()
	panel.add_child(_stats_label)


func _on_new_city_pressed() -> void:
	new_city_requested.emit()


func _on_hero_association_pressed() -> void:
	hero_association_requested.emit()


func _on_hero_creation_pressed() -> void:
	hero_creation_requested.emit()


func _on_power_pressed(power_id: String) -> void:
	power_requested.emit(power_id)


func _on_strike_pressed() -> void:
	strike_requested.emit()


func _on_direction_down(direction: String) -> void:
	_move_pressed[direction] = true
	_emit_movement()


func _on_direction_up(direction: String) -> void:
	_move_pressed[direction] = false
	_emit_movement()


func _emit_movement() -> void:
	var axis := Vector2.ZERO
	if bool(_move_pressed.get("east", false)):
		axis.x += 1.0
	if bool(_move_pressed.get("west", false)):
		axis.x -= 1.0
	if bool(_move_pressed.get("south", false)):
		axis.y += 1.0
	if bool(_move_pressed.get("north", false)):
		axis.y -= 1.0
	movement_changed.emit(axis.limit_length(1.0))


func _update_power_button(power_id: String, active: bool, cooldown: float) -> void:
	var button: Button = _power_buttons.get(power_id) as Button
	if button == null:
		return
	var data: Dictionary = _power_data.get(power_id, {})
	var title: String = str(data.get("name", "STRIKE"))
	match power_id:
		"elemental":
			title = _element + " BOLT"
		"super_strength":
			title = "STRENGTH"
		"speed":
			title = "SPEED"
		"teleportation":
			title = "TELEPORT"
		"beast":
			title = "BEAST"
		"flight":
			title = "FLIGHT"
	if cooldown > 0.05 and not active:
		button.text = "%s\n%.1fs" % [title, cooldown]
	else:
		button.text = "%s\n%s" % [title, "ON" if active else str(data.get("slot_key", "USE"))]
	button.disabled = cooldown > 0.05 and not active
	button.add_theme_stylebox_override("normal", _make_button_style(active))
	button.add_theme_stylebox_override("hover", _make_button_style(true))


func _hero_association_text() -> String:
	if _size_name.is_empty():
		return "HERO ASSOCIATION · CONSTRUCTION PENDING"
	return "HERO ASSOCIATION · %d DAILY VISITORS" % _hero_association_visitors


func _stats_text() -> String:
	if _size_name.is_empty():
		return "Choose a map size to begin"
	return (
		"%s %d×%d · %d blocks · %d citizens · %d vehicles"
		% [
			_size_name,
			_size_dimensions.x,
			_size_dimensions.y,
			_block_count,
			_citizen_count,
			_car_count,
		]
	)


func _make_panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(11)
	style.content_margin_left = 8.0
	style.content_margin_top = 6.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 6.0
	return style


func _make_button_style(highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#315548") if highlighted else Color("#10202be8")
	style.border_color = Color("#e0c17d") if highlighted else Color("#82c9bd77")
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.content_margin_left = 7.0
	style.content_margin_top = 5.0
	style.content_margin_right = 7.0
	style.content_margin_bottom = 5.0
	return style
