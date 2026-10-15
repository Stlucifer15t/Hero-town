extends CanvasLayer

signal new_city_requested

## Compact mobile-safe city HUD with a persistent New City entry point.
var _stats_label: Label
var _citizen_count: int = 0
var _car_count: int = 0
var _block_count: int = 0
var _size_name: String = ""
var _size_dimensions: Vector2i = Vector2i.ZERO


func _ready() -> void:
	layer = 5
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	_add_title_panel(root)
	_add_top_right_controls(root)
	_add_controls_panel(root)
	_add_stats_panel(root)


func set_city_stats(
	citizen_count: int,
	car_count: int,
	block_count: int,
	size_name: String,
	size_dimensions: Vector2i
) -> void:
	_citizen_count = citizen_count
	_car_count = car_count
	_block_count = block_count
	_size_name = size_name
	_size_dimensions = size_dimensions
	if _stats_label != null:
		_stats_label.text = _stats_text()


func _add_title_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(24.0, 22.0)
	panel.custom_minimum_size = Vector2(292.0, 88.0)
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
	subtitle.text = "A living TheoTown-inspired island city"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("#91b5b5"))
	column.add_child(subtitle)


func _add_top_right_controls(root: Control) -> void:
	var controls := HBoxContainer.new()
	controls.anchor_left = 1.0
	controls.anchor_right = 1.0
	controls.offset_left = -376.0
	controls.offset_right = -24.0
	controls.offset_top = 24.0
	controls.offset_bottom = 74.0
	controls.add_theme_constant_override("separation", 10)
	controls.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(controls)

	var new_city_button := Button.new()
	new_city_button.text = "NEW CITY"
	new_city_button.custom_minimum_size = Vector2(142.0, 48.0)
	new_city_button.add_theme_stylebox_override("normal", _make_button_style(false))
	new_city_button.add_theme_stylebox_override("hover", _make_button_style(true))
	new_city_button.add_theme_color_override("font_color", Color("#f4f3dc"))
	new_city_button.add_theme_font_size_override("font_size", 14)
	new_city_button.pressed.connect(_on_new_city_pressed)
	controls.add_child(new_city_button)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(172.0, 48.0)
	badge.add_theme_stylebox_override(
		"panel", _make_panel_style(Color("#10202be8"), Color("#77d7ab66"))
	)
	controls.add_child(badge)

	var label := Label.new()
	label.text = "●  CITY ACTIVE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("#92e3b8"))
	badge.add_child(label)


func _add_controls_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 24.0
	panel.offset_right = 346.0
	panel.offset_top = -72.0
	panel.offset_bottom = -20.0
	panel.add_theme_stylebox_override(
		"panel", _make_panel_style(Color("#10202bdc"), Color("#82c9bd44"))
	)
	root.add_child(panel)

	var label := Label.new()
	label.text = "DRAG TO PAN  ·  PINCH / SCROLL TO ZOOM"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#d7e3d7"))
	panel.add_child(label)


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
	_stats_label.add_theme_font_size_override("font_size", 12)
	_stats_label.add_theme_color_override("font_color", Color("#d7e3d7"))
	_stats_label.text = _stats_text()
	panel.add_child(_stats_label)


func _on_new_city_pressed() -> void:
	new_city_requested.emit()


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
	style.content_margin_left = 13.0
	style.content_margin_top = 8.0
	style.content_margin_right = 13.0
	style.content_margin_bottom = 8.0
	return style


func _make_button_style(highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#315548") if highlighted else Color("#10202be8")
	style.border_color = Color("#e0c17d") if highlighted else Color("#82c9bd77")
	style.set_border_width_all(1)
	style.set_corner_radius_all(11)
	style.content_margin_left = 13.0
	style.content_margin_top = 8.0
	style.content_margin_right = 13.0
	style.content_margin_bottom = 8.0
	return style
