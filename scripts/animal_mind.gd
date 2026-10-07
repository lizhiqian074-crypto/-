class_name AnimalMind
extends Node
## Personality, emotions, memory and directional relations for ONE animal.
## It is local simulation AI; no server or language-model calls exist.
signal memory_added(kind: String)
@export var memory_limit = 20
@export var calm_affinity_gain = 3.0
@export var disturbance_cooldown = 12.0
@export var fear_memory_days = 2.0
var animal_id = ""
var display_name = ""
var personality: Dictionary = {}
var player_affinity = 35.0
var fear = 0.0
var mood = "平静"
var relations: Dictionary = {}
var memories: Array = []
var counters = {"calm_seconds": 0.0, "disturbances": 0, "help_received": 0, "social_contacts": 0}
var threat_until = 0.0
var last_disturbance = -1000.0
var last_help_generation = 0
var last_social_memory: Dictionary = {}
var calm_memory_clock = 0.0
var previous_observer_speed = 0.0
var owner_animal: Node3D

func configure(animal: Node3D, id: String, title: String, profile: Dictionary) -> void:
	owner_animal = animal
	animal_id = id
	display_name = title
	personality = profile.duplicate(true)
	var saved = SaveManager.data.get("animals", {}).get(id, {})
	if saved is Dictionary:
		load_snapshot(saved)

func number(value: Variant, fallback: float, low: float, high: float) -> float:
	if not (value is float or value is int) or not is_finite(float(value)):
		return fallback
	return clampf(float(value), low, high)

func load_snapshot(saved: Dictionary) -> void:
	player_affinity = number(saved.get("player_affinity"), 35.0, 0, 100)
	fear = number(saved.get("fear"), 0.0, 0, 100)
	threat_until = number(saved.get("threat_until"), 0, 0, 1e12)
	last_disturbance = number(saved.get("last_disturbance"), -1000, -1000, 1e12)
	last_help_generation = int(number(saved.get("last_help_generation"), 0, 0, 1e9))
	if saved.get("relations") is Dictionary:
		for id in saved.relations:
			relations[str(id)] = number(saved.relations[id], 35, 0, 100)
	if saved.get("counters") is Dictionary:
		for key in counters:
			counters[key] = number(saved.counters.get(key), 0, 0, 1e12)
	if saved.get("memories") is Array:
		for entry in saved.memories:
			if entry is Dictionary and entry.get("kind") is String and entry.get("actor") is String:
				memories.append({"kind": entry.kind, "actor": entry.actor, "time": number(entry.get("time"),0,0,1e12)})
	while memories.size() > memory_limit:
		memories.pop_front()

func now() -> float:
	return float(SaveManager.data.get("world_seconds", 0.0))

func fear_memory_active() -> bool:
	return threat_until > now()

func remember(kind: String, actor: String = "player") -> void:
	memories.append({"kind": kind, "actor": actor, "time": now()})
	while memories.size() > memory_limit:
		memories.pop_front()
	memory_added.emit(kind)

func observe(delta: float, observer_distance: float, observer_speed: float, energy: float, hunger: float) -> void:
	var in_range = observer_distance < 18.0
	var suddenly_moving = observer_speed > 1.8 and previous_observer_speed < 0.65
	var too_close = observer_distance < 2.8
	if in_range and ((observer_distance < 9.0 and suddenly_moving) or too_close):
		if now() - last_disturbance >= disturbance_cooldown:
			record_disturbance()
	elif observer_distance >= 3.5 and in_range and observer_speed < 0.6:
		var gain = calm_affinity_gain * (0.6 + float(personality.get("curiosity", 0.5)))
		if fear_memory_active():
			gain *= 0.35
		player_affinity = clampf(player_affinity + delta * gain, 0, 100)
		counters.calm_seconds += delta
		calm_memory_clock += delta
		if calm_memory_clock >= 25.0:
			calm_memory_clock = 0
			remember("calm_observation")
	# At complete trust, old fear no longer overrides the new relationship.
	if player_affinity >= 100:
		threat_until = 0
		fear = 0
	previous_observer_speed = observer_speed
	fear = maxf(0, fear - delta * (0.5 if fear_memory_active() else 1.5))
	if too_close or (fear_memory_active() and observer_distance < avoidance_radius()):
		mood = "不安"
	elif hunger > 65:
		mood = "寻找食物"
	elif energy < 30:
		mood = "疲倦"
	elif player_affinity > 60:
		mood = "安心"
	else:
		mood = "平静"

func record_disturbance() -> void:
	last_disturbance = now()
	player_affinity = maxf(0, player_affinity - 16.0)
	fear = minf(100, fear + 45.0 * (1.2 - float(personality.get("courage", 0.4))))
	# Demo ecological day = 180 seconds, so avoidance lasts two simulated days.
	threat_until = now() + fear_memory_days * 180.0
	counters.disturbances += 1
	remember("startled")

func avoidance_radius() -> float:
	if not fear_memory_active():
		return 2.8
	return 4.5 + float(personality.get("vigilance", 0.5)) * 3.0

func record_help(generation: int) -> void:
	if generation <= last_help_generation:
		return
	last_help_generation = generation
	player_affinity = minf(100, player_affinity + 12.0)
	fear = maxf(0, fear - 8.0)
	counters.help_received += 1
	remember("habitat_help")

func affinity_to(other_id: String) -> float:
	return float(relations.get(other_id, 35.0))

func social_contact(other_id: String, delta: float, crowded: bool = false) -> void:
	var value = affinity_to(other_id)
	var social = float(personality.get("sociability", 0.5))
	value += delta * (-0.3 if crowded else 4.0 + social * 3.0)
	relations[other_id] = clampf(value, 0, 100)
	if now() - float(last_social_memory.get(other_id, -1000)) > 30.0:
		last_social_memory[other_id] = now()
		counters.social_contacts += 1
		remember("crowded" if crowded else "friendly_contact", other_id)

func snapshot() -> Dictionary:
	return {"name": display_name, "personality": personality.duplicate(true), "player_affinity": player_affinity,
		"fear": fear, "mood": mood, "threat_until": threat_until, "last_disturbance": last_disturbance,
		"last_help_generation": last_help_generation, "relations": relations.duplicate(true),
		"memories": memories.duplicate(true), "counters": counters.duplicate(true)}

func attitude() -> String:
	if fear_memory_active():
		return "还记得惊扰，保持距离"
	if player_affinity >= 65:
		return "愿意与你接近"
	if player_affinity >= 45:
		return "逐渐熟悉你的存在"
	if player_affinity < 25:
		return "谨慎地避开你"
	return "正在认识你"

func personality_text() -> String:
	var names: Array[String] = []
	if float(personality.get("curiosity",0)) >= 0.7: names.append("好奇")
	if float(personality.get("courage",0)) < 0.35: names.append("胆小")
	elif float(personality.get("courage",0)) >= 0.65: names.append("勇敢")
	if float(personality.get("sociability",0)) >= 0.65: names.append("亲近同伴")
	elif float(personality.get("sociability",0)) < 0.4: names.append("喜欢独处")
	return " · ".join(names)
