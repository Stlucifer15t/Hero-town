extends CanvasLayer

## Non-interactive, mobile-safe prototype HUD.
var _stats_label: Label
var _citizen_count: int = 0
var _car_count: int = 0


func _ready() -> void:
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_add_title_panel(root)
	_add_live_badge(root)
	_add_controls_panel(root)
	_add_stats_panel(root)


func set_city_stats(citizen_count: int, car_count: int) -> void:
	_citizen_count = citizen_count
	_car_count = car_count
	if _stats_label != null:
		_stats_label.text = _stats_text()


func _add_title_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(24.0, 22.0)
	panel.custom_minimum_size = Vector2(294.0, 98.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override(
		"panel", _make_panel_style(Color("#10202be8"), Color("#82c9bd55"))
	)
	root.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)

	var title := Label.new()
	title.text = "HERO TOWN"
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("#f4f3dc"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "A living isometric city"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#91b5b5"))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(subtitle)


func _add_live_badge(root: Control) -> void:
	var badge := PanelContainer.new()
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.offset_left = -202.0
	badge.offset_right = -24.0
	badge.offset_top = 24.0
	badge.offset_bottom = 74.0
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override(
		"panel", _make_panel_style(Color("#10202be8"), Color("#77d7ab66"))
	)
	root.add_child(badge)

	var label := Label.new()
	label.text = "●  CITY ACTIVE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("#92e3b8"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)


func _add_controls_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 24.0
	panel.offset_right = 360.0
	panel.offset_top = -78.0
	panel.offset_bottom = -22.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override(
		"panel", _make_panel_style(Color("#10202bdc"), Color("#82c9bd44"))
	)
	root.add_child(panel)

	var label := Label.new()
	label.text = "DRAG TO PAN    ·    PINCH TO ZOOM"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("#d7e3d7"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)


func _add_stats_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -360.0
	panel.offset_right = -24.0
	panel.offset_top = -78.0
	panel.offset_bottom = -22.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override(
		"panel", _make_panel_style(Color("#10202bdc"), Color("#82c9bd44"))
	)
	root.add_child(panel)

	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_size_override("font_size", 13)
	_stats_label.add_theme_color_override("font_color", Color("#d7e3d7"))
	_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_label.text = _stats_text()
	panel.add_child(_stats_label)


func _stats_text() -> String:
	return "%d citizens  ·  %d cars  ·  16 city blocks" % [_citizen_count, _car_count]


func _make_panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 15.0
	style.content_margin_top = 10.0
	style.content_margin_right = 15.0
	style.content_margin_bottom = 10.0
	return style
