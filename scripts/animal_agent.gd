class_name AnimalAgent
extends Node3D
## Autonomous weighted FSM. Special states are requests, not UI commands.
signal intent_reached(state_name: String)
signal state_changed(state_name: String)
enum State { IDLE, WANDER, FORAGE, REST, ALERT, LOOK_AROUND, APPROACH_PLAYER, GO_TO_EXPLORE_AREA, APPROACH_COMPANION }
@export var move_speed = 1.1
@export var home_radius = 6.0
@export var arrival_distance = 0.65
@export var turn_speed = 2.5
@export var is_companion = false
@export var use_navigation = true
@export var fallback_half_extent = 18.0
@export var curiosity_gain = 1.5
@export var idle_animation_name = "Idle"
@export var walk_animation_name = "Walk"
@export var eat_animation_name = "Eat"
@export var rest_animation_name = "Rest"
@export var alert_animation_name = "Alert"
var energy = 80.0
var hunger = 25.0
var alertness = 35.0
var curiosity = 15.0
var state: State = State.IDLE
var state_remaining = 4.0
var home_position = Vector3.ZERO
var target = Vector3.ZERO
var observer: Node3D
var animation_controller: AnimalAnimationController
var distance_walked_in_intent = 0.0
var intent_elapsed = 0.0
var arrived = false
var fallback_visual: Node3D
var rng = RandomNumberGenerator.new()
@onready var agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	rng.randomize()
	home_position = position
	target = position
	load_visual()
	set_state(State.IDLE)

func load_visual() -> void:
	var model = AssetCatalog.model("deer_model")
	if model == null:
		# Clearly marked primitive stand-in, never presented as the user's asset.
		model = PlaceholderWorld.deer_marker()
		fallback_visual = model
	else:
		model.scale *= float(AssetCatalog.config.get("deer_scale", 1.0))
		model.position = AssetCatalog.vector_setting("deer_offset")
		model.rotation.y = deg_to_rad(float(AssetCatalog.config.get("deer_yaw_degrees", 0.0)))
	$Visual.add_child(model)
	animation_controller = AnimalAnimationController.new()
	for key in ["idle_animation_name", "walk_animation_name", "eat_animation_name", "rest_animation_name", "alert_animation_name"]:
		animation_controller.set(key, get(key))
	add_child(animation_controller)
	animation_controller.bind_model(model)

func state_name() -> String:
	return State.keys()[state]

func set_state(next: State, destination: Vector3 = Vector3.INF) -> void:
	state = next
	state_remaining = rng.randf_range(3.5, 8.0)
	arrived = false
	intent_elapsed = 0.0
	distance_walked_in_intent = 0.0
	if destination.is_finite():
		target = destination
	elif state == State.WANDER:
		var angle = rng.randf_range(0, TAU)
		target = home_position + Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(2, home_radius)
	target.x = clampf(target.x, -fallback_half_extent + 1, fallback_half_extent - 1)
	target.z = clampf(target.z, -fallback_half_extent + 1, fallback_half_extent - 1)
	if is_node_ready():
		var map = agent.get_navigation_map()
		if navigation_available(map):
			target = NavigationServer3D.map_get_closest_point(map, target)
		agent.target_position = target
		animation_controller.play_state(state_name())
	state_changed.emit(state_name())

func is_special() -> bool:
	return state in [State.APPROACH_PLAYER, State.GO_TO_EXPLORE_AREA, State.APPROACH_COMPANION]

func request_intent(next: State, destination: Vector3) -> void:
	set_state(next, destination)

func distance_to_observer() -> float:
	if not is_instance_valid(observer):
		return 100.0
	var a = global_position
	var b = observer.global_position
	a.y = 0
	b.y = 0
	return a.distance_to(b)

func _physics_process(delta: float) -> void:
	if not visible:
		return
	intent_elapsed += delta
	update_needs(delta)
	if is_special():
		if state == State.APPROACH_PLAYER and (alertness > 65 or distance_to_observer() < 3.0):
			set_state(State.ALERT)
			return
		if not arrived:
			move_towards_target(delta)
		# No baked path / unreachable target: recover instead of locking AI forever.
		if intent_elapsed > 45 and not arrived:
			set_state(State.IDLE)
	elif state == State.WANDER:
		move_towards_target(delta)
		state_remaining -= delta
		if arrived or state_remaining < -12:
			choose_behavior()
	else:
		state_remaining -= delta
		if state_remaining <= 0:
			choose_behavior()
	if is_instance_valid(fallback_visual):
		# Subtle breathing only; locomotion still comes from the real FSM.
		fallback_visual.position.y = sin(Time.get_ticks_msec() * 0.002) * 0.015

func update_needs(delta: float) -> void:
	hunger = clampf(hunger + delta * 0.25, 0, 100)
	energy = clampf(energy - delta * 0.15, 0, 100)
	if state == State.REST:
		energy = clampf(energy + delta * 2.5, 0, 100)
	if state == State.FORAGE:
		hunger = clampf(hunger - delta * 3.0, 0, 100)
	if is_companion:
		return
	var distance = distance_to_observer()
	if distance < 3.0:
		alertness = clampf(alertness + delta * 12, 0, 100)
		curiosity = clampf(curiosity - delta * 2, 0, 100)
	else:
		alertness = clampf(alertness - delta * 1.2, 0, 100)
		if distance < 30 and is_instance_valid(observer) and observer.get("speed") < 0.6:
			curiosity = clampf(curiosity + delta * curiosity_gain, 0, 100)

func choose_behavior() -> void:
	var choices = [State.IDLE, State.WANDER, State.FORAGE, State.REST, State.ALERT, State.LOOK_AROUND]
	var weights = [18.0, 35.0, 8.0 + hunger * 0.55, 5.0 + (100 - energy) * 0.6, maxf(0, alertness - 40), 22.0]
	var total = 0.0
	for weight in weights:
		total += weight
	var value = rng.randf_range(0, total)
	for index in range(choices.size()):
		value -= weights[index]
		if value <= 0:
			set_state(choices[index])
			return

func move_towards_target(delta: float) -> void:
	var remaining = global_position.distance_to(target)
	if remaining <= arrival_distance:
		arrived = true
		if is_special():
			intent_reached.emit(state_name())
		return
	var next_position = target
	var map = agent.get_navigation_map()
	if navigation_available(map):
		if not agent.is_navigation_finished():
			next_position = agent.get_next_path_position()
		else:
			# If the navigation projection finished outside the goal, abandon safely.
			set_state(State.IDLE)
			return
	var direction = next_position - global_position
	# Baked terrain can contain slopes; only non-nav fallback is planar.
	if not navigation_available(map):
		direction.y = 0
	if direction.length_squared() < 0.0001:
		return
	var travel = minf(move_speed * delta, direction.length())
	global_position += direction.normalized() * travel
	distance_walked_in_intent += travel
	var yaw = atan2(-direction.x, -direction.z)
	$Visual.rotation.y = lerp_angle($Visual.rotation.y, yaw, minf(1, delta * turn_speed))

func navigation_available(map: RID) -> bool:
	if not use_navigation or not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return false
	# An empty/unbaked map can still have a nonzero synchronization revision.
	return NavigationServer3D.map_get_closest_point_owner(map, global_position).is_valid()
