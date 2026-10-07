extends Node
var failures: Array[String] = []
var checks = 0
var game: Node3D
var triggered: Array[String] = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame

func _ready() -> void:
	if OS.get_environment("HWA_TEST") != "1":
		push_error("Set HWA_TEST=1; normal player saves must be preserved.")
		get_tree().quit(2)
		return
	run.call_deferred()

func run() -> void:
	GameManager.reset_save()
	check(FileAccess.file_exists(SaveManager.save_path), "first launch creates JSON save")
	var home = load("res://scenes/Home.tscn").instantiate()
	add_child(home)
	check(home.cards.get_child_count() == 4, "home contains four animal cards")
	for id in ["otter", "hog_badger", "marten"]:
		home.select_animal(id)
		check(home.notice.text == "该动物档案将在未来开放。", "locked archive: " + id)
	home.queue_free()
	await frames(2)
	game = load("res://scenes/Game.tscn").instantiate()
	add_child(game)
	await frames(10)
	var deer = game.get_node("MainDeer")
	var observer = game.get_node("ObservationRig")
	var events = game.get_node("EventManager")
	var viewer = game.get_node("CanvasLayer/PostcardViewer")
	var collection = game.get_node("CanvasLayer/PostcardCollection")
	check(NavigationServer3D.map_get_iteration_id(deer.agent.get_navigation_map()) > 0, "navigation map synchronized")
	check(deer.get_node("Visual").get_child_count() > 0, "missing model gives visible geometry")
	check(not GameManager.record_event("NEW_COMPANION"), "out-of-order events are refused")
	# Approaching the deer as the observer must never trigger first meeting.
	observer.position = Vector3(0, 2.8, 1)
	deer.set_state(AnimalAgent.State.IDLE)
	await frames(120)
	check(not GameManager.completed("FIRST_MEETING"), "player approaching deer does not unlock first meeting")
	check(deer.alertness > 35, "close observer increases alertness")
	observer.position = Vector3(0, 2.8, 13)
	# Observe the weighted FSM. Deterministic seed is only a test fixture.
	deer.rng.seed = 771
	var seen: Dictionary = {}
	for i in range(60):
		deer.choose_behavior()
		seen[deer.state_name()] = true
	check(seen.size() >= 4, "weighted FSM chooses varied behaviors")
	deer.position = Vector3.ZERO
	deer.alertness = 0
	deer.curiosity = 100
	deer.set_state(AnimalAgent.State.IDLE)
	events.first_meeting_min_time = 0.1
	events.exploration_delay = 0.1
	events.companion_delay = 0.1
	events.decision_chance_per_second = 100.0
	deer.move_speed = 4.0
	game.get_node("CompanionDeer").move_speed = 4.0
	events.event_triggered.connect(func(id): triggered.append(id))
	var waited = 0
	while triggered.size() < 3 and waited < 6000:
		await frames(1)
		waited += 1
		if viewer.visible:
			check(get_tree().paused, "postcard pauses world: " + viewer.current_id)
			var before: Vector3 = deer.position
			var before_elapsed: float = events.elapsed
			await frames(20)
			check(deer.position == before and events.elapsed == before_elapsed, "AI and events stay paused during postcard")
			check(viewer.image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "postcard preserves original aspect")
			viewer.close()
			check(not get_tree().paused, "continue resumes world")
	check(triggered == ["FIRST_MEETING", "FIRST_EXPLORATION", "NEW_COMPANION"], "three real movement events in order")
	check(game.get_node("CompanionDeer").visible, "companion appears in third chapter")
	check(GameManager.collected_count() == 3, "three postcards recorded")
	check(SaveManager.data.documentary_unlocked, "documentary unlocks after all three cards")
	check(not GameManager.record_event("FIRST_MEETING"), "event cannot unlock twice")
	SaveManager.data = SaveManager.defaults()
	SaveManager.load_save()
	check(GameManager.collected_count() == 3, "progress survives JSON reload")
	collection.open()
	check(collection.slots.get_child_count() == 3, "collection displays three slots")
	viewer.show_postcard("FIRST_MEETING")
	viewer.close()
	check(get_tree().paused and collection.visible, "closing enlarged card retains collection pause")
	collection.close()
	check(not get_tree().paused, "closing collection resumes simulation")
	game.queue_free()
	await frames(3)
	game = load("res://scenes/Game.tscn").instantiate()
	add_child(game)
	await frames(120)
	check(not game.get_node("CanvasLayer/PostcardViewer").visible, "completed events do not reappear on re-entry")
	var doc = load("res://scenes/DocumentaryPlayer.tscn").instantiate()
	add_child(doc)
	check(doc.status.text.contains("资源未找到"), "missing video gives helpful message")
	doc.finish()
	check(doc.status.text == "生命仍在继续。", "documentary ending text")
	doc.queue_free()
	await frames(3)
	var real_doc = load("res://scenes/DocumentaryPlayer.tscn").instantiate()
	real_doc.video_path = "res://tests/fixtures/playback.ogv"
	add_child(real_doc)
	check(real_doc.player.stream != null and real_doc.player.is_playing(), "local Theora video starts playback")
	var video_wait = 0
	while real_doc.status.text != "生命仍在继续。" and video_wait < 360:
		await frames(1)
		video_wait += 1
	check(real_doc.status.text == "生命仍在继续。", "real local video reaches finished signal")
	real_doc.queue_free()
	# Actual navigation fallback is exercised by removing the mesh.
	game.get_node("NavigationRegion3D").navigation_mesh = null
	await frames(10)
	deer = game.get_node("MainDeer")
	var original: Vector3 = deer.position
	deer.request_intent(AnimalAgent.State.GO_TO_EXPLORE_AREA, original + Vector3(3, 0, 0))
	await frames(120)
	check(deer.position.distance_to(original) > 1.0, "unbaked navigation uses bounded movement fallback")
	# Verify camera movement using actual input actions.
	observer = game.get_node("ObservationRig")
	var camera_start: Vector3 = observer.position
	Input.action_press("move_right")
	await frames(60)
	Input.action_release("move_right")
	check(observer.position.x > camera_start.x, "WASD input moves observation rig")
	check(observer.speed <= observer.max_slow_speed + 0.01, "slow observation mode limits speed")
	GameManager.reset_save()
	check(GameManager.collected_count() == 0 and not SaveManager.data.documentary_unlocked, "reset clears events, postcards and film")
	check(checks >= 30, "nonempty meaningful test coverage")
	print("RESULT: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
