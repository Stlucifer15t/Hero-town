extends Node3D

const HeroTrainingTarget3D = preload("res://scripts/game3d/hero_training_target_3d.gd")

const GRASS_MEADOW_TEXTURE: Texture2D = preload("res://assets/pixel/grass_meadow.png")
const GRASS_WILDFLOWER_TEXTURE: Texture2D = preload("res://assets/pixel/grass_wildflower.png")
const STONE_PATH_TEXTURE: Texture2D = preload("res://assets/pixel/stone_path.png")
const PROMENADE_TEXTURE: Texture2D = preload("res://assets/pixel/promenade.png")
const CURB_STONE_TEXTURE: Texture2D = preload("res://assets/pixel/curb_stone.png")
const WATER_TEXTURE: Texture2D = preload("res://assets/pixel/park_water.png")
const TREE_CANOPY_TEXTURE: Texture2D = preload("res://assets/pixel/tree_canopy.png")
const WOOD_PIXEL_TEXTURE: Texture2D = preload("res://assets/pixel/wood_pixel.png")
const SUIT_WEAVE_TEXTURE: Texture2D = preload("res://assets/pixel/suit_weave.png")
const HERO_CREST_TEXTURE: Texture2D = preload("res://assets/pixel/hero_town_crest.png")
const BUILDING_FACADE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/pixel/facade_terracotta.png"),
	preload("res://assets/pixel/facade_limestone.png"),
	preload("res://assets/pixel/facade_glass.png"),
	preload("res://assets/pixel/facade_slate.png"),
]

const PARK_HALF_WIDTH: float = 52.0
const PARK_HALF_DEPTH: float = 74.0

var _rng := RandomNumberGenerator.new()
var _walkers: Array[Dictionary] = []
var _elapsed: float = 0.0


func _ready() -> void:
	_rng.seed = 20261017
	_build_environment()
	_build_ground()
	_build_paths()
	_build_grass()
	_build_tree_line()
	_build_skyline()
	_build_park_furniture()
	_build_citizens()
	_build_training_targets()


func get_player_spawn() -> Vector3:
	return Vector3(0.0, 0.0, 9.0)


func get_park_bounds() -> Vector2:
	return Vector2(PARK_HALF_WIDTH - 3.0, PARK_HALF_DEPTH - 3.0)


func _process(delta: float) -> void:
	_elapsed += delta
	for walker_data: Dictionary in _walkers:
		var walker: Node3D = walker_data["node"]
		if not is_instance_valid(walker):
			continue
		var phase: float = float(walker_data["phase"])
		var speed: float = float(walker_data["speed"])
		var route_phase: float = fposmod(_elapsed * speed + phase, 2.0)
		var outbound: bool = route_phase <= 1.0
		var progress: float = route_phase if outbound else 2.0 - route_phase
		var start_point: Vector3 = walker_data["start"]
		var destination: Vector3 = walker_data["destination"]
		walker.position = start_point.lerp(destination, progress)
		walker.position.z += sin(progress * PI) * 0.45
		walker.rotation.y = -PI * 0.5 if outbound else PI * 0.5
		for leg: Node3D in walker_data["legs"]:
			leg.rotation.x = sin(_elapsed * speed * TAU * 34.0 + phase * 2.0) * 0.35


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "AfternoonEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#47749b")
	sky_material.sky_horizon_color = Color("#d2e2e9")
	sky_material.sky_curve = 0.18
	sky_material.ground_bottom_color = Color("#596c55")
	sky_material.ground_horizon_color = Color("#c7d3c4")
	sky_material.ground_curve = 0.12
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#a5bed0")
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.06
	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.name = "LateAfternoonSun"
	sunlight.rotation = Vector3(deg_to_rad(-43.0), deg_to_rad(-28.0), deg_to_rad(-9.0))
	sunlight.light_color = Color("#ffe0af")
	sunlight.light_energy = 1.28
	sunlight.shadow_enabled = true
	sunlight.directional_shadow_max_distance = 68.0
	add_child(sunlight)


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "ParkLawn"
	var plane := PlaneMesh.new()
	plane.size = Vector2(PARK_HALF_WIDTH * 2.0, PARK_HALF_DEPTH * 2.0)
	ground.mesh = plane
	ground.position = Vector3(0.0, -0.12, -2.0)
	ground.material_override = _make_texture_material(
		GRASS_WILDFLOWER_TEXTURE, Color("#d9ebbd"), 1.0, Vector3(10.0, 14.0, 1.0)
	)
	add_child(ground)

	var ground_body := StaticBody3D.new()
	ground_body.name = "GroundCollision"
	ground_body.position = Vector3(0.0, -0.16, -2.0)
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(PARK_HALF_WIDTH * 2.0, 0.3, PARK_HALF_DEPTH * 2.0)
	ground_shape.shape = ground_box
	ground_body.add_child(ground_shape)
	add_child(ground_body)

	var far_lawn := MeshInstance3D.new()
	far_lawn.name = "HorizonLawn"
	var horizon_plane := PlaneMesh.new()
	horizon_plane.size = Vector2(500.0, 500.0)
	far_lawn.mesh = horizon_plane
	far_lawn.position = Vector3(0.0, -0.28, -170.0)
	far_lawn.material_override = _make_texture_material(
		GRASS_MEADOW_TEXTURE, Color("#9bb38f"), 1.0, Vector3(48.0, 48.0, 1.0)
	)
	add_child(far_lawn)


func _build_paths() -> void:
	_add_box(
		self,
		"MainParkWalk",
		Vector3(4.0, 0.12, 118.0),
		Vector3(0.0, -0.015, -12.0),
		_make_texture_material(STONE_PATH_TEXTURE, Color.WHITE, 0.96, Vector3(2.0, 59.0, 1.0))
	)
	_add_box(
		self,
		"CrossParkWalk",
		Vector3(94.0, 0.12, 3.0),
		Vector3(0.0, -0.008, -24.0),
		_make_texture_material(PROMENADE_TEXTURE, Color.WHITE, 0.96, Vector3(47.0, 1.5, 1.0))
	)
	_add_box(
		self,
		"FarPromenade",
		Vector3(106.0, 0.18, 5.0),
		Vector3(0.0, 0.02, -46.0),
		_make_texture_material(PROMENADE_TEXTURE, Color("#e5e7db"), 0.94, Vector3(26.5, 1.25, 1.0))
	)
	_add_box(
		self,
		"WaterfrontCurb",
		Vector3(108.0, 0.28, 0.55),
		Vector3(0.0, 0.12, -49.0),
		_make_texture_material(CURB_STONE_TEXTURE, Color.WHITE, 0.92, Vector3(54.0, 1.0, 1.0))
	)

	var water := MeshInstance3D.new()
	water.name = "ParkWater"
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(108.0, 14.0)
	water.mesh = water_mesh
	water.position = Vector3(0.0, -0.045, -59.5)
	water.material_override = _make_texture_material(
		WATER_TEXTURE, Color("#c4ded0"), 0.42, Vector3(27.0, 3.5, 1.0)
	)
	add_child(water)


func _build_grass() -> void:
	var grass_mesh := _make_grass_mesh()
	var grass_material := StandardMaterial3D.new()
	grass_material.vertex_color_use_as_albedo = true
	grass_material.roughness = 1.0
	grass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	var grass := MultiMeshInstance3D.new()
	grass.name = "ForegroundGrass"
	var grass_multimesh := MultiMesh.new()
	grass_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	grass_multimesh.mesh = grass_mesh
	grass_multimesh.instance_count = 3100
	grass.multimesh = grass_multimesh
	grass.material_override = grass_material
	add_child(grass)

	for index: int in range(grass_multimesh.instance_count):
		var position: Vector3 = _random_lawn_point(false)
		var height_scale: float = _rng.randf_range(0.52, 1.58)
		var width_scale: float = _rng.randf_range(0.55, 1.2)
		var basis := Basis(Vector3.UP, _rng.randf_range(0.0, TAU)).scaled(
			Vector3(width_scale, height_scale, width_scale)
		)
		grass_multimesh.set_instance_transform(index, Transform3D(basis, position))

	var flower := MultiMeshInstance3D.new()
	flower.name = "MeadowFlowers"
	var flower_mesh := SphereMesh.new()
	flower_mesh.radius = 0.055
	flower_mesh.height = 0.11
	flower_mesh.radial_segments = 5
	flower_mesh.rings = 3
	var flower_multi := MultiMesh.new()
	flower_multi.transform_format = MultiMesh.TRANSFORM_3D
	flower_multi.mesh = flower_mesh
	flower_multi.instance_count = 92
	flower.multimesh = flower_multi
	flower.material_override = _make_material("#f3e8c4", 0.82)
	add_child(flower)
	for index: int in range(flower_multi.instance_count):
		var position: Vector3 = _random_lawn_point(true)
		var flower_scale: float = _rng.randf_range(0.55, 1.35)
		position.y = 0.13 * flower_scale
		flower_multi.set_instance_transform(
			index, Transform3D(Basis().scaled(Vector3.ONE * flower_scale), position)
		)


func _random_lawn_point(for_flower: bool) -> Vector3:
	var x: float = 0.0
	var z: float = 0.0
	for _attempt: int in range(80):
		x = _rng.randf_range(-PARK_HALF_WIDTH + 1.0, PARK_HALF_WIDTH - 1.0)
		z = _rng.randf_range(-50.0, 41.0)
		if absf(x) < (3.2 if for_flower else 2.8):
			continue
		if absf(z + 24.0) < (3.0 if for_flower else 2.2) or absf(z + 46.0) < 3.0:
			continue
		if absf(x) < 5.5 and z > -12.0 and z < 15.0:
			continue
		return Vector3(x, 0.0, z)
	return Vector3(15.0, 0.0, 15.0)


func _make_grass_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var colors: Array[Color] = [Color("#86af59"), Color("#6f9e4d"), Color("#9bc76c")]
	for blade_index: int in range(3):
		var angle: float = float(blade_index) * PI / 3.0
		var side := Vector3(cos(angle), 0.0, sin(angle)) * 0.07
		var tip := Vector3(
			cos(angle + 0.72) * 0.045,
			0.29 + float(blade_index % 2) * 0.06,
			sin(angle + 0.72) * 0.045
		)
		var left := -side
		var right := side
		surface.set_color(colors[blade_index])
		surface.add_vertex(left)
		surface.add_vertex(tip)
		surface.add_vertex(right)
		surface.set_color(colors[(blade_index + 1) % colors.size()])
		surface.add_vertex(right)
		surface.add_vertex(tip)
		surface.add_vertex(left)
	surface.generate_normals()
	return surface.commit()


func _build_tree_line() -> void:
	var leaf_colors: Array[Color] = [
		Color("#3f8a4c"), Color("#4a9953"), Color("#347b45"), Color("#5ba75a")
	]
	for index: int in range(19):
		var x: float = -45.0 + float(index) * 5.0 + _rng.randf_range(-1.5, 1.5)
		var z: float = -34.0 + _rng.randf_range(-2.5, 2.5)
		if absf(x) < 5.0:
			continue
		_add_tree(
			Vector3(x, 0.0, z), _rng.randf_range(0.8, 1.24), leaf_colors[index % leaf_colors.size()]
		)
	for index: int in range(10):
		var side: float = -1.0 if index % 2 == 0 else 1.0
		var z: float = 6.0 - float(index / 2) * 8.0
		var x: float = side * _rng.randf_range(27.0, 42.0)
		_add_tree(
			Vector3(x, 0.0, z),
			_rng.randf_range(0.78, 1.15),
			leaf_colors[(index + 1) % leaf_colors.size()]
		)


func _add_tree(tree_position: Vector3, tree_scale: float, leaf_color: Color) -> void:
	var tree := Node3D.new()
	tree.name = "ParkTree"
	tree.position = tree_position
	tree.scale = Vector3.ONE * tree_scale
	add_child(tree)
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.34
	trunk_mesh.height = 2.4
	trunk_mesh.radial_segments = 6
	var trunk := MeshInstance3D.new()
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.2
	trunk.material_override = _make_texture_material(
		WOOD_PIXEL_TEXTURE, Color("#b9946b"), 0.98, Vector3(2.0, 2.0, 1.0)
	)
	tree.add_child(trunk)
	var trunk_body := StaticBody3D.new()
	trunk_body.name = "TreeTrunkCollision"
	var trunk_collision := CollisionShape3D.new()
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.33
	trunk_shape.height = 2.4
	trunk_collision.shape = trunk_shape
	trunk_collision.position.y = 1.2
	trunk_body.add_child(trunk_collision)
	tree.add_child(trunk_body)
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radius = 1.35
	leaf_mesh.height = 2.5
	leaf_mesh.radial_segments = 7
	leaf_mesh.rings = 3
	for cluster_index: int in range(3):
		var cluster := MeshInstance3D.new()
		cluster.mesh = leaf_mesh
		cluster.position = Vector3(
			float(cluster_index - 1) * 0.65,
			2.55 + (0.38 if cluster_index == 1 else 0.0),
			0.12 if cluster_index == 2 else 0.0
		)
		cluster.scale = Vector3(0.75, 0.7, 0.75) if cluster_index != 1 else Vector3(0.8, 0.85, 0.8)
		cluster.material_override = _make_texture_material(
			TREE_CANOPY_TEXTURE,
			leaf_color.lightened(float(cluster_index) * 0.025),
			1.0,
			Vector3(1.6, 1.6, 1.0)
		)
		tree.add_child(cluster)


func _build_skyline() -> void:
	var window_textures: Array[Texture2D] = BUILDING_FACADE_TEXTURES
	for index: int in range(33):
		var lane: int = index % 2
		var x: float = -59.0 + float(index) * 3.7 + _rng.randf_range(-1.2, 1.2)
		var z: float = -72.0 - float(lane) * 11.0 + _rng.randf_range(-1.4, 1.4)
		var width: float = _rng.randf_range(3.0, 6.2)
		var depth: float = _rng.randf_range(4.5, 8.5)
		var height: float = _rng.randf_range(10.0, 27.0)
		if index % 8 == 1:
			height = _rng.randf_range(30.0, 39.0)
		var building := MeshInstance3D.new()
		building.name = "SkylineBuilding_%02d" % index
		var box := BoxMesh.new()
		box.size = Vector3(width, height, depth)
		building.mesh = box
		building.position = Vector3(x, height * 0.5 - 0.12, z)
		var facade_texture: Texture2D = window_textures[index % window_textures.size()]
		var facade := _make_texture_material(
			facade_texture,
			Color.WHITE,
			0.96,
			Vector3(maxf(width / 6.0, 1.0), maxf(height / 7.0, 1.0), 1.0)
		)
		building.material_override = facade
		add_child(building)

		var roof := MeshInstance3D.new()
		var roof_mesh := BoxMesh.new()
		roof_mesh.size = Vector3(width + 0.18, 0.24, depth + 0.18)
		roof.mesh = roof_mesh
		roof.position = building.position + Vector3(0.0, height * 0.5, 0.0)
		roof.material_override = _make_texture_material(
			CURB_STONE_TEXTURE, Color("#a7a69b"), 0.96, Vector3(width / 3.0, depth / 3.0, 1.0)
		)
		add_child(roof)
		if index % 5 == 0:
			_add_box(
				self,
				"RooftopWaterTank",
				Vector3(width * 0.22, 1.3, depth * 0.2),
				building.position + Vector3(width * 0.15, height * 0.5 + 0.85, -depth * 0.1),
				_make_material("#5f6666", 1.0)
			)

	_add_hero_hq_landmark()


func _add_hero_hq_landmark() -> void:
	var hq := Node3D.new()
	hq.name = "HeroAssociationSkyline"
	hq.position = Vector3(-8.0, -0.1, -55.0)
	add_child(hq)
	_add_box(
		hq,
		"HQBase",
		Vector3(11.0, 15.0, 8.0),
		Vector3(0.0, 7.5, 0.0),
		_make_texture_material(
			BUILDING_FACADE_TEXTURES[1], Color("#f0e4c7"), 0.93, Vector3(2.0, 2.5, 1.0)
		)
	)
	_add_box(
		hq,
		"HQGlassTower",
		Vector3(5.5, 22.0, 5.4),
		Vector3(0.2, 18.5, 0.0),
		_make_texture_material(
			BUILDING_FACADE_TEXTURES[2], Color("#b5d3d4"), 0.62, Vector3(1.4, 3.1, 1.0)
		)
	)
	_add_box(
		hq,
		"HQRoof",
		Vector3(12.0, 0.55, 9.0),
		Vector3(0.0, 7.8, 0.0),
		_make_texture_material(CURB_STONE_TEXTURE, Color("#e2d7ba"), 0.9, Vector3(3.0, 2.25, 1.0))
	)
	var crest := MeshInstance3D.new()
	crest.name = "AssociationCrest"
	var crest_mesh := QuadMesh.new()
	crest_mesh.size = Vector2(1.7, 1.7)
	crest.mesh = crest_mesh
	crest.position = Vector3(0.0, 11.4, 4.08)
	var crest_material := _make_texture_material(
		HERO_CREST_TEXTURE, Color.WHITE, 1.0, Vector3.ONE, true
	)
	crest_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crest_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	crest.material_override = crest_material
	hq.add_child(crest)

	var sign := Label3D.new()
	sign.name = "HeroAssociationSign"
	sign.text = "HERO\nASSOCIATION"
	sign.font_size = 48
	sign.pixel_size = 0.012
	sign.modulate = Color("#f4df9b")
	sign.position = Vector3(0.0, 13.0, 4.1)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hq.add_child(sign)


func _build_park_furniture() -> void:
	for index: int in range(5):
		var x: float = -17.0 + float(index) * 8.5
		var bench := Node3D.new()
		bench.name = "ParkBench_%02d" % index
		bench.position = Vector3(x, 0.0, -16.0)
		add_child(bench)
		_add_box(
			bench,
			"BenchSeat",
			Vector3(2.0, 0.18, 0.62),
			Vector3(0.0, 0.6, 0.0),
			_make_texture_material(
				WOOD_PIXEL_TEXTURE, Color("#bb936b"), 0.92, Vector3(2.0, 1.0, 1.0)
			)
		)
		_add_box(
			bench,
			"BenchBack",
			Vector3(2.0, 0.82, 0.16),
			Vector3(0.0, 1.02, -0.25),
			_make_texture_material(
				WOOD_PIXEL_TEXTURE, Color("#c59a68"), 0.92, Vector3(2.0, 1.0, 1.0)
			)
		)
		for leg_x: float in [-0.72, 0.72]:
			_add_box(
				bench,
				"BenchLeg",
				Vector3(0.14, 0.58, 0.56),
				Vector3(leg_x, 0.29, 0.0),
				_make_material("#444d4a", 0.92)
			)
		var bench_body := StaticBody3D.new()
		bench_body.name = "BenchCollision"
		var bench_collision := CollisionShape3D.new()
		var bench_shape := BoxShape3D.new()
		bench_shape.size = Vector3(2.0, 1.12, 0.7)
		bench_collision.shape = bench_shape
		bench_collision.position.y = 0.56
		bench_body.add_child(bench_collision)
		bench.add_child(bench_body)

	for index: int in range(8):
		var lamp_x: float = -28.0 + float(index) * 8.0
		var lamp := Node3D.new()
		lamp.name = "ParkLamp_%02d" % index
		lamp.position = Vector3(lamp_x, 0.0, -27.0)
		add_child(lamp)
		_add_box(
			lamp,
			"LampPost",
			Vector3(0.12, 3.1, 0.12),
			Vector3(0.0, 1.55, 0.0),
			_make_material("#55645f", 0.85)
		)
		_add_box(
			lamp,
			"LampArm",
			Vector3(0.68, 0.1, 0.12),
			Vector3(0.25, 2.96, 0.0),
			_make_material("#55645f", 0.85)
		)
		_add_box(
			lamp,
			"LampGlow",
			Vector3(0.34, 0.15, 0.32),
			Vector3(0.56, 2.9, 0.0),
			_make_material("#f4d89b", 0.55, true)
		)


func _build_citizens() -> void:
	var outfits: Array[Color] = [
		Color("#d56d57"),
		Color("#3d77a3"),
		Color("#e0bb55"),
		Color("#775c9e"),
		Color("#e8dfc9"),
		Color("#4b8661"),
	]
	for index: int in range(10):
		var walker := Node3D.new()
		walker.name = "ParkVisitor_%02d" % index
		var lane: float = -30.0 + float(index % 4) * 7.0
		var start_point := Vector3(-13.0, 0.0, lane)
		var destination := Vector3(13.0, 0.0, lane + (1.2 if index % 2 == 0 else -1.2))
		walker.position = start_point
		walker.add_to_group("park_visitors_3d")
		walker.set_meta("park_origin", "West Garden Gate")
		walker.set_meta("park_destination", "Waterfront Promenade")
		add_child(walker)
		var torso_mesh := CapsuleMesh.new()
		torso_mesh.radius = 0.23
		torso_mesh.height = 0.95
		torso_mesh.radial_segments = 6
		var torso := MeshInstance3D.new()
		torso.mesh = torso_mesh
		torso.position = Vector3(0.0, 1.05, 0.0)
		torso.material_override = _make_texture_material(
			SUIT_WEAVE_TEXTURE, outfits[index % outfits.size()], 0.96, Vector3(1.2, 1.5, 1.0)
		)
		walker.add_child(torso)
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.19
		head_mesh.height = 0.38
		head_mesh.radial_segments = 6
		head_mesh.rings = 3
		var head := MeshInstance3D.new()
		head.mesh = head_mesh
		head.position = Vector3(0.0, 1.67, 0.0)
		head.material_override = _make_material("#d8ab83", 0.95)
		walker.add_child(head)
		var legs: Array[Node3D] = []
		for side: float in [-1.0, 1.0]:
			var leg := MeshInstance3D.new()
			var leg_mesh := CylinderMesh.new()
			leg_mesh.top_radius = 0.07
			leg_mesh.bottom_radius = 0.09
			leg_mesh.height = 0.58
			leg_mesh.radial_segments = 5
			leg.mesh = leg_mesh
			leg.position = Vector3(side * 0.1, 0.32, 0.0)
			leg.material_override = _make_material("#38464a", 0.98)
			walker.add_child(leg)
			legs.append(leg)
		(
			_walkers
			. append(
				{
					"node": walker,
					"start": start_point,
					"destination": destination,
					"phase": float(index) * 0.17,
					"speed": 0.022 + float(index % 3) * 0.003,
					"legs": legs,
				}
			)
		)


func _build_training_targets() -> void:
	for index: int in range(3):
		var target: Node3D = HeroTrainingTarget3D.new()
		target.name = "TrainingDummy_%02d" % index
		target.position = Vector3(-5.5 + float(index) * 5.5, 0.0, 2.0)
		add_child(target)


func _add_box(
	parent: Node3D, box_name: String, size: Vector3, box_position: Vector3, material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = box_name
	var box := BoxMesh.new()
	box.size = size
	instance.mesh = box
	instance.position = box_position
	instance.material_override = material
	parent.add_child(instance)
	return instance


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
	tint: Color = Color.WHITE,
	roughness_value: float = 1.0,
	uv_scale: Vector3 = Vector3.ONE,
	unshaded: bool = false
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.texture_repeat = true
	material.uv1_scale = uv_scale
	material.roughness = roughness_value
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
