extends SceneTree

const HeroPowerCatalog = preload("res://scripts/hero/hero_power_catalog.gd")
const HeroTown3DScene = preload("res://scenes/hero_town_3d.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failure: String = ""
	var game: Node3D = HeroTown3DScene.instantiate() as Node3D
	root.add_child(game)
	await process_frame
	await physics_frame

	var park: Node3D = game.get_node_or_null("HeroTownPark") as Node3D
	var hero: CharacterBody3D = game.get_node_or_null("PlayerHero") as CharacterBody3D
	if park == null or hero == null:
		failure = "The portrait 3D scene did not create its park and player hero."
	elif park.get_node_or_null("ForegroundGrass") == null:
		failure = "The 3D park is missing its instanced meadow grass."
	elif park.get_node_or_null("AfternoonEnvironment") == null:
		failure = "The 3D park is missing its afternoon sky and lighting."
	elif park.get_tree().get_nodes_in_group("hero_targets_3d").size() < 3:
		failure = "The 3D park did not create three training targets."
	elif park.get_tree().get_nodes_in_group("park_visitors_3d").size() < 8:
		failure = "The 3D park does not populate its named pedestrian routes."
	elif game.get_node_or_null("PortraitGameUI/UIRoot/LocationCard") == null:
		failure = "The in-world location intro is missing from the startup screen."
	elif game.get_node_or_null("PortraitGameUI/UIRoot/StartMenu/TitleCard") == null:
		failure = "The 3D park does not open on a game-style title screen."
	elif game.get_node_or_null("PortraitGameUI/UIRoot/PatrolHUD/MovementJoystick") == null:
		failure = "The portrait gameplay HUD is missing its touch joystick."
	elif (
		int(ProjectSettings.get_setting("display/window/size/viewport_width"))
		>= int(ProjectSettings.get_setting("display/window/size/viewport_height"))
	):
		failure = "The active game viewport is not portrait-first."

	if failure.is_empty():
		game.call("_show_creator")
		await process_frame
		var power_grid: Node = game.find_child("PowerCardGrid", true, false)
		if power_grid == null or power_grid.get_child_count() != 6:
			failure = "The 3D character creator does not show all six power cards."
		elif game.find_child("HeroCreator", true, false) == null:
			failure = "The character creator did not open from the in-world start menu."
		elif game.find_child("HeroModelPreview", true, false) == null:
			failure = "The portrait character creator is missing its live 3D hero preview."
		else:
			game.call("_commit_hero_profile")
			await process_frame
			var bolt_action: Button = (
				game.find_child("PowerAction_elemental", true, false) as Button
			)
			var flight_action: Button = game.find_child("PowerAction_flight", true, false) as Button
			var strength_action: Button = (
				game.find_child("PowerAction_super_strength", true, false) as Button
			)
			if not bool(game.get("_gameplay_active")):
				failure = "The hero creator did not transition into the park patrol."
			elif bolt_action == null or flight_action == null or strength_action == null:
				failure = "The patrol HUD did not create its equipped power controls."
			elif (
				bolt_action.text != "BOLT\n1"
				or flight_action.text != "FLIGHT\n2"
				or strength_action.text != "SMASH\n3"
			):
				failure = "The power HUD slot order does not match its keyboard controls."

	var targets: Array[Node] = get_nodes_in_group("hero_targets_3d")
	var center_target: Node3D
	var side_target: Node3D
	for candidate: Node in targets:
		if not candidate is Node3D:
			continue
		var target: Node3D = candidate
		if absf(target.global_position.x) < 0.1:
			center_target = target
		elif side_target == null:
			side_target = target

	if failure.is_empty() and (center_target == null or side_target == null):
		failure = "The training range did not expose accessible targets."

	if failure.is_empty():
		(
			hero
			. call(
				"configure",
				{
					"name": "Test Nova",
					"powers": ["elemental"],
					"element": "fire",
				},
				park.call("get_park_bounds")
			)
		)
		hero.global_position = Vector3(0.0, 0.0, 9.0)
		hero.call("set_gameplay_enabled", true)
		center_target.call("reset_target")
		var fire_health: float = center_target.call("get_health")
		if not bool(hero.call("activate_power", "elemental")):
			failure = "3D elemental power did not activate."
		else:
			for _frame: int in range(60):
				await physics_frame
			if float(center_target.call("get_health")) >= fire_health:
				failure = "3D fire projectile did not damage its target."
			elif str(center_target.call("get_effect_status")) != "burning":
				failure = "3D fire affinity did not apply its burning status."

	if failure.is_empty():
		hero.call(
			"configure",
			{"name": "Test Nova", "powers": ["elemental"], "element": "ice"},
			park.call("get_park_bounds")
		)
		center_target.call("reset_target")
		if not bool(hero.call("activate_power", "elemental")):
			failure = "3D Ice affinity did not activate."
		else:
			for _frame: int in range(50):
				await physics_frame
			if str(center_target.call("get_effect_status")) != "frozen":
				failure = "3D Ice affinity did not freeze its target."

	if failure.is_empty():
		hero.call(
			"configure",
			{"name": "Test Nova", "powers": ["elemental"], "element": "lightning"},
			park.call("get_park_bounds")
		)
		center_target.call("reset_target")
		side_target.call("reset_target")
		var side_health: float = side_target.call("get_health")
		if not bool(hero.call("activate_power", "elemental")):
			failure = "3D lightning projectile did not activate."
		else:
			for _frame: int in range(60):
				await physics_frame
			if float(side_target.call("get_health")) >= side_health:
				failure = "3D lightning did not chain to a nearby training target."

	if failure.is_empty():
		hero.call(
			"configure",
			{"name": "Test Nova", "powers": ["super_strength"]},
			park.call("get_park_bounds")
		)
		hero.global_position = Vector3(0.0, 0.0, 4.0)
		center_target.call("reset_target")
		var strength_health: float = center_target.call("get_health")
		if not bool(hero.call("activate_power", "super_strength")):
			failure = "3D Super Strength did not activate."
		elif float(center_target.call("get_health")) >= strength_health:
			failure = "3D Super Strength did not damage a nearby target."

	if failure.is_empty():
		hero.call(
			"configure", {"name": "Test Nova", "powers": ["speed"]}, park.call("get_park_bounds")
		)
		hero.global_position = Vector3(0.0, 0.0, 10.0)
		var start_position: Vector3 = hero.global_position
		if not bool(hero.call("activate_power", "speed")):
			failure = "3D Super Speed did not activate."
		else:
			hero.call("set_virtual_movement", Vector2(1.0, 0.0))
			for _frame: int in range(30):
				await physics_frame
			hero.call("set_virtual_movement", Vector2.ZERO)
			if hero.global_position.distance_to(start_position) < 1.0:
				failure = "3D Super Speed did not move the hero."

	if failure.is_empty():
		hero.call(
			"configure",
			{"name": "Test Nova", "powers": ["teleportation"]},
			park.call("get_park_bounds")
		)
		hero.global_position = Vector3(0.0, 0.0, 9.0)
		var before_teleport: Vector3 = hero.global_position
		if not bool(hero.call("activate_power", "teleportation")):
			failure = "3D Teleportation did not activate."
		elif hero.global_position.distance_to(before_teleport) < 2.4:
			failure = "3D Teleportation did not blink through the training range."

	if failure.is_empty():
		hero.call(
			"configure",
			{"name": "Test Nova", "powers": ["beast", "flight"]},
			park.call("get_park_bounds")
		)
		if not bool(hero.call("activate_power", "beast")):
			failure = "3D Beast Form did not activate."
		elif not bool(hero.call("is_power_active", "beast")):
			failure = "3D Beast Form did not enter its enhanced state."
		elif not bool(hero.call("activate_power", "flight")):
			failure = "3D Flight did not activate."
		elif not bool(hero.call("is_power_active", "flight")):
			failure = "3D Flight did not enable its traversal state."
		else:
			for _frame: int in range(20):
				await physics_frame
			if hero.global_position.y <= 0.5:
				failure = "3D Flight did not lift the hero above the park."

	if failure.is_empty() and HeroPowerCatalog.get_all_powers().size() != 6:
		failure = "The shared power catalog does not expose all six powers to 3D."

	if not failure.is_empty():
		push_error("3D park smoke test failed: " + failure)
		quit(1)
		return

	print(
		"3D park smoke test passed: portrait intro, character creation, six powers, and training effects."
	)
	quit(0)
