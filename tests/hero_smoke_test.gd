extends SceneTree

const HeroPowerCatalog = preload("res://scripts/hero/hero_power_catalog.gd")
const HeroCharacter = preload("res://scripts/hero/hero_character.gd")
const HeroCreationMenu = preload("res://scripts/hero/hero_creation_menu.gd")
const HeroTrainingTarget = preload("res://scripts/hero/hero_training_target.gd")
const HeroTestMap = preload("res://tests/hero_test_map.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failure: String = ""
	var powers: Array[Dictionary] = HeroPowerCatalog.get_all_powers()
	if powers.size() != 6:
		failure = "Expected six selectable, data-backed hero powers."
	elif HeroPowerCatalog.MAX_EQUIPPED_POWERS != 3:
		failure = "The hero loadout limit is incorrect."

	var creator: CanvasLayer
	if failure.is_empty():
		creator = HeroCreationMenu.new()
		creator.call("configure", false, {})
		root.add_child(creator)
		await process_frame
		for power: Dictionary in powers:
			var power_button: Node = creator.find_child("Power_%s" % str(power["id"]), true, false)
			if power_button == null:
				failure = "Character creation is missing the %s power card." % str(power["name"])
				break
		creator.queue_free()

	var hero: Node2D
	var target: Node2D
	if failure.is_empty():
		hero = HeroCharacter.new()
		hero.name = "TestHero"
		root.add_child(hero)
		(
			hero
			. call(
				"configure",
				{
					"name": "Test Nova",
					"suit_color": "#45bcae",
					"cape_color": "#e7645d",
					"powers": ["elemental", "super_strength", "speed"],
					"element": "fire",
				},
				null
			)
		)
		target = HeroTrainingTarget.new()
		target.name = "TestTarget"
		root.add_child(target)
		target.global_position = Vector2(48.0, 12.0)
		await process_frame

	if failure.is_empty():
		var starting_health: float = target.call("get_health")
		if not bool(hero.call("activate_power", "super_strength")):
			failure = "Super Strength did not activate."
		elif float(target.call("get_health")) >= starting_health:
			failure = "Super Strength did not damage a nearby training target."

	if failure.is_empty():
		if not bool(hero.call("activate_power", "speed")):
			failure = "Super Speed did not activate."
		elif not bool(hero.call("is_power_active", "speed")):
			failure = "Super Speed did not enter its active movement state."
		else:
			hero.call("set_virtual_movement", Vector2(1.0, 0.0))
			var before_move: Vector2 = hero.global_position
			hero.call("_process", 0.2)
			if hero.global_position.distance_to(before_move) <= 1.0:
				failure = "Super Speed did not move the hero."
			hero.call("set_virtual_movement", Vector2.ZERO)

	if failure.is_empty():
		hero.call("configure", {"name": "Test Nova", "powers": ["teleportation"]}, null)
		var before_teleport: Vector2 = hero.global_position
		if not bool(hero.call("activate_power", "teleportation")):
			failure = "Teleportation did not activate."
		elif hero.global_position.distance_to(before_teleport) < 100.0:
			failure = "Teleportation did not blink the hero forward."

	if failure.is_empty():
		hero.call("configure", {"name": "Test Nova", "powers": ["beast", "flight"]}, null)
		if not bool(hero.call("activate_power", "beast")):
			failure = "Beast Form did not activate."
		elif not bool(hero.call("is_power_active", "beast")):
			failure = "Beast Form did not change the hero's state."
		if not bool(hero.call("activate_power", "flight")):
			failure = "Flight did not activate."
		elif not bool(hero.call("is_power_active", "flight")):
			failure = "Flight did not change the hero's traversal state."

	var elemental_target: Node2D
	if failure.is_empty():
		hero.call(
			"configure", {"name": "Test Nova", "powers": ["elemental"], "element": "fire"}, null
		)
		elemental_target = HeroTrainingTarget.new()
		elemental_target.name = "ElementalTestTarget"
		root.add_child(elemental_target)
		elemental_target.global_position = hero.global_position + Vector2(72.0, 18.0)
		await process_frame
		if not bool(hero.call("activate_power", "elemental")):
			failure = "Elemental power did not launch."
		else:
			for _frame: int in range(20):
				await process_frame
			if (
				float(elemental_target.call("get_health"))
				>= float(elemental_target.call("get_max_health"))
			):
				failure = "Elemental projectile did not affect its target."
			elif str(elemental_target.call("get_effect_status")) != "burning":
				failure = "Fire affinity did not apply its burning effect."

	if failure.is_empty():
		var ice_profile: Dictionary = {
			"name": "Test Nova",
			"powers": ["elemental"],
			"element": "ice",
		}
		hero.call("configure", ice_profile, null)
		elemental_target.call("reset_target")
		elemental_target.global_position = hero.global_position + Vector2(72.0, 18.0)
		if not bool(hero.call("activate_power", "elemental")):
			failure = "Ice affinity did not launch."
		else:
			for _frame: int in range(20):
				await process_frame
			if str(elemental_target.call("get_effect_status")) != "frozen":
				failure = "Ice affinity did not freeze its target."

	var lightning_chain_target: Node2D
	if failure.is_empty():
		var lightning_profile: Dictionary = {
			"name": "Test Nova",
			"powers": ["elemental"],
			"element": "lightning",
		}
		hero.call("configure", lightning_profile, null)
		elemental_target.call("reset_target")
		elemental_target.global_position = hero.global_position + Vector2(72.0, 18.0)
		lightning_chain_target = HeroTrainingTarget.new()
		lightning_chain_target.name = "LightningChainTarget"
		root.add_child(lightning_chain_target)
		lightning_chain_target.global_position = hero.global_position + Vector2(132.0, 33.0)
		await process_frame
		if not bool(hero.call("activate_power", "elemental")):
			failure = "Lightning affinity did not launch."
		else:
			for _frame: int in range(20):
				await process_frame
			if str(elemental_target.call("get_effect_status")) != "shocked":
				failure = "Lightning did not shock its first target."
			elif (
				float(lightning_chain_target.call("get_health"))
				>= float(lightning_chain_target.call("get_max_health"))
			):
				failure = "Lightning did not chain to a nearby target."

	if failure.is_empty():
		var blocked_map: Node2D = HeroTestMap.new()
		root.add_child(blocked_map)
		hero.call("configure", {"powers": ["flight"]}, blocked_map)
		hero.global_position = Vector2.ZERO
		hero.call("set_virtual_movement", Vector2(1.0, 0.0))
		hero.call("_process", 0.2)
		var grounded_position: Vector2 = hero.global_position
		hero.call("activate_power", "flight")
		hero.call("_process", 0.2)
		if hero.global_position.distance_to(grounded_position) <= 1.0:
			failure = "Flight did not cross terrain blocked to a grounded hero."

	if not failure.is_empty():
		push_error("Hero smoke test failed: " + failure)
		quit(1)
		return

	print(
		(
			"Hero smoke test passed: character creation lists six powers; "
			+ "Strength, Speed, Teleport, Beast, Flight, and Elemental all have usable effects."
		)
	)
	quit(0)
