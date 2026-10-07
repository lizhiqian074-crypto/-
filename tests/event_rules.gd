extends Node
var game: Node3D
var count = 0
var failures = 0
func check(ok: bool,text: String) -> void:
	count += 1
	if ok: print("PASS: " + text)
	else:
		failures += 1
		push_error("FAIL: " + text)
func frames(number: int) -> void:
	for i in range(number): await get_tree().physics_frame
func fresh() -> void:
	get_tree().paused = false
	if is_instance_valid(game):
		game.queue_free()
		await frames(3)
	GameManager.reset_save()
	game = load("res://scenes/Game.tscn").instantiate()
	add_child(game)
	# Freeze affinity changes in threshold fixtures; movement and event AI stay live.
	game.get_node("HerdManager").set_physics_process(false)
	for animal in game.get_node("HerdManager").animals:
		animal.exploration_chance = 0
		animal.move_speed = 3
		animal.mind.calm_affinity_gain = 0
		animal.set_state(AnimalAgent.State.IDLE)
		animal.state_remaining = 1000
	await frames(8)
func wait_for(id: String,limit: int = 1000) -> void:
	var waited = 0
	while not GameManager.completed(id) and waited < limit:
		await frames(1)
		waited += 1
	await frames(2)
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	if OS.get_environment("HWA_TEST") != "1":
		get_tree().quit(2)
		return
	await fresh()
	var events = game.get_node("EventManager")
	var moss = game.get_node("MossDeer")
	moss.mind.player_affinity = 99
	await frames(60)
	check(not GameManager.completed("FIRST_MEETING") and moss.state != AnimalAgent.State.APPROACH_PLAYER,"99 affinity is insufficient for meeting")
	var approach_start: Vector3 = moss.position
	moss.mind.player_affinity = 100
	await frames(2)
	check(moss.state == AnimalAgent.State.APPROACH_PLAYER,"a non-main deer at 100 starts its own approach")
	check(not GameManager.completed("FIRST_MEETING"),"reaching 100 alone does not award card before movement")
	await wait_for("FIRST_MEETING")
	check(GameManager.completed("FIRST_MEETING") and moss.position.distance_to(approach_start) >= 1.0,"real non-main deer arrival records meeting")
	check(game.get_node("CanvasLayer/PostcardViewer").current_id == "FIRST_MEETING" and get_tree().paused,"meeting directly shows its postcard and pauses")
	check(not GameManager.record_event("FIRST_MEETING"),"meeting card cannot record twice")
	game.get_node("CanvasLayer/PostcardViewer").close()
	await fresh()
	events = game.get_node("EventManager")
	moss = game.get_node("MossDeer")
	var amber = game.get_node("AmberDeer")
	moss.position = Vector3(-2,0,-6)
	amber.position = Vector3(2,0,-6)
	moss.mind.relations[amber.animal_id] = 100
	amber.mind.relations[moss.animal_id] = 99
	await frames(60)
	check(not GameManager.completed("NEW_COMPANION") and not is_instance_valid(events.friend_a),"one-sided 100 is insufficient for friendship")
	amber.mind.relations[moss.animal_id] = 100
	await frames(2)
	check(moss.state == AnimalAgent.State.APPROACH_COMPANION and amber.state == AnimalAgent.State.APPROACH_COMPANION,"two non-main deer at mutual 100 approach each other")
	var waited = 0
	while moss.state != AnimalAgent.State.PLAY_TOGETHER and waited < 500:
		await frames(1)
		waited += 1
	check(moss.state == AnimalAgent.State.PLAY_TOGETHER and amber.state == AnimalAgent.State.PLAY_TOGETHER,"full-affinity pair actually enters play state")
	check(not GameManager.completed("NEW_COMPANION"),"pair must play before friendship postcard")
	await wait_for("NEW_COMPANION")
	check(GameManager.completed("NEW_COMPANION") and events.play_distance >= 0.8,"actual pair movement while playing records friendship")
	check(not GameManager.completed("FIRST_MEETING") and not GameManager.completed("FIRST_EXPLORATION"),"friendship works independently before meeting and exploration")
	check(GameManager.TITLES[2] == "新的朋友","friendship UI uses requested title")
	game.get_node("CanvasLayer/PostcardViewer").close()
	await fresh()
	var cloud = game.get_node("CloudDeer")
	var area = game.get_node("ExploreArea_A")
	var old_area: Vector3 = area.position
	area.position = cloud.position + Vector3(1,0,0)
	cloud.set_state(AnimalAgent.State.WANDER,area.position)
	await frames(100)
	check(not GameManager.completed("FIRST_EXPLORATION"),"nearby area is not a distant exploration")
	area.position = old_area
	cloud.set_state(AnimalAgent.State.WANDER,area.position)
	await wait_for("FIRST_EXPLORATION")
	check(GameManager.completed("FIRST_EXPLORATION") and cloud.total_distance_walked > 8,"any deer wandering into a distant new area records exploration")
	check(not GameManager.completed("FIRST_MEETING") and not GameManager.completed("NEW_COMPANION"),"exploration works independently before other cards")
	check(SaveManager.data.visited_explore_areas.has("ExploreArea_A"),"new area visit is persisted")
	check(GameManager.TITLES[1] == "第一次探索","exploration UI uses requested title")
	game.get_node("CanvasLayer/PostcardViewer").close()
	SaveManager.save_data()
	game.queue_free()
	await frames(3)
	SaveManager.load_save()
	check(GameManager.completed("FIRST_EXPLORATION") and not GameManager.completed("FIRST_MEETING"),"independent exploration survives reload without being discarded")
	await fresh()
	events = game.get_node("EventManager")
	events.record_occurrence("NEW_COMPANION")
	events.record_occurrence("FIRST_EXPLORATION")
	check(SaveManager.data.pending_postcards.size() == 2,"same-frame event cards are queued separately")
	await frames(2)
	var viewer = game.get_node("CanvasLayer/PostcardViewer")
	check(viewer.visible and viewer.current_id == "NEW_COMPANION" and SaveManager.data.pending_postcards.size() == 1,"first queued card displayed without overwriting")
	SaveManager.load_save()
	check(SaveManager.data.pending_postcards == ["FIRST_EXPLORATION"],"undisplayed card queue survives save reload")
	viewer.close()
	await frames(2)
	check(viewer.visible and viewer.current_id == "FIRST_EXPLORATION","second queued card shown only after continuing")
	viewer.close()
	GameManager.record_event("FIRST_MEETING")
	check(GameManager.collected_count() == 3 and SaveManager.data.documentary_unlocked,"all three cards unlock full archive in any order")
	await fresh()
	var herd = game.get_node("HerdManager")
	for animal in herd.animals: animal.mind.calm_affinity_gain = 3.0
	herd.set_physics_process(true)
	await frames(1200)
	check(game.get_node("MainDeer").mind.player_affinity >= 100,"normal quiet observation reaches 100 at faster default rate")
	GameManager.reset_save()
	game.queue_free()
	await frames(3)
	print("RESULT: %d independent-event checks, %d failures" % [count,failures])
	get_tree().quit(0 if failures == 0 else 1)
