extends RefCounted

const HeroPlayer3D = preload("res://scripts/game3d/hero_player_3d.gd")
const GRASS_TEXTURE: Texture2D = preload("res://assets/pixel/grass_meadow.png")


static func add_preview(
	parent: VBoxContainer, profile: Dictionary, preset: Dictionary
) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 13)
	parent.add_child(row)

	var frame := PanelContainer.new()
	frame.name = "HeroPreviewFrame"
	frame.custom_minimum_size = Vector2(152.0, 158.0)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color("#142931")
	frame_style.border_color = Color("#c8b977")
	frame_style.set_border_width_all(1)
	frame_style.set_corner_radius_all(10)
	frame.add_theme_stylebox_override("panel", frame_style)
	row.add_child(frame)

	var viewport_container := SubViewportContainer.new()
	viewport_container.name = "HeroPreviewViewportContainer"
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(viewport_container)

	var viewport := SubViewport.new()
	viewport.name = "HeroPreviewViewport"
	viewport.size = Vector2i(240, 250)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)

	var preview_world := Node3D.new()
	preview_world.name = "PreviewWorld"
	viewport.add_child(preview_world)
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#243c46")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c6d3cf")
	environment.ambient_light_energy = 0.8
	world_environment.environment = environment
	preview_world.add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.rotation = Vector3(deg_to_rad(-32.0), deg_to_rad(24.0), 0.0)
	light.light_color = Color("#ffe4bd")
	light.light_energy = 1.35
	preview_world.add_child(light)

	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(5.0, 5.0)
	floor.mesh = floor_mesh
	floor.position.y = -0.035
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_texture = GRASS_TEXTURE
	floor_material.albedo_color = Color("#c4d7ba")
	floor_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	floor_material.texture_repeat = BaseMaterial3D.TEXTURE_REPEAT_ENABLED
	floor_material.uv1_scale = Vector3(3.0, 3.0, 1.0)
	floor_material.roughness = 1.0
	floor.material_override = floor_material
	preview_world.add_child(floor)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 2.05, -4.8)
	camera.fov = 42.0
	camera.current = true
	camera.look_at(Vector3(0.0, 1.08, 0.0), Vector3.UP)
	preview_world.add_child(camera)

	var preview_hero: CharacterBody3D = HeroPlayer3D.new() as CharacterBody3D
	preview_hero.name = "HeroModelPreview"
	preview_world.add_child(preview_hero)
	preview_hero.call("configure", profile, Vector2(2.0, 2.0))
	preview_hero.call("set_gameplay_enabled", false)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	copy.add_theme_constant_override("separation", 5)
	row.add_child(copy)
	var heading := Label.new()
	heading.text = "HERO PREVIEW"
	heading.add_theme_font_size_override("font_size", 10)
	heading.add_theme_color_override("font_color", Color("#dfd19b"))
	copy.add_child(heading)
	var name_label := Label.new()
	name_label.name = "PreviewCallsign"
	name_label.text = str(profile.get("name", "Nova")).to_upper()
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color("#f3f0df"))
	copy.add_child(name_label)
	var color_label := Label.new()
	color_label.name = "PreviewPalette"
	color_label.text = "%s SUIT  ·  %s CAPE" % [str(preset["name"]), str(preset["name"])]
	color_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	color_label.add_theme_font_size_override("font_size", 11)
	color_label.add_theme_color_override("font_color", Color("#b8cbc3"))
	copy.add_child(color_label)
	var hint := Label.new()
	hint.text = "Your hero appears in the city in this colorway."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color("#9eb6b1"))
	copy.add_child(hint)
	return {"hero": preview_hero, "name_label": name_label, "color_label": color_label}
