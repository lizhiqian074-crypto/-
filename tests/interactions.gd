extends Node
var count = 0
var failures = 0
func check(ok: bool, message: String) -> void:
	count += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)
func frames(number: int) -> void:
	for i in range(number):
		await get_tree().physics_frame
func key(code: Key) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	if OS.get_environment("HWA_TEST") != "1":
		get_tree().quit(2)
		return
	# Keep this test harness separate from the current scene during real transitions.
	get_tree().current_scene = null
	GameManager.reset_save()
	InputSetup.install()
	GameManager.go_to("Start")
	await frames(4)
	var start = get_tree().current_scene
	check(start.name == "Start", "project opens on forest start page")
	start.start_button.pressed.emit()
	await frames(4)
	var home = get_tree().current_scene
	home.select_animal("otter")
	await frames(2)
	check(get_tree().current_scene == home, "locked animal click keeps home scene")
	home.enter_button.pressed.emit()
	await frames(4)
	var game = get_tree().current_scene
	check(game.name == "Game", "enter button performs actual Home → Game transition")
	var deer = game.get_node("MainDeer")
	var rig = game.get_node("ObservationRig")
	var events = game.get_node("EventManager")
	var hud = game.get_node("CanvasLayer/GameHUD")
	var viewer = game.get_node("CanvasLayer/PostcardViewer")
	var collection = game.get_node("CanvasLayer/PostcardCollection")
	await key(KEY_ESCAPE)
	check(get_tree().paused and hud.pause_panel.visible, "ESC opens pause menu")
	var before: Vector3 = rig.position
	Input.action_press("move_right")
	await frames(20)
	Input.action_release("move_right")
	check(rig.position == before, "paused camera ignores movement")
	await key(KEY_ESCAPE)
	check(not get_tree().paused and not hud.pause_panel.visible, "ESC resumes observation")
	var mouse = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_RIGHT
	mouse.position = get_viewport().get_visible_rect().size / 2
	mouse.pressed = true
	Input.parse_input_event(mouse)
	await frames(2)
	if DisplayServer.get_name() == "headless":
		print("SKIP: pointer capture requires graphical display")
	else:
		check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "right button captures observation view")
	var motion = InputEventMouseMotion.new()
	motion.relative = Vector2(30, 20)
	var old_yaw: float = rig.rotation.y
	Input.parse_input_event(motion)
	await frames(2)
	if DisplayServer.get_name() == "headless":
		print("SKIP: captured-pointer rotation requires graphical display")
	else:
		check(rig.rotation.y != old_yaw, "mouse movement rotates observation rig")
	mouse = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_RIGHT
	mouse.pressed = false
	Input.parse_input_event(mouse)
	await frames(2)
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "right button release frees pointer")
	mouse = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_WHEEL_UP
	mouse.position = get_viewport().get_visible_rect().size / 2
	mouse.pressed = true
	Input.parse_input_event(mouse)
	await frames(2)
	check(rig.speed_multiplier > 1, "mouse wheel adjusts movement multiplier")
	await key(KEY_F1)
	check(deer.state != AnimalAgent.State.APPROACH_PLAYER, "debug F1 has no effect when debug mode is off")
	events.debug_mode = true
	await key(KEY_F1)
	check(deer.state == AnimalAgent.State.APPROACH_PLAYER, "debug F1 prepares active deer approach")
	# Subsequent physical debug keys must respect narrative prerequisites.
	GameManager.record_event("FIRST_MEETING")
	await key(KEY_F2)
	check(deer.state == AnimalAgent.State.GO_TO_EXPLORE_AREA, "debug F2 prepares exploration")
	GameManager.record_event("FIRST_EXPLORATION")
	await key(KEY_F3)
	check(game.get_node("CompanionDeer").visible and deer.state == AnimalAgent.State.APPROACH_COMPANION, "debug F3 spawns companion")
	viewer.show_postcard("FIRST_MEETING")
	await key(KEY_ESCAPE)
	check(not viewer.visible and not get_tree().paused, "ESC closes postcard and resumes")
	collection.open()
	await key(KEY_ESCAPE)
	check(not collection.visible and not get_tree().paused, "ESC closes collection and resumes")
	GameManager.record_event("NEW_COMPANION")
	hud.documentary_button.pressed.emit()
	await frames(4)
	var generator = get_tree().current_scene
	check(generator.name == "DocumentaryGenerator", "HUD opens local documentary generator")
	generator.generate_button.pressed.emit()
	await frames(2)
	check(not generator.view_button.disabled, "generate button enables supplied video")
	generator.view_button.pressed.emit()
	await frames(4)
	var doc = get_tree().current_scene
	check(doc.name == "DocumentaryPlayer", "watch button opens documentary scene")
	doc.return_button.pressed.emit()
	await frames(4)
	game = get_tree().current_scene
	check(game.name == "Game" and GameManager.collected_count() == 3, "documentary return reloads observation with progress")
	game.get_node("EventManager").debug_mode = true
	await key(KEY_F4)
	await frames(4)
	check(GameManager.collected_count() == 0 and get_tree().current_scene.name == "Game", "debug F4 clears save and reloads forest")
	GameManager.go_to("Home")
	await frames(4)
	check(get_tree().current_scene.name == "Home" and not get_tree().paused, "return to archive unpauses world")
	print("RESULT: %d interaction checks, %d failures" % [count, failures])
	get_tree().quit(1 if failures > 0 else 0)
