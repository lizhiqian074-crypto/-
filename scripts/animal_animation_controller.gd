class_name AnimalAnimationController
extends Node
@export var idle_animation_name = "Idle"
@export var walk_animation_name = "Walk"
@export var eat_animation_name = "Eat"
@export var rest_animation_name = "Rest"
@export var alert_animation_name = "Alert"
var player: AnimationPlayer

func bind_model(model: Node3D) -> void:
	var found = model.find_children("*", "AnimationPlayer", true, false)
	if not found.is_empty():
		player = found[0] as AnimationPlayer

func play_state(state: String) -> void:
	if not is_instance_valid(player):
		return
	var desired = idle_animation_name
	if state in ["WANDER", "APPROACH_PLAYER", "GO_TO_EXPLORE_AREA", "APPROACH_COMPANION"]:
		desired = walk_animation_name
	elif state == "FORAGE":
		desired = eat_animation_name
	elif state == "REST":
		desired = rest_animation_name
	elif state == "ALERT":
		desired = alert_animation_name
	var matched = find_animation(desired)
	if matched.is_empty():
		matched = find_animation(idle_animation_name)
	if not matched.is_empty() and player.current_animation != matched:
		var animation = player.get_animation(matched)
		animation.loop_mode = Animation.LOOP_LINEAR
		player.play(matched, 0.25)

func find_animation(desired: String) -> String:
	for animation in player.get_animation_list():
		if animation.to_lower() == desired.to_lower() or animation.get_file().to_lower() == desired.to_lower():
			return animation
	return ""
