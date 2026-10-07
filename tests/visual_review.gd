extends Node
func _ready() -> void:
	capture.call_deferred()
func capture() -> void:
	var args = OS.get_cmdline_user_args()
	var stage = args[0] if not args.is_empty() else "Home"
	var target = "Game" if stage == "Herd" else stage
	var scene = load("res://scenes/" + target + ".tscn").instantiate()
	add_child(scene)
	if stage == "Herd":
		scene.get_node("CanvasLayer/HerdViewer").open()
	for i in range(8):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image = get_viewport().get_texture().get_image()
	image.save_png("/tmp/hwa_" + stage.to_lower() + ".png")
	get_tree().quit()
