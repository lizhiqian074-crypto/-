extends Node
var count = 0
var failures = 0
func check(ok: bool, message: String) -> void:
	count += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)
func frames(n: int) -> void:
	for i in range(n): await get_tree().physics_frame
func _ready() -> void: run.call_deferred()
func run() -> void:
	if OS.get_environment("HWA_TEST") != "1":
		get_tree().quit(2)
		return
	GameManager.reset_save()
	AssetCatalog.config.forest_model = "res://tests/fixtures/CollisionForest.tscn"
	var game = load("res://scenes/Game.tscn").instantiate()
	add_child(game)
	game.get_node("EventManager").set_physics_process(false)
	game.get_node("HerdManager").set_physics_process(false)
	var deer: AnimalAgent = game.get_node("MainDeer")
	var player: CharacterBody3D = game.get_node("ObservationRig")
	player.position = Vector3(15,8,15)
	await frames(10)
	player.position = Vector3(15,8,15)
	for animal in game.get_node("HerdManager").animals:
		animal.exploration_chance = 0
		animal.set_state(AnimalAgent.State.REST)
		animal.state_remaining = 10000
		animal.mind.calm_affinity_gain = 0
	check(deer is CharacterBody3D and player is CharacterBody3D,"deer and observer use physical bodies")
	check(game.get_node("EnvironmentRoot").find_children("TerrainCollision","StaticBody3D",true,false).size() == 3,"imported meshes automatically receive terrain collision")
	check(TerrainPhysics.add_mesh_collisions(game.get_node("EnvironmentRoot")) == 0,"collider generation is idempotent")
	var standalone = MeshInstance3D.new()
	standalone.mesh = BoxMesh.new()
	standalone.position = Vector3(20,3,20)
	game.add_child(standalone)
	check(TerrainPhysics.add_mesh_collisions(standalone) == 1,"standalone forest mesh resource also receives collision")
	standalone.queue_free()
	var prebuilt = MeshInstance3D.new()
	prebuilt.mesh = BoxMesh.new()
	prebuilt.position = Vector3(20,3,20)
	var existing = StaticBody3D.new()
	existing.collision_layer = 8
	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	existing.add_child(shape)
	prebuilt.add_child(existing)
	game.add_child(prebuilt)
	check(TerrainPhysics.add_mesh_collisions(prebuilt) == 0 and (existing.collision_layer & 1) != 0,"existing imported collider is reused and enabled on terrain layer")
	prebuilt.queue_free()
	check(game.get_node("CompanionDeer/BodyCollision").disabled,"hidden deer does not leave an invisible obstacle")
	var nav: NavigationMesh = game.get_node("NavigationRegion3D").navigation_mesh
	var elevated = false
	for point in nav.vertices:
		if point.y > 1.0: elevated = true
	check(elevated and nav.get_polygon_count() > 1,"navigation bakes real ramp and obstacles rather than a flat square")
	deer.position = Vector3(0,3,0)
	deer.velocity = Vector3.ZERO
	await frames(120)
	check(deer.is_on_floor() and absf(deer.position.y) < 0.06,"idle deer falls to the ground and stays on its surface")
	# No navigation still uses physical collision; fallback must never pass through walls.
	deer.use_navigation = false
	deer.request_intent(AnimalAgent.State.GO_TO_EXPLORE_AREA,Vector3(0,0,-8))
	await frames(300)
	check(deer.position.z > -3.45 and deer.position.z < -2.5,"deer stops at wall in fallback movement")
	var walked = deer.total_distance_walked
	await frames(120)
	check(absf(deer.total_distance_walked-walked) < 0.01,"blocked requested travel is not counted as actual exploration")
	deer.use_navigation = true
	deer.request_intent(AnimalAgent.State.GO_TO_EXPLORE_AREA,Vector3(0,0,-8))
	var reached = false
	for i in range(1800):
		await frames(1)
		if deer.position.z < -7.3:
			reached = true
			break
	check(reached,"baked navigation routes deer around wall to reachable destination")
	deer.position = Vector3(9,0.6,8)
	deer.velocity = Vector3.ZERO
	deer.use_navigation = false
	deer.request_intent(AnimalAgent.State.GO_TO_EXPLORE_AREA,Vector3(9,2.5,0))
	await frames(420)
	check(deer.position.y > 1.8 and deer.is_on_floor(),"deer climbs walkable slope without entering terrain")
	deer.set_state(AnimalAgent.State.REST)
	deer.state_remaining = 10000
	player.position = Vector3(0,2.8,0)
	Input.action_press("move_forward")
	await frames(150)
	Input.action_release("move_forward")
	check(player.position.z > -3.45,"player cannot cross wall")
	player.position = Vector3(0,2.8,0)
	Input.action_press("move_down")
	await frames(120)
	Input.action_release("move_down")
	check(player.position.y >= 1.49 and player.position.y < 1.6,"Q descent stops the player capsule at the terrain surface")
	player.position = Vector3(0,5,0)
	Input.action_press("move_down")
	await frames(5)
	Input.action_release("move_down")
	check(player.position.y < 5,"collision preserves free observation height controls")
	deer.position = Vector3.ZERO
	deer.set_physics_process(false)
	player.position = Vector3(0,1.8,4)
	Input.action_press("move_forward")
	await frames(150)
	Input.action_release("move_forward")
	check(player.position.z > 0.6,"player cannot walk through deer body")
	var other: AnimalAgent = game.get_node("MossDeer")
	other.position = Vector3(0,0,4)
	other.use_navigation = false
	other.observer = null
	other.request_intent(AnimalAgent.State.GO_TO_EXPLORE_AREA,Vector3(0,0,-3))
	player.position = Vector3(15,8,15)
	await frames(300)
	check(other.position.z > 0.6,"deer cannot walk through another deer")
	game.queue_free()
	await frames(3)
	GameManager.reset_save()
	print("RESULT: %d collision checks, %d failures" % [count,failures])
	get_tree().quit(0 if failures == 0 else 1)
