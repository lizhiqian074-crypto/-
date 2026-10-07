extends Node
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	if OS.get_environment("HWA_TEST") != "1":
		get_tree().quit(2)
		return
	for seed_value in [42, 771, 2026]:
		GameManager.reset_save()
		var game = load("res://scenes/Game.tscn").instantiate()
		add_child(game)
		game.get_node("MainDeer").rng.seed = seed_value
		game.get_node("EventManager").rng.seed = seed_value
		var viewer = game.get_node("CanvasLayer/PostcardViewer")
		var frames = 0
		while GameManager.collected_count() < 3 and frames < 21600:
			await get_tree().physics_frame
			frames += 1
			if viewer.visible:
				viewer.close()
		if GameManager.collected_count() != 3:
			push_error("Natural flow timeout: seed %d, cards %d" % [seed_value, GameManager.collected_count()])
			get_tree().quit(1)
			return
		print("PASS: natural idle-observer flow, seed %d, %.1f simulated seconds" % [seed_value, frames / 60.0])
		game.queue_free()
		await get_tree().physics_frame
		await get_tree().physics_frame
	GameManager.reset_save()
	print("RESULT: 3 default-parameter natural flows passed")
	get_tree().quit()
