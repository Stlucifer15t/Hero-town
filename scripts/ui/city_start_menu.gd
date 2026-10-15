extends CanvasLayer

signal city_size_confirmed(preset_index: int)
signal cancelled

const CityGenerator = preload("res://scripts/city/city_generator.gd")

var _can_cancel: bool = false
var _selected_index: int = 2
var _size_buttons: Array[Button] = []
var _selected_badges: Array[Label] = []


func configure(can_cancel: bool, selected_index: int) -> void:
	_can_cancel = can_cancel
	_selected_index = clampi(selected_index, 0, CityGenerator.get_map_presets().size() - 1)


func _ready() -> void:
	layer = 20
	_build_menu()


func _build_menu() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color("#07131de8")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center := CenterContainer.new()
	center.name = "MenuCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.name = "SizePanel"
	panel.custom_minimum_size = Vector2(1050.0, 500.0)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	column.add_child(header)

	var heading_column := VBoxContainer.new()
	heading_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_column.add_theme_constant_override("separation", 3)
	header.add_child(heading_column)

	var heading := Label.new()
	heading.text = "START A NEW CITY"
	heading.add_theme_font_size_override("font_size", 27)
	heading.add_theme_color_override("font_color", Color("#f4f3dc"))
	heading_column.add_child(heading)

	var subtitle := Label.new()
	subtitle.text = "Choose a map size · island districts, waterfront roads, ring route and parks"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#9ab9b7"))
	heading_column.add_child(subtitle)

	if _can_cancel:
		var cancel_button := Button.new()
		cancel_button.text = "BACK"
		cancel_button.custom_minimum_size = Vector2(100.0, 42.0)
		cancel_button.add_theme_stylebox_override("normal", _make_button_style(false))
		cancel_button.add_theme_stylebox_override("hover", _make_button_style(true))
		cancel_button.add_theme_color_override("font_color", Color("#dce6dc"))
		cancel_button.pressed.connect(_on_cancel_pressed)
		header.add_child(cancel_button)

	var option_row := HBoxContainer.new()
	option_row.add_theme_constant_override("separation", 12)
	option_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(option_row)

	var presets: Array[Dictionary] = CityGenerator.get_map_presets()
	for preset_index: int in range(presets.size()):
		var preset: Dictionary = presets[preset_index]
		var size_button := Button.new()
		size_button.name = "MapSize_%d" % preset_index
		size_button.text = ""
		size_button.custom_minimum_size = Vector2(220.0, 190.0)
		size_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		size_button.focus_mode = Control.FOCUS_ALL
		size_button.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.0))
		size_button.pressed.connect(_on_size_button_pressed.bind(preset_index))
		option_row.add_child(size_button)
		_size_buttons.append(size_button)

		var contents := VBoxContainer.new()
		contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contents.add_theme_constant_override("separation", 7)
		contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_button.add_child(contents)

		var selected_badge := Label.new()
		selected_badge.text = "SELECTED"
		selected_badge.add_theme_font_size_override("font_size", 11)
		selected_badge.add_theme_color_override("font_color", Color("#f2cf83"))
		selected_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(selected_badge)
		_selected_badges.append(selected_badge)

		var name_label := Label.new()
		name_label.text = str(preset["name"])
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", Color("#f4f3dc"))
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(name_label)

		var block_count: int = int(preset["blocks_wide"]) * int(preset["blocks_long"])
		var size_label := Label.new()
		size_label.text = "%d × %d blocks" % [preset["blocks_wide"], preset["blocks_long"]]
		size_label.add_theme_font_size_override("font_size", 16)
		size_label.add_theme_color_override("font_color", Color("#c5d7ca"))
		size_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(size_label)

		var count_label := Label.new()
		count_label.text = "Up to %d city blocks" % block_count
		count_label.add_theme_font_size_override("font_size", 13)
		count_label.add_theme_color_override("font_color", Color("#90aaa9"))
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(count_label)

		var description := Label.new()
		description.text = str(preset["description"])
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 13)
		description.add_theme_color_override("font_color", Color("#b1c3bd"))
		description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		description.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(description)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	footer.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(footer)

	var hint := Label.new()
	hint.text = "Drag to pan · pinch or scroll to zoom"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("#8eaaa8"))
	footer.add_child(hint)

	var start_button := Button.new()
	start_button.name = "StartCityButton"
	start_button.text = "BUILD CITY"
	start_button.custom_minimum_size = Vector2(210.0, 50.0)
	start_button.add_theme_stylebox_override("normal", _make_button_style(true))
	start_button.add_theme_stylebox_override("hover", _make_button_style(true, true))
	start_button.add_theme_color_override("font_color", Color("#142326"))
	start_button.add_theme_font_size_override("font_size", 16)
	start_button.pressed.connect(_on_start_pressed)
	footer.add_child(start_button)

	_update_selection()


func _on_size_button_pressed(preset_index: int) -> void:
	_selected_index = preset_index
	_update_selection()


func _on_start_pressed() -> void:
	city_size_confirmed.emit(_selected_index)
	queue_free()


func _on_cancel_pressed() -> void:
	cancelled.emit()
	queue_free()


func _update_selection() -> void:
	for index: int in range(_size_buttons.size()):
		var selected: bool = index == _selected_index
		_size_buttons[index].add_theme_stylebox_override("normal", _make_button_style(selected))
		_size_buttons[index].add_theme_stylebox_override(
			"hover", _make_button_style(selected, true)
		)
		_selected_badges[index].visible = selected


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#10222bec")
	style.border_color = Color("#82c9bd88")
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style


func _make_button_style(selected: bool, hovered: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#244039") if selected else Color("#172d35")
	if hovered:
		style.bg_color = style.bg_color.lightened(0.09)
	style.border_color = Color("#e7c47b") if selected else Color("#598079")
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(11)
	style.content_margin_left = 12.0
	style.content_margin_top = 12.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 12.0
	return style
