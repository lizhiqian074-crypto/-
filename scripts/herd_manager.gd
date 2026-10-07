extends Node
## Owns world time and coordination only. Each deer owns its own mind and FSM.
@export var autosave_interval = 15.0
@export var habitat_help_cooldown = 20.0
var animals: Array[AnimalAgent] = []
var observer: Node3D
var forage_patch: Marker3D
var save_clock = 0.0
var social_clock = 0.0
var created_epoch = 0
var environment: Dictionary = {}
var rng = RandomNumberGenerator.new()

func configure(game: Node3D) -> void:
	created_epoch = SaveManager.reset_epoch
	observer = game.get_node("ObservationRig")
	forage_patch = game.get_node("ForagePatch")
	rng.randomize()
	environment = SaveManager.data.get("habitat", {}).duplicate(true)
	if environment.is_empty():
		environment = {"food_supply": 30.0, "help_generation": 0, "last_help": -1000.0}
	for child in game.get_children():
		if child is AnimalAgent:
			animals.append(child)
			child.observer = observer
			child.herd = self
	SaveManager.collecting_save.connect(sync_save)

func _physics_process(delta: float) -> void:
	if animals.is_empty() or created_epoch != SaveManager.reset_epoch:
		return
	SaveManager.data.world_seconds = float(SaveManager.data.get("world_seconds",0)) + delta
	for animal in animals:
		if not animal.visible:
			continue
		if animal.state == AnimalAgent.State.FORAGE and animal.global_position.distance_to(forage_patch.global_position) < 5.0 and environment.food_supply > 0:
			environment.food_supply = maxf(0, environment.food_supply - delta * 0.5)
			animal.hunger = maxf(0, animal.hunger - delta * 2)
			animal.mind.record_help(int(environment.help_generation))
		for other in animals:
			if other == animal or not other.visible:
				continue
			var distance = animal.global_position.distance_to(other.global_position)
			if distance < 3.0:
				animal.mind.social_contact(other.animal_id, delta, distance < 0.6)
	social_clock += delta
	if social_clock >= 4.0:
		social_clock = 0
		for animal in animals:
			consider_company(animal)
	save_clock += delta
	if save_clock >= autosave_interval:
		save_clock = 0
		SaveManager.save_data()

func consider_company(animal: AnimalAgent) -> void:
	if not animal.visible or animal.is_special() or animal.state in [AnimalAgent.State.FLEE,AnimalAgent.State.SOCIALIZE,AnimalAgent.State.ALERT] or animal.hunger > 65 or animal.energy < 30:
		return
	var sociability = float(animal.mind.personality.get("sociability",0.5))
	if rng.randf() > sociability * 0.38 or animal.mind.fear > 55:
		return
	var closest: AnimalAgent = null
	var best_distance = 12.0
	for other in animals:
		if other == animal or not other.visible or other.is_special() or other.state == AnimalAgent.State.FLEE:
			continue
		var distance = animal.global_position.distance_to(other.global_position)
		if distance < best_distance and animal.mind.affinity_to(other.animal_id) >= 30:
			closest = other
			best_distance = distance
	if closest:
		var away = animal.global_position - closest.global_position
		if away.length() < 0.1:
			away = Vector3(1,0,0)
		animal.set_state(AnimalAgent.State.SOCIALIZE, closest.global_position + away.normalized() * 1.8)

func help_habitat() -> bool:
	var now = float(SaveManager.data.get("world_seconds",0))
	if now - float(environment.get("last_help",-1000)) < habitat_help_cooldown:
		return false
	environment.last_help = now
	environment.help_generation = int(environment.get("help_generation",0)) + 1
	environment.food_supply = minf(100, float(environment.get("food_supply",0)) + 55)
	# No command goes to an animal. A deer benefits only if it chooses to forage here.
	SaveManager.save_data()
	return true

func sync_save() -> void:
	if created_epoch != SaveManager.reset_epoch:
		return
	var snapshots: Dictionary = SaveManager.data.get("animals", {}).duplicate(true)
	for animal in animals:
		if is_instance_valid(animal) and is_instance_valid(animal.mind):
			var previously_seen = bool(snapshots.get(animal.animal_id, {}).get("observed", false))
			snapshots[animal.animal_id] = animal.mind.snapshot()
			snapshots[animal.animal_id]["observed"] = previously_seen or animal.visible
	SaveManager.data.animals = snapshots
	SaveManager.data.habitat = environment.duplicate(true)

func _exit_tree() -> void:
	if SaveManager.collecting_save.is_connected(sync_save):
		SaveManager.collecting_save.disconnect(sync_save)
	if created_epoch == SaveManager.reset_epoch:
		sync_save()
		SaveManager.save_data()
