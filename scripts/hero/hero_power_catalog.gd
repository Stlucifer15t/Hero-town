extends RefCounted

const MAX_EQUIPPED_POWERS: int = 3
const ELEMENT_TYPES: Array[Dictionary] = [
	{"id": "fire", "name": "FIRE", "color": "#ff824b"},
	{"id": "ice", "name": "ICE", "color": "#78dcff"},
	{"id": "lightning", "name": "LIGHTNING", "color": "#ffe16b"},
]


static func get_all_powers() -> Array[Dictionary]:
	return [
		{
			"id": "elemental",
			"name": "ELEMENTAL",
			"tagline": "Launch a chosen element",
			"description": "Fire burns, ice freezes, and lightning chains between nearby targets.",
			"cooldown": 1.2,
			"color": "#ff824b",
			"key": "1",
		},
		{
			"id": "super_strength",
			"name": "SUPER STRENGTH",
			"tagline": "Crack the ground",
			"description": "A heavy close-range smash deals high damage and knocks targets back.",
			"cooldown": 1.5,
			"color": "#f2c75c",
			"key": "2",
		},
		{
			"id": "speed",
			"name": "SUPER SPEED",
			"tagline": "Move and strike faster",
			"description": "Toggle a sprint, leave a speed trail, and shorten attack cooldowns.",
			"cooldown": 0.45,
			"color": "#87e9d2",
			"key": "3",
		},
		{
			"id": "teleportation",
			"name": "TELEPORTATION",
			"tagline": "Blink across the city",
			"description": "Instantly blink forward through obstacles, landing on safe ground.",
			"cooldown": 2.4,
			"color": "#bd9aff",
			"key": "4",
		},
		{
			"id": "beast",
			"name": "BEAST FORM",
			"tagline": "Transform for impact",
			"description": "Toggle a larger form with stronger, wider strikes and a speed boost.",
			"cooldown": 0.45,
			"color": "#ee8c76",
			"key": "5",
		},
		{
			"id": "flight",
			"name": "FLIGHT",
			"tagline": "Take to the sky",
			"description": "Toggle flight to hover, move faster, and cross water or rooftops.",
			"cooldown": 0.45,
			"color": "#a9d2ff",
			"key": "6",
		},
	]


static func get_power(power_id: String) -> Dictionary:
	for power: Dictionary in get_all_powers():
		if str(power["id"]) == power_id:
			return power.duplicate(true)
	return {}


static func get_all_elements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for element: Dictionary in ELEMENT_TYPES:
		result.append(element.duplicate(true))
	return result


static func get_element(element_id: String) -> Dictionary:
	for element: Dictionary in ELEMENT_TYPES:
		if str(element["id"]) == element_id:
			return element.duplicate(true)
	return ELEMENT_TYPES[0].duplicate(true)


static func sanitize_loadout(power_ids: Array) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in power_ids:
		var power_id: String = str(value)
		if get_power(power_id).is_empty() or result.has(power_id):
			continue
		result.append(power_id)
		if result.size() >= MAX_EQUIPPED_POWERS:
			break
	return result
