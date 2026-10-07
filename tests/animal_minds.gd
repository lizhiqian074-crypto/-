extends Node
var failures = 0
var count = 0
func check(ok: bool, message: String) -> void:
	count += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)
func frames(number: int) -> void:
	for i in range(number): await get_tree().physics_frame
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	if OS.get_environment("HWA_TEST") != "1":
		get_tree().quit(2)
		return
	GameManager.reset_save()
	var game = load("res://scenes/Game.tscn").instantiate()
	add_child(game)
	await frames(8)
	var herd = game.get_node("HerdManager")
	var rig = game.get_node("ObservationRig")
	var main = game.get_node("MainDeer")
	var moss = game.get_node("MossDeer")
	var amber = game.get_node("AmberDeer")
	var cloud = game.get_node("CloudDeer")
	var visible_count = 0
	var ids: Dictionary = {}
	for animal in herd.animals:
		ids[animal.animal_id] = true
		if animal.visible: visible_count += 1
	check(visible_count == 4 and ids.size() == 5, "four starting deer and unique persistent IDs plus narrative companion")
	check(main.mind != moss.mind and main.agent != moss.agent, "each deer owns its mind and navigation agent")
	check(main.mind.personality.curiosity == 0.8 and moss.mind.personality.courage == 0.2 and amber.mind.personality.sociability == 0.85, "distinct personalities from named profiles")
	var start_positions: Array[Vector3] = []
	for animal in [main,moss,amber,cloud]: start_positions.append(animal.position)
	game.get_node("EventManager").set_physics_process(false)
	for animal in herd.animals: animal.exploration_chance = 0
	await frames(2400)
	var changed = 0
	for i in range(4):
		if [main,moss,amber,cloud][i].position.distance_to(start_positions[i]) > 0.5: changed += 1
	check(changed >= 3, "multiple deer autonomously move without player commands")
	check(main.mind.player_affinity > 40, "quiet observation increases player affinity")
	check(main.mind.counters.calm_seconds > 20, "quiet observation leaves cumulative personal history")
	var has_calm = false
	for memory in main.mind.memories:
		if memory.kind == "calm_observation": has_calm = true
	check(has_calm, "calm observation creates bounded personal memories")
	# Pause event scheduling while constructing behavioral scenarios, not the animal AI.
	game.get_node("EventManager").set_physics_process(false)
	if game.get_node("CanvasLayer/PostcardViewer").visible: game.get_node("CanvasLayer/PostcardViewer").close()
	main.position = Vector3.ZERO
	main.set_state(AnimalAgent.State.IDLE)
	rig.position = Vector3(0,2.8,7)
	await frames(3)
	var trust_before: float = main.mind.player_affinity
	Input.action_press("move_right")
	await frames(6)
	Input.action_release("move_right")
	await frames(3)
	check(main.mind.counters.disturbances >= 1 and main.mind.player_affinity < trust_before, "nearby sudden real player movement reduces trust")
	check(main.mind.fear_memory_active(), "disturbance remembered for future ecological days")
	check(main.mind.avoidance_radius() > 5.0, "fear memory increases future avoidance distance")
	main.position = Vector3.ZERO
	main.set_state(AnimalAgent.State.IDLE)
	rig.position = Vector3(0,2.8,6)
	await frames(5)
	check(main.state == AnimalAgent.State.FLEE, "remembered observer causes early flight beyond normal close distance")
	check(not GameManager.completed("FIRST_MEETING"), "a startled deer does not award first meeting")
	# A remembered fear differs per animal and does not automatically infect all minds.
	check(moss.mind != main.mind and moss.mind.memories != main.mind.memories, "personal memories are not one shared herd list")
	rig.position = Vector3(0,2.8,23)
	main.position = Vector3(-2,0,-2)
	moss.position = Vector3(0,0,-2)
	main.set_state(AnimalAgent.State.REST)
	moss.set_state(AnimalAgent.State.REST)
	main.state_remaining = 100
	moss.state_remaining = 100
	main.mind.fear = 0
	main.mind.relations[moss.animal_id] = 35.0
	moss.mind.relations[main.animal_id] = 35.0
	var relation_a: float = main.mind.affinity_to(moss.animal_id)
	var relation_b: float = moss.mind.affinity_to(main.animal_id)
	await frames(120)
	check(main.mind.affinity_to(moss.animal_id) > relation_a and moss.mind.affinity_to(main.animal_id) > relation_b, "same-species peaceful contact changes both directional affinities")
	var contains_social = false
	for memory in main.mind.memories:
		if memory.kind == "friendly_contact": contains_social = true
	check(contains_social, "social history records actual close contact")
	amber.position = Vector3(14,0,14)
	amber.set_state(AnimalAgent.State.REST)
	amber.state_remaining = 100
	check(herd.help_habitat(), "player can improve habitat without issuing deer orders")
	check(not herd.help_habitat(), "habitat help cooldown prevents repeated instant boosts")
	var prior_help: float = main.mind.counters.help_received
	main.position = game.get_node("ForagePatch").position
	main.set_state(AnimalAgent.State.FORAGE)
	main.state_remaining = 100
	await frames(20)
	check(main.mind.counters.help_received == prior_help + 1, "foraging deer remembers benefiting from player habitat help")
	var affinity_after_help: float = main.mind.player_affinity
	await frames(20)
	check(main.mind.counters.help_received == prior_help + 1 and main.mind.player_affinity == affinity_after_help, "same habitat help is not counted every frame")
	check(amber.mind.counters.help_received == 0, "deer that did not benefit receives no invented help memory")
	SaveManager.save_data()
	var saved_trust: float = main.mind.player_affinity
	var saved_relation: float = main.mind.affinity_to(moss.animal_id)
	var memory_count: int = main.mind.memories.size()
	game.queue_free()
	await frames(3)
	SaveManager.load_save()
	game = load("res://scenes/Game.tscn").instantiate()
	add_child(game)
	main = game.get_node("MainDeer")
	check(absf(main.mind.player_affinity - saved_trust) < 0.001, "trust restored after reloading JSON and rebuilding world")
	check(absf(main.mind.affinity_to("moss") - saved_relation) < 0.001, "relationships restored by stable identity")
	check(main.mind.memories.size() == memory_count and main.mind.fear_memory_active(), "memories and future avoidance survive restart")
	check(main.mind.counters.help_received == 1, "help history survives restart")
	var viewer = game.get_node("CanvasLayer/HerdViewer")
	viewer.open()
	check(viewer.visible and get_tree().paused and viewer.list.get_child_count() == 4, "life archive shows current personalities and relations and pauses world")
	viewer.close()
	check(not get_tree().paused, "life archive close resumes simulation")
	# Documentary access is available before any postcards, per the user's preference.
	check(GameManager.collected_count() == 0 and GameManager.can_generate_documentary(), "demo permits documentary generation before postcards")
	check(DocumentaryArchive.generate(), "actual supplied movie supports local archive generation")
	check(FileAccess.file_exists(DocumentaryArchive.archive_path) and SaveManager.data.documentary_generated, "generation writes a persistent local documentary archive")
	var archive = JSON.parse_string(FileAccess.get_file_as_string(DocumentaryArchive.archive_path))
	check(archive.video_source == "user_provided_prerendered_video" and archive.recorded_moments.is_empty(), "archive accurately states video origin and actual observed progress")
	var old_access = AssetCatalog.config.documentary_demo_access
	AssetCatalog.config.documentary_demo_access = false
	check(not GameManager.can_generate_documentary(), "optional full-archive mode still gates generation")
	AssetCatalog.config.documentary_demo_access = old_access
	var doc = load("res://scenes/DocumentaryPlayer.tscn").instantiate()
	add_child(doc)
	check(doc.player.stream != null and doc.player.is_playing(), "supplied 14-second Theora documentary starts playback")
	# The supplied movie has audio; its finished signal is tested in real time by SuppliedVideo.tscn.
	doc.queue_free()
	GameManager.reset_save()
	game.queue_free()
	await frames(3)
	SaveManager.load_save()
	check(SaveManager.data.animals.is_empty() and SaveManager.data.world_seconds == 0 and not SaveManager.data.documentary_generated, "reset prevents old world exit from restoring deleted memories")
	check(not FileAccess.file_exists(DocumentaryArchive.archive_path), "reset also removes generated local archive")
	var old_logo = AssetCatalog.config.game_logo
	# Test the image slot with a local fixture; do not ship a replacement logo.
	AssetCatalog.config.game_logo = "res://assets/ui/documentary_poster.png"
	var start = load("res://scenes/Start.tscn").instantiate()
	add_child(start)
	check(start.logo != null and start.logo.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "start page loads supplied logo slot without cropping or stretching")
	AssetCatalog.config.game_logo = old_logo
	start.queue_free()
	# Migrate a genuine v1 fixture, rather than assuming new save reload covers migration.
	var legacy = {"version":1, "first_meeting_completed":true, "first_meeting_postcard_unlocked":true,
		"first_exploration_completed":false, "new_companion_completed":false,"documentary_unlocked":false}
	var file = FileAccess.open(SaveManager.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	SaveManager.load_save()
	check(GameManager.completed("FIRST_MEETING") and not GameManager.completed("FIRST_EXPLORATION"), "v1 migration preserves actual postcard progress")
	check(SaveManager.data.version == 3 and SaveManager.data.animals.is_empty() and not SaveManager.data.documentary_generated, "v1 migration initializes new fields safely")
	GameManager.reset_save()
	print("RESULT: %d animal-memory/documentary checks, %d failures" % [count, failures])
	get_tree().quit(0 if failures == 0 else 1)
