extends Node
## Only these three narrative events exist. Signals separate animal logic and UI.
signal event_triggered(event_id: String)
@export var debug_mode = false
@export var first_meeting_min_time = 35.0
@export var exploration_delay = 30.0
@export var companion_delay = 30.0
@export var meeting_curiosity_threshold = 52.0
@export var meeting_alertness_threshold = 30.0
@export var companion_contact_seconds = 3.0
@export var decision_chance_per_second = 0.35
var elapsed = 0.0
var quiet_observation = 0.0
var phase_elapsed = 0.0
var contact_elapsed = 0.0
var visited_areas: Array[String] = []
var observer: Node3D
var deer: AnimalAgent
var companion: AnimalAgent
var explore_a: Marker3D
var explore_b: Marker3D
var companion_spawn: Marker3D
var rng = RandomNumberGenerator.new()

func configure(game: Node3D) -> void:
	observer = game.get_node("ObservationRig")
	deer = game.get_node("MainDeer")
	companion = game.get_node("CompanionDeer")
	explore_a = game.get_node("ExploreArea_A")
	explore_b = game.get_node("ExploreArea_B")
	companion_spawn = game.get_node("CompanionSpawn")
	deer.observer = observer
	deer.intent_reached.connect(on_intent_reached)
	debug_mode = debug_mode or OS.get_cmdline_user_args().has("--debug-demo")
	rng.randomize()
	if GameManager.completed("NEW_COMPANION"):
		spawn_companion()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(deer):
		return
	elapsed += delta
	phase_elapsed += delta
	if observer.speed < 0.6 and deer.distance_to_observer() >= 3.0:
		quiet_observation += delta
	else:
		quiet_observation = maxf(0, quiet_observation - delta * 2)
	if GameManager.completed("NEW_COMPANION"):
		return
	if deer.is_special():
		if deer.state == AnimalAgent.State.APPROACH_COMPANION:
			update_contact(delta)
		return
	var chance = rng.randf() < 1.0 - exp(-decision_chance_per_second * delta)
	if not chance:
		return
	if not GameManager.completed("FIRST_MEETING"):
		var wait = 5.0 if debug_mode else first_meeting_min_time
		var curiosity_required = 25.0 if debug_mode else meeting_curiosity_threshold
		if elapsed >= wait and quiet_observation >= wait * 0.7 and deer.alertness <= meeting_alertness_threshold and deer.curiosity >= curiosity_required and deer.mind.player_affinity >= 40 and not deer.mind.fear_memory_active():
			prepare_meeting()
	elif not GameManager.completed("FIRST_EXPLORATION"):
		if phase_elapsed >= (5.0 if debug_mode else exploration_delay):
			prepare_exploration()
	elif phase_elapsed >= (5.0 if debug_mode else companion_delay):
		prepare_companion()

func prepare_meeting() -> void:
	if GameManager.completed("FIRST_MEETING"):
		return
	# Stop 5 m short. If observer is too near, a player approach cannot complete it.
	var point = observer.global_position
	point.y = deer.global_position.y
	var away = deer.global_position - point
	if away.length() < 7.0:
		return
	point += away.normalized() * 5.0
	deer.request_intent(AnimalAgent.State.APPROACH_PLAYER, point)

func prepare_exploration() -> void:
	if not GameManager.completed("FIRST_MEETING") or GameManager.completed("FIRST_EXPLORATION"):
		return
	var area = explore_a if rng.randf() < 0.5 else explore_b
	deer.request_intent(AnimalAgent.State.GO_TO_EXPLORE_AREA, area.global_position)

func spawn_companion() -> void:
	companion.position = companion_spawn.position
	companion.home_position = companion.position
	companion.visible = true

func prepare_companion() -> void:
	if not GameManager.completed("FIRST_EXPLORATION") or GameManager.completed("NEW_COMPANION"):
		return
	spawn_companion()
	contact_elapsed = 0
	var midpoint = (deer.global_position + companion.global_position) / 2
	deer.request_intent(AnimalAgent.State.APPROACH_COMPANION, midpoint + Vector3(-0.8, 0, 0))
	companion.request_intent(AnimalAgent.State.APPROACH_COMPANION, midpoint + Vector3(0.8, 0, 0))

func update_contact(delta: float) -> void:
	if not companion.visible:
		return
	if deer.global_position.distance_to(companion.global_position) < 3.0:
		contact_elapsed += delta
	else:
		contact_elapsed = 0
	if contact_elapsed >= companion_contact_seconds:
		deer.mind.relations[companion.animal_id] = maxf(65, deer.mind.affinity_to(companion.animal_id))
		companion.mind.relations[deer.animal_id] = maxf(65, companion.mind.affinity_to(deer.animal_id))
		deer.mind.remember("new_companion", companion.animal_id)
		companion.mind.remember("new_companion", deer.animal_id)
		deer.home_position = deer.global_position
		companion.home_position = companion.global_position
		deer.set_state(AnimalAgent.State.IDLE)
		companion.set_state(AnimalAgent.State.LOOK_AROUND)
		trigger("NEW_COMPANION")

func on_intent_reached(state_name: String) -> void:
	if state_name == "APPROACH_PLAYER":
		var distance = deer.distance_to_observer()
		if distance >= 4.0 and distance <= 7.0 and deer.distance_walked_in_intent >= 1.0 and observer.speed < 0.6 and deer.alertness < 65:
			deer.set_state(AnimalAgent.State.LOOK_AROUND)
			trigger("FIRST_MEETING")
		else:
			deer.set_state(AnimalAgent.State.IDLE)
	elif state_name == "GO_TO_EXPLORE_AREA":
		var area = explore_a if deer.global_position.distance_to(explore_a.global_position) < 1.5 else explore_b
		if deer.global_position.distance_to(area.global_position) < 1.5 and not visited_areas.has(area.name):
			visited_areas.append(area.name)
			deer.home_position = area.global_position
			deer.set_state(AnimalAgent.State.LOOK_AROUND)
			trigger("FIRST_EXPLORATION")

func trigger(id: String) -> void:
	if GameManager.record_event(id):
		phase_elapsed = 0
		event_triggered.emit(id)

func _unhandled_input(event: InputEvent) -> void:
	if not debug_mode:
		return
	if event.is_action_pressed("debug_event_1"):
		deer.alertness = 0
		deer.curiosity = 100
		deer.mind.player_affinity = maxf(50, deer.mind.player_affinity)
		deer.mind.threat_until = 0
		prepare_meeting()
	elif event.is_action_pressed("debug_event_2"):
		prepare_exploration()
	elif event.is_action_pressed("debug_event_3"):
		prepare_companion()
	elif event.is_action_pressed("debug_reset_save"):
		GameManager.reset_save()
		GameManager.go_to("Game")
