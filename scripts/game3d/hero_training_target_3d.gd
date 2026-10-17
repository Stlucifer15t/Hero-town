extends Node3D

var _max_health: float = 100.0
var _health: float = 100.0
var _respawn_timer: float = 0.0
var _flash_timer: float = 0.0
var _burn_timer: float = 0.0
var _burn_tick: float = 0.0
var _freeze_timer: float = 0.0
var _shock_timer: float = 0.0
var _knockback: Vector3 = Vector3.ZERO
var _body_material: StandardMaterial3D
var _glow_material: StandardMaterial3D
var _body_node: MeshInstance3D
var _collision_body: StaticBody3D
var _health_label: Label3D


func _ready() -> void:
	add_to_group("hero_targets_3d")
	_build_target()


func get_health() -> float:
	return _health


func get_max_health() -> float:
	return _max_health


func get_target_position() -> Vector3:
	return global_position + Vector3(0.0, 1.12, 0.0)


func get_effect_status() -> String:
	if _burn_timer > 0.0:
		return "burning"
	if _freeze_timer > 0.0:
		return "frozen"
	if _shock_timer > 0.0:
		return "shocked"
	return "normal"


func take_damage(
	amount: float, direction: Vector3 = Vector3.ZERO, element: String = "impact"
) -> void:
	if not visible or amount <= 0.0:
		return
	_health = maxf(0.0, _health - amount)
	_flash_timer = 0.18
	_knockback = direction.normalized() * minf(amount * 0.025, 1.8)
	match element:
		"fire":
			_burn_timer = 2.2
			_burn_tick = 0.0
		"ice":
			_freeze_timer = 1.8
		"lightning":
			_shock_timer = 0.7
	_update_visuals()
	if _health <= 0.0:
		visible = false
		_collision_body.collision_layer = 0
		_collision_body.collision_mask = 0
		_respawn_timer = 4.0
		_burn_timer = 0.0
		_freeze_timer = 0.0
		_shock_timer = 0.0
		_knockback = Vector3.ZERO


func reset_target() -> void:
	_health = _max_health
	visible = true
	_collision_body.collision_layer = 1
	_collision_body.collision_mask = 1
	_burn_timer = 0.0
	_burn_tick = 0.0
	_freeze_timer = 0.0
	_shock_timer = 0.0
	_flash_timer = 0.0
	_knockback = Vector3.ZERO
	_update_visuals()


func _process(delta: float) -> void:
	if not visible:
		_respawn_timer = maxf(0.0, _respawn_timer - delta)
		if _respawn_timer <= 0.0:
			reset_target()
		return
	_flash_timer = maxf(0.0, _flash_timer - delta)
	_freeze_timer = maxf(0.0, _freeze_timer - delta)
	_shock_timer = maxf(0.0, _shock_timer - delta)
	_burn_timer = maxf(0.0, _burn_timer - delta)
	if _burn_timer > 0.0:
		_burn_tick += delta
		if _burn_tick >= 0.5:
			_burn_tick -= 0.5
			_health = maxf(0.0, _health - 4.0)
			if _health <= 0.0:
				visible = false
				_collision_body.collision_layer = 0
				_collision_body.collision_mask = 0
				_respawn_timer = 4.0
				_burn_timer = 0.0
				_freeze_timer = 0.0
				_shock_timer = 0.0
				_knockback = Vector3.ZERO
	_knockback = _knockback.move_toward(Vector3.ZERO, delta * 6.5)
	position += _knockback * delta
	_update_visuals()


func _build_target() -> void:
	_body_material = StandardMaterial3D.new()
	_body_material.albedo_color = Color("#d38b55")
	_body_material.roughness = 0.92
	_body_material.metallic = 0.08
	_glow_material = StandardMaterial3D.new()
	_glow_material.albedo_color = Color("#f1cd72")
	_glow_material.emission_enabled = true
	_glow_material.emission = Color("#efb849")
	_glow_material.roughness = 0.7

	_collision_body = StaticBody3D.new()
	_collision_body.name = "DummyCollision"
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.7
	collision.shape = capsule
	collision.position.y = 0.84
	_collision_body.add_child(collision)
	add_child(_collision_body)

	_body_node = MeshInstance3D.new()
	_body_node.name = "TargetBody"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.34
	body_mesh.height = 1.28
	body_mesh.radial_segments = 7
	_body_node.mesh = body_mesh
	_body_node.position.y = 0.9
	_body_node.material_override = _body_material
	add_child(_body_node)

	var head := MeshInstance3D.new()
	head.name = "TargetHead"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.25
	head_mesh.height = 0.5
	head_mesh.radial_segments = 7
	head_mesh.rings = 3
	head.mesh = head_mesh
	head.position.y = 1.72
	head.material_override = _make_material("#d8a879")
	add_child(head)

	var core := MeshInstance3D.new()
	core.name = "TargetCore"
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.11
	core_mesh.height = 0.22
	core_mesh.radial_segments = 6
	core_mesh.rings = 3
	core.mesh = core_mesh
	core.position = Vector3(0.0, 1.08, -0.31)
	core.material_override = _glow_material
	add_child(core)

	_health_label = Label3D.new()
	_health_label.name = "HealthLabel"
	_health_label.text = "TRAINING DRONE  ·  100%"
	_health_label.font_size = 34
	_health_label.pixel_size = 0.008
	_health_label.position = Vector3(0.0, 2.24, 0.0)
	_health_label.modulate = Color("#f4e8c7")
	_health_label.outline_size = 8
	_health_label.outline_modulate = Color("#26343a")
	_health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_health_label)
	_update_visuals()


func _update_visuals() -> void:
	if _body_material == null:
		return
	var base_color := Color("#d38b55")
	var status_color := base_color
	if _freeze_timer > 0.0:
		status_color = Color("#78c9dc")
	elif _burn_timer > 0.0:
		status_color = Color("#e47445")
	elif _shock_timer > 0.0:
		status_color = Color("#e6cb5e")
	if _flash_timer > 0.0:
		status_color = status_color.lerp(Color.WHITE, 0.62)
	_body_material.albedo_color = status_color
	var health_percent := 0 if _max_health <= 0.0 else roundi(_health / _max_health * 100.0)
	_health_label.text = "TRAINING DRONE  ·  %d%%" % health_percent
	_health_label.modulate = Color("#b9ecf4") if _freeze_timer > 0.0 else Color("#f4e8c7")


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
