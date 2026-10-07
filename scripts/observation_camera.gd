extends CharacterBody3D
@export var slow_observation_mode = true
@export var move_speed = 3.0
@export var max_slow_speed = 4.0
@export var mouse_sensitivity = 0.0025
@export var bounds_half_extent = 24.0
var speed_multiplier = 1.0
var pitch = -0.14
var speed = 0.0
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 7
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var shape = CollisionShape3D.new()
	shape.name = "PlayerCollision"
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = -0.65
	add_child(shape)
	InputSetup.install()
	camera.rotation.x = pitch

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_rotate"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_released("camera_rotate") or event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -1.1, 1.1)
		camera.rotation.x = pitch
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			speed_multiplier = clampf(speed_multiplier * 1.15, 0.35, 2.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			speed_multiplier = clampf(speed_multiplier / 1.15, 0.35, 2.0)

func _physics_process(delta: float) -> void:
	var axes = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = global_basis * Vector3(axes.x, 0, axes.y)
	direction.y += Input.get_axis("move_down", "move_up")
	var actual_speed = move_speed * speed_multiplier
	if slow_observation_mode:
		actual_speed = minf(actual_speed, max_slow_speed)
	var motion = direction.limit_length() * actual_speed * delta
	var destination = global_position + motion
	destination.x = clampf(destination.x,-bounds_half_extent,bounds_half_extent)
	destination.z = clampf(destination.z,-bounds_half_extent,bounds_half_extent)
	destination.y = minf(destination.y,float(AssetCatalog.config.get("ground_height",0)) + 12.0)
	velocity = (destination-global_position) / maxf(delta,0.0001)
	var before = global_position
	move_and_slide()
	speed = global_position.distance_to(before) / maxf(delta,0.0001)
