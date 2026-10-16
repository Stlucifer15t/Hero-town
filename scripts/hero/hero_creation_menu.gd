extends CanvasLayer

signal hero_created(profile: Dictionary)
signal cancelled

const HeroPowerCatalog = preload("res://scripts/hero/hero_power_catalog.gd")
const SUIT_PRESETS: Array[Dictionary] = [
	{"name": "TIDAL", "suit": "#45bcae", "cape": "#e7645d"},
	{"name": "NOVA", "suit": "#527fe5", "cape": "#edcb69"},
	{"name": "EMBER", "suit": "#df674f", "cape": "#f3c85a"},
	{"name": "NIGHT", "suit": "#554c83", "cape": "#bd9aff"},
	{"name": "MOSS", "suit": "#568b61", "cape": "#e2d8b2"},
	{"name": "STORM", "suit": "#d7dde6", "cape": "#6aa7d3"},
]

var _can_cancel: bool = false
var _initial_profile: Dictionary = {}
var _selected_powers: Array[String] = []
var _selected_preset: int = 0
var _selected_element: String = "fire"
var _name_field: LineEdit
var _element_picker: OptionButton
var _element_row: HBoxContainer
var _power_buttons: Array[Button] = []
var _preset_buttons: Array[Button] = []
var _status_label: Label
var _create_button: Button


func configure(can_cancel: bool, profile: Dictionary = {}) -> void:
	_can_cancel = can_cancel
	_initial_profile = profile.duplicate(true)
	var default_powers: Array = ["elemental", "flight"]
	var requested_powers: Array = _initial_profile.get("powers", default_powers)
	_selected_powers = HeroPowerCatalog.sanitize_loadout(requested_powers)
	_selected_preset = _find_preset_index(str(_initial_profile.get("suit_color", "#45bcae")))
	_selected_element = str(_initial_profile.get("element", "fire"))


func _ready() -> void:
	layer = 25
	_build_menu()


func _build_menu() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color("#07131ded")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.name = "HeroCreationPanel"
	panel.custom_minimum_size = Vector2(1120.0, 630.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)

	var header_copy := VBoxContainer.new()
	header_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_copy.add_theme_constant_override("separation", 2)
	header.add_child(header_copy)

	var title := Label.new()
	title.text = "CREATE YOUR HERO"
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("#f4f3dc"))
	header_copy.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Build a look, pick up to three powers, then use them in the city."
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("#9ab9b7"))
	header_copy.add_child(subtitle)

	if _can_cancel:
		var cancel_button := Button.new()
		cancel_button.text = "BACK"
		cancel_button.custom_minimum_size = Vector2(90.0, 42.0)
		cancel_button.add_theme_stylebox_override("normal", _button_style(false))
		cancel_button.add_theme_stylebox_override("hover", _button_style(true))
		cancel_button.add_theme_color_override("font_color", Color("#e7eee4"))
		cancel_button.pressed.connect(_on_cancel_pressed)
		header.add_child(cancel_button)

	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 12)
	column.add_child(identity_row)

	var callsign_label := Label.new()
	callsign_label.text = "CALLSIGN"
	callsign_label.custom_minimum_size.x = 104.0
	callsign_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	callsign_label.add_theme_font_size_override("font_size", 13)
	callsign_label.add_theme_color_override("font_color", Color("#d9e4d8"))
	identity_row.add_child(callsign_label)

	_name_field = LineEdit.new()
	_name_field.placeholder_text = "Your hero name"
	_name_field.text = str(_initial_profile.get("name", "Nova"))
	_name_field.custom_minimum_size = Vector2(260.0, 40.0)
	_name_field.max_length = 18
	identity_row.add_child(_name_field)

	var loadout_hint := Label.new()
	loadout_hint.text = "SELECT POWERS  ·  1–3 EQUIPPED"
	loadout_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loadout_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	loadout_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loadout_hint.add_theme_font_size_override("font_size", 13)
	loadout_hint.add_theme_color_override("font_color", Color("#e9ca7d"))
	identity_row.add_child(loadout_hint)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)
	for power: Dictionary in HeroPowerCatalog.get_all_powers():
		var button := Button.new()
		button.name = "Power_%s" % str(power["id"])
		button.custom_minimum_size = Vector2(330.0, 102.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_stylebox_override("normal", _button_style(false))
		button.add_theme_stylebox_override("hover", _button_style(true))
		button.add_theme_color_override("font_color", Color("#f4f3dc"))
		button.pressed.connect(_on_power_pressed.bind(str(power["id"])))
		grid.add_child(button)
		_power_buttons.append(button)

		var card_copy := VBoxContainer.new()
		card_copy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card_copy.add_theme_constant_override("separation", 3)
		card_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(card_copy)

		var power_title := Label.new()
		power_title.text = str(power["name"])
		power_title.add_theme_font_size_override("font_size", 15)
		power_title.add_theme_color_override("font_color", Color(str(power["color"])))
		power_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_copy.add_child(power_title)

		var power_tagline := Label.new()
		power_tagline.text = str(power["tagline"])
		power_tagline.add_theme_font_size_override("font_size", 12)
		power_tagline.add_theme_color_override("font_color", Color("#f4f3dc"))
		power_tagline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_copy.add_child(power_tagline)

		var description := Label.new()
		description.text = str(power["description"])
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 11)
		description.add_theme_color_override("font_color", Color("#a9c1bd"))
		description.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_copy.add_child(description)

	var element_row := HBoxContainer.new()
	element_row.add_theme_constant_override("separation", 10)
	column.add_child(element_row)
	_element_row = element_row

	var element_label := Label.new()
	element_label.text = "ELEMENTAL AFFINITY"
	element_label.custom_minimum_size.x = 165.0
	element_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	element_label.add_theme_font_size_override("font_size", 12)
	element_label.add_theme_color_override("font_color", Color("#d6e4dd"))
	element_row.add_child(element_label)

	_element_picker = OptionButton.new()
	_element_picker.custom_minimum_size = Vector2(180.0, 36.0)
	for element: Dictionary in HeroPowerCatalog.get_all_elements():
		_element_picker.add_item(str(element["name"]))
	_element_picker.item_selected.connect(_on_element_selected)
	element_row.add_child(_element_picker)

	var element_hint := Label.new()
	element_hint.text = "Fire burns · Ice freezes · Lightning chains"
	element_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	element_hint.add_theme_font_size_override("font_size", 12)
	element_hint.add_theme_color_override("font_color", Color("#9ab9b7"))
	element_row.add_child(element_hint)

	var appearance_row := HBoxContainer.new()
	appearance_row.add_theme_constant_override("separation", 8)
	column.add_child(appearance_row)

	var appearance_label := Label.new()
	appearance_label.text = "SUIT + CAPE"
	appearance_label.custom_minimum_size.x = 165.0
	appearance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	appearance_label.add_theme_font_size_override("font_size", 12)
	appearance_label.add_theme_color_override("font_color", Color("#d6e4dd"))
	appearance_row.add_child(appearance_label)

	for preset_index: int in range(SUIT_PRESETS.size()):
		var preset: Dictionary = SUIT_PRESETS[preset_index]
		var preset_button := Button.new()
		preset_button.text = str(preset["name"])
		preset_button.custom_minimum_size = Vector2(96.0, 34.0)
		preset_button.add_theme_color_override("font_color", Color("#f4f3dc"))
		preset_button.add_theme_font_size_override("font_size", 10)
		preset_button.add_theme_stylebox_override(
			"normal", _preset_style(preset_index == _selected_preset, preset)
		)
		preset_button.add_theme_stylebox_override("hover", _preset_style(true, preset))
		preset_button.pressed.connect(_on_preset_pressed.bind(preset_index))
		appearance_row.add_child(preset_button)
		_preset_buttons.append(preset_button)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", Color("#e9ca7d"))
	column.add_child(_status_label)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(footer)

	var loadout_label := Label.new()
	loadout_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loadout_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	loadout_label.add_theme_font_size_override("font_size", 12)
	loadout_label.add_theme_color_override("font_color", Color("#b1c8bf"))
	footer.add_child(loadout_label)
	_status_label.set_meta("loadout_label", loadout_label)

	_create_button = Button.new()
	_create_button.text = "CREATE HERO"
	_create_button.custom_minimum_size = Vector2(190.0, 46.0)
	_create_button.add_theme_stylebox_override("normal", _button_style(true))
	_create_button.add_theme_stylebox_override("hover", _button_style(true))
	_create_button.add_theme_color_override("font_color", Color("#f4e5b4"))
	_create_button.add_theme_font_size_override("font_size", 15)
	_create_button.pressed.connect(_on_create_pressed)
	footer.add_child(_create_button)

	_update_controls()


func _on_power_pressed(power_id: String) -> void:
	if _selected_powers.has(power_id):
		_selected_powers.erase(power_id)
		_status_label.text = ""
	elif _selected_powers.size() < HeroPowerCatalog.MAX_EQUIPPED_POWERS:
		_selected_powers.append(power_id)
		_status_label.text = ""
	else:
		_status_label.text = "Your loadout is full. Remove a power before adding another."
	_update_controls()


func _on_preset_pressed(preset_index: int) -> void:
	_selected_preset = preset_index
	_update_controls()


func _on_element_selected(index: int) -> void:
	var elements: Array[Dictionary] = HeroPowerCatalog.get_all_elements()
	if index >= 0 and index < elements.size():
		_selected_element = str(elements[index]["id"])
	_update_controls()


func _on_create_pressed() -> void:
	if _selected_powers.is_empty():
		_status_label.text = "Choose at least one power before creating your hero."
		return
	var profile := {
		"name":
		_name_field.text.strip_edges() if not _name_field.text.strip_edges().is_empty() else "Nova",
		"suit_color": str(SUIT_PRESETS[_selected_preset]["suit"]),
		"cape_color": str(SUIT_PRESETS[_selected_preset]["cape"]),
		"powers": _selected_powers.duplicate(),
		"element": _selected_element_id(),
	}
	hero_created.emit(profile)
	queue_free()


func _on_cancel_pressed() -> void:
	cancelled.emit()
	queue_free()


func _selected_element_id() -> String:
	var selected_index: int = maxi(0, _element_picker.selected)
	var elements: Array[Dictionary] = HeroPowerCatalog.get_all_elements()
	return str(elements[selected_index]["id"])


func _find_preset_index(suit_color: String) -> int:
	for index: int in range(SUIT_PRESETS.size()):
		if str(SUIT_PRESETS[index]["suit"]) == suit_color:
			return index
	return 0


func _update_controls() -> void:
	if _status_label == null:
		return
	for index: int in range(_power_buttons.size()):
		var power: Dictionary = HeroPowerCatalog.get_all_powers()[index]
		var power_id: String = str(power["id"])
		var selected: bool = _selected_powers.has(power_id)
		_power_buttons[index].add_theme_stylebox_override("normal", _button_style(selected))
		_power_buttons[index].add_theme_stylebox_override("hover", _button_style(true))
		var card_copy: VBoxContainer = _power_buttons[index].get_child(0) as VBoxContainer
		var title: Label = card_copy.get_child(0) as Label
		title.text = (
			("✓ %d  ·  " % (_selected_powers.find(power_id) + 1) if selected else "")
			+ str(power["name"])
		)
		_power_buttons[index].modulate = Color.WHITE if selected else Color(0.86, 0.92, 0.92, 1.0)
	var has_elemental: bool = _selected_powers.has("elemental")
	_element_row.visible = has_elemental
	_element_picker.select(_find_element_index(_selected_element))
	for index: int in range(_preset_buttons.size()):
		_preset_buttons[index].add_theme_stylebox_override(
			"normal", _preset_style(index == _selected_preset, SUIT_PRESETS[index])
		)
	_create_button.disabled = _selected_powers.is_empty()
	var loadout_label: Label = _status_label.get_meta("loadout_label") as Label
	var selected_names: Array[String] = []
	for power_id: String in _selected_powers:
		selected_names.append(str(HeroPowerCatalog.get_power(power_id)["name"]))
	loadout_label.text = (
		"%d / %d powers  ·  %s"
		% [
			_selected_powers.size(),
			HeroPowerCatalog.MAX_EQUIPPED_POWERS,
			"  +  ".join(selected_names),
		]
	)


func _find_element_index(element_id: String) -> int:
	var elements: Array[Dictionary] = HeroPowerCatalog.get_all_elements()
	for index: int in range(elements.size()):
		if str(elements[index]["id"]) == element_id:
			return index
	return 0


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#10222bf2")
	style.border_color = Color("#82c9bd99")
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style


func _button_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#28463e") if selected else Color("#172d35")
	style.border_color = Color("#e7c47b") if selected else Color("#598079")
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 11.0
	style.content_margin_top = 7.0
	style.content_margin_right = 11.0
	style.content_margin_bottom = 7.0
	return style


func _preset_style(selected: bool, preset: Dictionary) -> StyleBoxFlat:
	var style := _button_style(selected)
	style.bg_color = Color(str(preset["suit"])).darkened(0.38)
	return style
