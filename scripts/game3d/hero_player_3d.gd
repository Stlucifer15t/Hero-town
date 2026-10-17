extends CharacterBody3D

const HeroPowerCatalog = preload("res://scripts/hero/hero_power_catalog.gd")
const SUIT_WEAVE_TEXTURE: Texture2D = preload("res://assets/pixel/suit_weave.png")
const CAPE_WEAVE_TEXTURE: Texture2D = preload("res://assets/pixel/cape_weave.png")
const HERO_CREST_TEXTURE: Texture2D = preload("res://assets/pixel/hero_town_crest.png")

const WALK_SPEED: float = 4.6
const SPRINT_MULTIPLIER: float = 1.9
const FLIGHT_MULTIPLIER: float = 1.42
const BEAST_MULTIPLIER: float = 1.22

var _profile: Dictionary = {}
var _hero_name: String = "Nova"
var _suit_color: Color = Color("#45bcae")
var _cape_color: Color = Color("#e7645d")
var _element: String = "fire"
var _equipped_powers: Array[String] = []
var _virtual_axis: Vector2 = Vector2.ZERO
var _last_direction: Vector3 = Vector3.FORWARD
var _cooldowns: Dictionary = {}
var _park_bounds: Vector2 = Vector2(48.0, 68.0)
var _gameplay_enabled: bool = false
var _speed_active: bool = false
var _flight_active: bool = false
var _beast_active: bool = false
var _strike_cooldown: float = 0.0
var _flight_height: float = 0.0
var _time: float = 0.0
var _visual_root: Node3D
var _torso_material: StandardMaterial3D
var _cape_material: StandardMaterial3D
var _aura: MeshInstance3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _projectiles: Array[Dictionary] = []


func configure(profile: Dictionary, park_bounds: Vector2 = Vector2(48.0, 68.0)) -> void:
	_profile = profile.duplicate(true)
	_hero_name = str(_profile.get("name", "Nova")).strip_edges()
	if _hero_name.is_empty():
		_hero_name = "Nova"
	_suit_color = Color(str(_profile.get("suit_color", "#45bcae")))
	_cape_color = Color(str(_profile.get("cape_color", "#e7645d")))
	_element = str(_profile.get("element", "fire"))
	var powers: Array = _profile.get("powers", ["elemental", "flight"])
	_equipped_powers = HeroPowerCatalog.sanitize_loadout(powers)
	_park_bounds = park_bounds
	_cooldowns.clear()
	_strike_cooldown = 0.0
	_speed_active = false
	_flight_active = false
	_beast_active = false
	_flight_height = 0.0
	position.y = 0.0
	collision_mask = 1
	_virtual_axis = Vector2.ZERO
	_apply_profile_look()


func set_gameplay_enabled(enabled: bool) -> void:
	_gameplay_enabled = enabled
	if not enabled:
		_virtual_axis = Vector2.ZERO
		velocity = Vector3.ZERO


func set_virtual_movement(axis: Vector2) -> void:
	_virtual_axis = axis.limit_length(1.0)


func get_hero_name() -> String:
	return _hero_name


func get_facing_direction() -> Vector3:
	return _last_direction.normalized()


func get_equipped_powers() -> Array[String]:
	return _equipped_powers.duplicate()


func has_power(power_id: String) -> bool:
	return _equipped_powers.has(power_id)


func get_element() -> String:
	return _element


func is_power_active(power_id: String) -> bool:
	match power_id:
		"speed":
			return _speed_active
		"flight":
			return _flight_active
		"beast":
			return _beast_active
	return false


func get_power_cooldown(power_id: String) -> float:
	return maxf(0.0, float(_cooldowns.get(power_id, 0.0)))


func get_strike_cooldown() -> float:
	return maxf(0.0, _strike_cooldown)


func get_status_text() -> String:
	var states: Array[String] = []
	if _flight_active:
		states.append("AIRBORNE")
	if _speed_active:
		states.append("SUPER SPEED")
	if _beast_active:
		states.append("BEAST FORM")
	if states.is_empty():
		states.append("ON PATROL")
	return "%s  ·  %s" % [_hero_name.to_upper(), "  ·  ".join(states)]


func activate_power(power_id: String) -> bool:
	if not _gameplay_enabled or not has_power(power_id):
		return false
	var toggled: bool = power_id in ["speed", "flight", "beast"]
	if get_power_cooldown(power_id) > 0.0 and not (toggled and is_power_active(power_id)):
		return false
	var power: Dictionary = HeroPowerCatalog.get_power(power_id)
	if power.is_empty():
		return false
	match power_id:
		"elemental":
			_launch_elemental()
		"super_strength":
			_activate_strength()
		"speed":
			_speed_active = not _speed_active
		"teleportation":
			if not _teleport_forward():
				return false
		"beast":
			_beast_active = not _beast_active
		"flight":
			_flight_active = not _flight_active
			collision_mask = 0 if _flight_active else 1
			_spawn_burst(global_position + Vector3(0.0, 0.35, 0.0), Color("#a9d2ff"))
		_:
			return false
	var cooldown: float = float(power.get("cooldown", 0.6))
	# Transform toggles stay available so the player can always switch back.
	if toggled:
		cooldown = 0.36
	elif _speed_active:
		cooldown *= 0.72
	_cooldowns[power_id] = cooldown
	_update_power_look()
	return true


func perform_strike() -> bool:
	if not _gameplay_enabled or _strike_cooldown > 0.0:
		return false
	var damage: float = 22.0
	var radius: float = 2.8
	if has_power("super_strength"):
		damage = 34.0
		radius = 3.8
	if _beast_active:
		damage *= 1.55
		radius *= 1.18
	_damage_targets(radius, damage, "impact", true)
	_strike_cooldown = 0.72 * (0.55 if _speed_active else 1.0)
	_spawn_burst(
		global_position + _last_direction * 1.25 + Vector3.UP * 0.85, Color("#f2c75c"), 0.68
	)
	return true


func _physics_process(delta: float) -> void:
	_time += delta
	for power_id: Variant in _cooldowns.keys():
		_cooldowns[power_id] = maxf(0.0, float(_cooldowns[power_id]) - delta)
	_strike_cooldown = maxf(0.0, _strike_cooldown - delta)
	_update_projectiles(delta)
	_update_flight_height(delta)
	if not _gameplay_enabled:
		velocity = Vector3.ZERO
		_update_animation(false)
		return

	var axis: Vector2 = _get_movement_axis()
	var moving: bool = axis.length_squared() > 0.012
	var speed: float = WALK_SPEED
	if _speed_active:
		speed *= SPRINT_MULTIPLIER
	if _flight_active:
		speed *= FLIGHT_MULTIPLIER
	if _beast_active:
		speed *= BEAST_MULTIPLIER
	var movement := Vector3(axis.x, 0.0, axis.y)
	if movement.length_squared() > 0.001:
		movement = movement.normalized()
		_last_direction = movement
		var target_yaw: float = atan2(-movement.x, -movement.z)
		_visual_root.rotation.y = lerp_angle(
			_visual_root.rotation.y, target_yaw, minf(delta * 12.0, 1.0)
		)
		velocity.x = movement.x * speed
		velocity.z = movement.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 8.0 * delta)
	velocity.y = 0.0
	move_and_slide()
	position.x = clampf(position.x, -_park_bounds.x, _park_bounds.x)
	position.z = clampf(position.z, -_park_bounds.y + 7.0, _park_bounds.y - 5.0)
	_update_animation(moving)


func _unhandled_key_input(event: InputEvent) -> void:
	if not _gameplay_enabled or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_SPACE:
			perform_strike()
			return
		KEY_1:
			_activate_slot(0)
			return
		KEY_2:
			_activate_slot(1)
			return
		KEY_3:
			_activate_slot(2)


func _activate_slot(slot: int) -> void:
	if slot >= 0 and slot < _equipped_powers.size():
		activate_power(_equipped_powers[slot])


func _get_movement_axis() -> Vector2:
	var horizontal: float = (
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
		- float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	)
	var vertical: float = (
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
		- float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	)
	return (Vector2(horizontal, vertical) + _virtual_axis).limit_length(1.0)


func _update_flight_height(delta: float) -> void:
	var desired_height: float = 1.45 if _flight_active else 0.0
	_flight_height = move_toward(_flight_height, desired_height, delta * 4.0)
	position.y = _flight_height
	if _aura != null:
		_aura.visible = _speed_active or _flight_active or _beast_active
		if _flight_active:
			_aura.position.y = 0.14
			_aura.scale = Vector3.ONE * 1.15
		elif _beast_active:
			_aura.position.y = 0.08
			_aura.scale = Vector3.ONE * 1.4
		else:
			_aura.position.y = 0.06
			_aura.scale = Vector3.ONE


func _update_animation(moving: bool) -> void:
	if _visual_root == null:
		return
	var gait: float = _time * (7.5 if moving else 1.8)
	var swing: float = sin(gait) * (0.47 if moving else 0.035)
	_left_leg.rotation.x = swing
	_right_leg.rotation.x = -swing
	_left_arm.rotation.x = -swing * 0.72
	_right_arm.rotation.x = swing * 0.72
	_visual_root.position.y = (
		sin(_time * 2.2) * 0.025 if not _flight_active else sin(_time * 3.0) * 0.09
	)
	if _flight_active:
		_visual_root.position.y += 0.06
	if _beast_active:
		_visual_root.rotation.z = sin(_time * 4.0) * 0.018
	else:
		_visual_root.rotation.z = 0.0


func _launch_elemental() -> void:
	var element_data: Dictionary = HeroPowerCatalog.get_element(_element)
	var projectile := MeshInstance3D.new()
	projectile.name = "%sBolt" % _element.capitalize()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	sphere.radial_segments = 8
	sphere.rings = 4
	projectile.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(str(element_data["color"]))
	material.emission_enabled = true
	material.emission = Color(str(element_data["color"]))
	material.emission_energy_multiplier = 1.35
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	projectile.material_override = material
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector3.UP * 1.28 + _last_direction * 0.9
	(
		_projectiles
		. append(
			{
				"node": projectile,
				"direction": _last_direction,
				"element": _element,
				"time_left": 2.8,
				"speed": 13.0,
			}
		)
	)


func _update_projectiles(delta: float) -> void:
	for index: int in range(_projectiles.size() - 1, -1, -1):
		var projectile_data: Dictionary = _projectiles[index]
		var projectile: MeshInstance3D = projectile_data["node"]
		if not is_instance_valid(projectile):
			_projectiles.remove_at(index)
			continue
		var direction: Vector3 = projectile_data["direction"]
		var old_position: Vector3 = projectile.global_position
		var new_position: Vector3 = (
			old_position + direction * float(projectile_data["speed"]) * delta
		)
		projectile.global_position = new_position
		projectile_data["time_left"] = float(projectile_data["time_left"]) - delta
		var target_hit: Node3D
		for candidate: Node in get_tree().get_nodes_in_group("hero_targets_3d"):
			if not candidate is Node3D:
				continue
			var target: Node3D = candidate
			if not target.visible:
				continue
			if target.global_position.distance_to(new_position) <= 1.35:
				target_hit = target
				break
		if target_hit != null:
			var element: String = str(projectile_data["element"])
			target_hit.call("take_damage", 34.0, direction, element)
			if element == "lightning":
				_chain_lightning(target_hit, direction)
			projectile.queue_free()
			_projectiles.remove_at(index)
		elif (
			float(projectile_data["time_left"]) <= 0.0
			or absf(new_position.x) > 70.0
			or new_position.z < -115.0
		):
			projectile.queue_free()
			_projectiles.remove_at(index)
		else:
			_projectiles[index] = projectile_data


func _chain_lightning(first_target: Node3D, direction: Vector3) -> void:
	var nearest_target: Node3D
	var nearest_distance: float = 7.0
	for candidate: Node in get_tree().get_nodes_in_group("hero_targets_3d"):
		if candidate == first_target or not candidate is Node3D:
			continue
		var target: Node3D = candidate
		if not target.visible:
			continue
		var distance: float = first_target.global_position.distance_to(target.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_target = target
	if nearest_target != null:
		nearest_target.call("take_damage", 19.0, direction, "lightning")
		_spawn_lightning_link(
			first_target.global_position + Vector3.UP, nearest_target.global_position + Vector3.UP
		)


func _spawn_lightning_link(start: Vector3, finish: Vector3) -> void:
	var beam := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.045
	cylinder.bottom_radius = 0.045
	cylinder.height = start.distance_to(finish)
	cylinder.radial_segments = 5
	beam.mesh = cylinder
	beam.position = (start + finish) * 0.5
	beam.quaternion = Quaternion(Vector3.UP, (finish - start).normalized())
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#fff19a")
	material.emission_enabled = true
	material.emission = Color("#fff19a")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam.material_override = material
	get_parent().add_child(beam)
	var tween := create_tween()
	tween.tween_interval(0.18)
	tween.tween_callback(beam.queue_free)


func _activate_strength() -> void:
	var damage: float = 54.0 if _beast_active else 45.0
	var radius: float = 6.0 if _beast_active else 5.0
	_damage_targets(radius, damage, "impact", false)
	_spawn_burst(global_position + Vector3.UP * 0.22, Color("#f2c75c"), 2.1)


func _damage_targets(radius: float, damage: float, element: String, directional: bool) -> void:
	for candidate: Node in get_tree().get_nodes_in_group("hero_targets_3d"):
		if not candidate is Node3D:
			continue
		var target: Node3D = candidate
		if not target.visible:
			continue
		var target_position: Vector3 = target.global_position + Vector3(0.0, 0.8, 0.0)
		var offset: Vector3 = target_position - global_position
		var distance: float = offset.length()
		if distance > radius:
			continue
		if directional and distance > 0.01 and _last_direction.dot(offset.normalized()) < -0.08:
			continue
		target.call("take_damage", damage, offset.normalized(), element)


func _teleport_forward() -> bool:
	var direction: Vector3 = _last_direction.normalized()
	var destination: Vector3 = global_position + direction * 9.0
	var ray_from: Vector3 = global_position + Vector3.UP * 0.85
	var ray_to: Vector3 = destination + Vector3.UP * 0.85
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.exclude = [get_rid()]
	query.collision_mask = 1
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var available_distance: float = 9.0
	if not hit.is_empty():
		available_distance = global_position.distance_to(hit["position"]) - 1.4
	if available_distance < 2.4:
		return false
	var landing: Vector3 = global_position + direction * minf(available_distance, 9.0)
	landing.x = clampf(landing.x, -_park_bounds.x, _park_bounds.x)
	landing.z = clampf(landing.z, -_park_bounds.y + 7.0, _park_bounds.y - 5.0)
	_spawn_burst(global_position + Vector3.UP * 0.8, Color("#bd9aff"), 1.0)
	global_position = landing
	_spawn_burst(global_position + Vector3.UP * 0.8, Color("#bd9aff"), 1.0)
	return true


func _spawn_burst(burst_position: Vector3, burst_color: Color, max_scale: float = 1.55) -> void:
	var effect := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.44
	sphere.height = 0.88
	sphere.radial_segments = 8
	sphere.rings = 4
	effect.mesh = sphere
	effect.position = burst_position
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(burst_color.r, burst_color.g, burst_color.b, 0.42)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = burst_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	effect.material_override = material
	get_parent().add_child(effect)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector3.ONE * max_scale, 0.28)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.28)
	tween.chain().tween_callback(effect.queue_free)


func _apply_profile_look() -> void:
	if _torso_material == null:
		return
	_torso_material.albedo_color = _suit_color
	_cape_material.albedo_color = _cape_color
	if _aura != null:
		var aura_color := Color("#a9d2ff") if _flight_active else Color("#87e9d2")
		var aura_material: StandardMaterial3D = _aura.material_override as StandardMaterial3D
		aura_material.albedo_color = Color(aura_color.r, aura_color.g, aura_color.b, 0.18)
		aura_material.emission = aura_color
	_update_power_look()


func _update_power_look() -> void:
	if _visual_root == null:
		return
	_visual_root.scale = Vector3.ONE * (1.22 if _beast_active else 1.0)
	if _aura != null:
		var aura_material: StandardMaterial3D = _aura.material_override as StandardMaterial3D
		var aura_color := Color("#a9d2ff")
		if _speed_active:
			aura_color = Color("#87e9d2")
		if _beast_active:
			aura_color = Color("#ee8c76")
		aura_material.albedo_color = Color(aura_color.r, aura_color.g, aura_color.b, 0.18)
		aura_material.emission = aura_color


func _build_model() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.78
	collision.shape = capsule
	collision.position.y = 0.89
	add_child(collision)

	_visual_root = Node3D.new()
	_visual_root.name = "HeroModel"
	add_child(_visual_root)
	_torso_material = _make_texture_material(
		SUIT_WEAVE_TEXTURE, _suit_color, 0.78, Vector3(1.8, 1.8, 1.0)
	)
	_cape_material = _make_texture_material(
		CAPE_WEAVE_TEXTURE, _cape_color, 0.84, Vector3(1.5, 1.5, 1.0)
	)
	var dark_material := _make_material("#263740", 0.88)
	var skin_material := _make_material("#d6a47d", 0.9)

	var cape := MeshInstance3D.new()
	cape.name = "Cape"
	var cape_mesh := BoxMesh.new()
	cape_mesh.size = Vector3(0.78, 1.08, 0.12)
	cape.mesh = cape_mesh
	cape.position = Vector3(0.0, 1.28, 0.42)
	cape.rotation.x = deg_to_rad(-5.0)
	cape.material_override = _cape_material
	_visual_root.add_child(cape)

	var torso := MeshInstance3D.new()
	torso.name = "Suit"
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.35
	torso_mesh.height = 1.08
	torso_mesh.radial_segments = 8
	torso.mesh = torso_mesh
	torso.position.y = 1.22
	torso.material_override = _torso_material
	_visual_root.add_child(torso)

	var belt := MeshInstance3D.new()
	belt.name = "UtilityBelt"
	var belt_mesh := BoxMesh.new()
	belt_mesh.size = Vector3(0.62, 0.12, 0.4)
	belt.mesh = belt_mesh
	belt.position = Vector3(0.0, 0.88, -0.01)
	belt.material_override = dark_material
	_visual_root.add_child(belt)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.255
	head_mesh.height = 0.5
	head_mesh.radial_segments = 8
	head_mesh.rings = 4
	head.mesh = head_mesh
	head.position = Vector3(0.0, 2.01, 0.0)
	head.material_override = skin_material
	_visual_root.add_child(head)

	var visor := MeshInstance3D.new()
	visor.name = "HeroVisor"
	var visor_mesh := BoxMesh.new()
	visor_mesh.size = Vector3(0.36, 0.11, 0.055)
	visor.mesh = visor_mesh
	visor.position = Vector3(0.0, 2.03, -0.232)
	visor.material_override = dark_material
	_visual_root.add_child(visor)

	_left_arm = _add_limb(
		"LeftArm", Vector3(-0.43, 1.35, 0.0), Vector3(0.18, 0.58, 0.19), _torso_material
	)
	_right_arm = _add_limb(
		"RightArm", Vector3(0.43, 1.35, 0.0), Vector3(0.18, 0.58, 0.19), _torso_material
	)
	_left_arm.rotation.z = deg_to_rad(12.0)
	_right_arm.rotation.z = deg_to_rad(-12.0)
	_left_leg = _add_limb(
		"LeftLeg", Vector3(-0.17, 0.43, 0.0), Vector3(0.2, 0.65, 0.22), dark_material
	)
	_right_leg = _add_limb(
		"RightLeg", Vector3(0.17, 0.43, 0.0), Vector3(0.2, 0.65, 0.22), dark_material
	)

	var emblem := MeshInstance3D.new()
	emblem.name = "HeroEmblem"
	var emblem_mesh := QuadMesh.new()
	emblem_mesh.size = Vector2(0.3, 0.34)
	emblem.mesh = emblem_mesh
	emblem.position = Vector3(0.0, 1.45, -0.39)
	emblem.rotation.y = PI
	var emblem_material := _make_texture_material(
		HERO_CREST_TEXTURE, Color.WHITE, 0.72, Vector3.ONE, true
	)
	emblem_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	emblem_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	emblem.material_override = emblem_material
	_visual_root.add_child(emblem)

	var aura_ring := MeshInstance3D.new()
	aura_ring.name = "PowerAura"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.55
	ring_mesh.outer_radius = 0.68
	ring_mesh.rings = 6
	ring_mesh.ring_segments = 18
	aura_ring.mesh = ring_mesh
	aura_ring.rotation.x = PI * 0.5
	aura_ring.position.y = 0.08
	var aura_material := StandardMaterial3D.new()
	aura_material.albedo_color = Color(0.53, 0.91, 0.82, 0.18)
	aura_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aura_material.emission_enabled = true
	aura_material.emission = Color("#87e9d2")
	aura_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	aura_ring.material_override = aura_material
	aura_ring.visible = false
	_visual_root.add_child(aura_ring)
	_aura = aura_ring


func _add_limb(
	limb_name: String, limb_position: Vector3, limb_size: Vector3, material: Material
) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = limb_name
	pivot.position = limb_position
	_visual_root.add_child(pivot)
	var limb := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = limb_size.x * 0.5
	capsule.height = limb_size.y
	capsule.radial_segments = 6
	limb.mesh = capsule
	limb.material_override = material
	pivot.add_child(limb)
	return pivot


func _make_material(
	color_value: Variant, roughness_value: float, unshaded: bool = false
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color_value if color_value is Color else Color(str(color_value))
	material.roughness = roughness_value
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		material.emission = material.albedo_color
	return material


func _make_texture_material(
	texture: Texture2D,
	tint: Color,
	roughness_value: float,
	uv_scale: Vector3 = Vector3.ONE,
	unshaded: bool = false
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.texture_repeat = BaseMaterial3D.TEXTURE_REPEAT_ENABLED
	material.uv1_scale = uv_scale
	material.roughness = roughness_value
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _ready() -> void:
	_build_model()
	configure(
		{
			"name": "Nova",
			"suit_color": "#45bcae",
			"cape_color": "#e7645d",
			"element": "fire",
			"powers": ["elemental", "flight"]
		}
	)


func _process(_delta: float) -> void:
	# Keep transform power visuals responsive to cooldown toggles outside physics.
	if _aura != null and _aura.visible:
		_aura.rotation.y = _time * 0.85
