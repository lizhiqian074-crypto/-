extends Node
## Independent behavior-driven records. Any visible animal/pair may qualify.
signal event_triggered(event_id: String)
@export var debug_mode = false
@export var exploration_min_distance = 8.0
@export var explore_area_radius = 1.5
@export var friend_play_min_seconds = 2.0
@export var friend_play_duration = 7.0
var elapsed = 0.0
var observer: Node3D
var deer: AnimalAgent # Kept for debug keys and existing scene references.
var companion: AnimalAgent
var herd: Node
var areas: Array[Marker3D] = []
var meeting_actor: AnimalAgent
var friend_a: AnimalAgent
var friend_b: AnimalAgent
var play_center = Vector3.ZERO
var play_elapsed = 0.0
var play_distance = 0.0
var play_step = 0
var play_axis = Vector3.RIGHT
var play_side = Vector3.FORWARD
var play_last_a = Vector3.ZERO
var play_last_b = Vector3.ZERO
var last_play_end = -100.0
var rng = RandomNumberGenerator.new()

func configure(game: Node3D) -> void:
	observer = game.get_node("ObservationRig")
	deer = game.get_node("MainDeer")
	companion = game.get_node("CompanionDeer")
	herd = game.get_node("HerdManager")
	areas = [game.get_node("ExploreArea_A"), game.get_node("ExploreArea_B")]
	for animal in herd.animals:
		animal.intent_reached.connect(on_intent_reached.bind(animal))
	debug_mode = debug_mode or OS.get_cmdline_user_args().has("--debug-demo")
	rng.randomize()
	if GameManager.completed("NEW_COMPANION"): companion.visible = true

func _physics_process(delta: float) -> void:
	if get_tree().paused or not is_instance_valid(herd): return
	elapsed += delta
	# The first card pauses the world; same-frame events remain in a saved queue.
	if not SaveManager.data.pending_postcards.is_empty():
		dispatch_postcard()
		return
	check_exploration()
	update_friends(delta)
	if not GameManager.completed("FIRST_MEETING"):
		if not is_instance_valid(meeting_actor) or meeting_actor.state != AnimalAgent.State.APPROACH_PLAYER:
			for animal in herd.animals:
				if eligible(animal) and animal.mind.player_affinity >= 100:
					prepare_meeting(animal)
					if is_instance_valid(meeting_actor): break
	dispatch_postcard()

func eligible(animal: AnimalAgent) -> bool:
	return animal.visible and not animal.is_special() and animal.state != AnimalAgent.State.FLEE

func prepare_meeting(animal: AnimalAgent = null) -> void:
	if GameManager.completed("FIRST_MEETING"): return
	if animal == null: animal = deer
	if animal.mind.player_affinity < 100: return
	var point = observer.global_position
	point.y = animal.global_position.y
	var away = animal.global_position - point
	if away.length() < 3.5: return
	# At 4–7m, take a small lateral step: reaching 100 still produces real approach.
	var direction = away.normalized()
	if away.length() < 6.5: direction = direction.rotated(Vector3.UP, 0.7)
	point += direction * 4.5
	meeting_actor = animal
	animal.request_intent(AnimalAgent.State.APPROACH_PLAYER, point)

func exploration_target_for(animal: AnimalAgent) -> Vector3:
	if GameManager.completed("FIRST_EXPLORATION"): return Vector3.INF
	var candidates: Array[Marker3D] = []
	for area in areas:
		if not SaveManager.data.visited_explore_areas.has(str(area.name)) and horizontal_distance(area.global_position,animal.origin_position) >= exploration_min_distance:
			candidates.append(area)
	if candidates.is_empty(): return Vector3.INF
	return candidates[rng.randi_range(0,candidates.size()-1)].global_position

func prepare_exploration(animal: AnimalAgent = null) -> void:
	if animal == null: animal = deer
	var target = exploration_target_for(animal)
	if target.is_finite(): animal.request_intent(AnimalAgent.State.GO_TO_EXPLORE_AREA,target)

func horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x,a.z).distance_to(Vector2(b.x,b.z))

func check_exploration() -> void:
	if GameManager.completed("FIRST_EXPLORATION"): return
	for animal in herd.animals:
		if not animal.visible or animal.total_distance_walked < 1.0: continue
		for area in areas:
			if SaveManager.data.visited_explore_areas.has(str(area.name)): continue
			if horizontal_distance(animal.global_position,area.global_position) <= explore_area_radius and horizontal_distance(area.global_position,animal.origin_position) >= exploration_min_distance:
				SaveManager.data.visited_explore_areas.append(str(area.name))
				animal.mind.remember("first_exploration",str(area.name))
				record_occurrence("FIRST_EXPLORATION")
				return

func prepare_companion() -> void:
	# Developer key F3: prepare a full-affinity pair; normal play never changes values.
	companion.visible = true
	deer.mind.relations[companion.animal_id] = 100
	companion.mind.relations[deer.animal_id] = 100
	start_friendship(deer,companion)

func start_friendship(a: AnimalAgent,b: AnimalAgent) -> void:
	if is_instance_valid(friend_a): return
	if a.mind.affinity_to(b.animal_id) < 100 or b.mind.affinity_to(a.animal_id) < 100: return
	friend_a = a
	friend_b = b
	play_elapsed = 0
	play_distance = 0
	play_center = (a.global_position + b.global_position) / 2
	play_axis = a.global_position - b.global_position
	play_axis.y = 0
	play_axis = play_axis.normalized() if play_axis.length() > 0.1 else Vector3.RIGHT
	play_side = play_axis.rotated(Vector3.UP,PI/2)
	a.request_intent(AnimalAgent.State.APPROACH_COMPANION,play_center + play_axis)
	b.request_intent(AnimalAgent.State.APPROACH_COMPANION,play_center - play_axis)

func update_friends(delta: float) -> void:
	if not is_instance_valid(friend_a) or not is_instance_valid(friend_b):
		friend_a = null
		friend_b = null
		if elapsed - last_play_end < 15: return
		for i in range(herd.animals.size()):
			var a: AnimalAgent = herd.animals[i]
			if not eligible(a): continue
			for j in range(i+1,herd.animals.size()):
				var b: AnimalAgent = herd.animals[j]
				if eligible(b) and a.mind.affinity_to(b.animal_id) >= 100 and b.mind.affinity_to(a.animal_id) >= 100:
					start_friendship(a,b)
					return
		return
	if friend_a.mind.affinity_to(friend_b.animal_id) < 100 or friend_b.mind.affinity_to(friend_a.animal_id) < 100 or friend_a.state == AnimalAgent.State.FLEE or friend_b.state == AnimalAgent.State.FLEE:
		end_play()
		return
	if friend_a.state == AnimalAgent.State.APPROACH_COMPANION and friend_a.arrived and friend_b.arrived:
		play_step = 0
		play_last_a = friend_a.global_position
		play_last_b = friend_b.global_position
		set_play_targets()
	if friend_a.state != AnimalAgent.State.PLAY_TOGETHER: return
	play_elapsed += delta
	play_distance += friend_a.global_position.distance_to(play_last_a) + friend_b.global_position.distance_to(play_last_b)
	play_last_a = friend_a.global_position
	play_last_b = friend_b.global_position
	if friend_a.arrived and friend_b.arrived:
		play_step = (play_step + 1) % 4
		set_play_targets()
	if play_elapsed >= friend_play_min_seconds and play_distance >= 0.8 and not GameManager.completed("NEW_COMPANION"):
		friend_a.mind.remember("new_companion",friend_b.animal_id)
		friend_b.mind.remember("new_companion",friend_a.animal_id)
		record_occurrence("NEW_COMPANION")
	if play_elapsed >= friend_play_duration: end_play()

func set_play_targets() -> void:
	var offsets = [play_axis + play_side*0.8, play_axis - play_side*0.8, -play_axis - play_side*0.8, -play_axis + play_side*0.8]
	friend_a.set_state(AnimalAgent.State.PLAY_TOGETHER,play_center + offsets[play_step])
	friend_b.set_state(AnimalAgent.State.PLAY_TOGETHER,play_center + offsets[(play_step+2)%4])

func end_play() -> void:
	for animal in [friend_a,friend_b]:
		if is_instance_valid(animal) and animal.state in [AnimalAgent.State.APPROACH_COMPANION,AnimalAgent.State.PLAY_TOGETHER]: animal.set_state(AnimalAgent.State.LOOK_AROUND)
	friend_a = null
	friend_b = null
	last_play_end = elapsed

func on_intent_reached(state_name: String, animal: AnimalAgent) -> void:
	if state_name == "APPROACH_PLAYER":
		var distance = animal.distance_to_observer()
		if animal.mind.player_affinity >= 100 and distance >= 4 and distance <= 7 and animal.distance_walked_in_intent >= 1:
			animal.mind.remember("first_meeting")
			record_occurrence("FIRST_MEETING")
		animal.set_state(AnimalAgent.State.LOOK_AROUND)
		if animal == meeting_actor: meeting_actor = null
	elif state_name == "GO_TO_EXPLORE_AREA":
		check_exploration()
		animal.set_state(AnimalAgent.State.LOOK_AROUND)

func record_occurrence(id: String) -> void:
	GameManager.record_event(id,true)

func dispatch_postcard() -> void:
	if get_tree().paused or SaveManager.data.pending_postcards.is_empty(): return
	var id = str(SaveManager.data.pending_postcards.pop_front())
	SaveManager.save_data()
	event_triggered.emit(id)

func _unhandled_input(event: InputEvent) -> void:
	if not debug_mode: return
	if event.is_action_pressed("debug_event_1"):
		deer.mind.player_affinity = 100
		deer.mind.threat_until = 0
		deer.alertness = 0
		prepare_meeting()
	elif event.is_action_pressed("debug_event_2"): prepare_exploration()
	elif event.is_action_pressed("debug_event_3"): prepare_companion()
	elif event.is_action_pressed("debug_reset_save"):
		GameManager.reset_save()
		GameManager.go_to("Game")
