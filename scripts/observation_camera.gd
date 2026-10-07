extends Node3D
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
	position += motion
	position.x = clampf(position.x, -bounds_half_extent, bounds_half_extent)
	position.z = clampf(position.z, -bounds_half_extent, bounds_half_extent)
	var floor_height = float(AssetCatalog.config.get("ground_height", 0.0))
	position.y = clampf(position.y, floor_height + 1.2, floor_height + 12.0)
	speed = motion.length() / maxf(delta, 0.0001)
