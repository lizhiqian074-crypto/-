extends Node
var started_at = 0
var doc: Control
func _ready() -> void:
	if OS.get_environment("HWA_TEST") != "1":
		get_tree().quit(2)
		return
	GameManager.reset_save()
	if not DocumentaryArchive.generate():
		push_error("FAIL: cannot generate supplied movie archive")
		get_tree().quit(1)
		return
	print("PASS: supplied movie archive generated")
	doc = load("res://scenes/DocumentaryPlayer.tscn").instantiate()
	add_child(doc)
	if doc.player.stream == null or not doc.player.is_playing():
		push_error("FAIL: supplied movie did not start")
		get_tree().quit(1)
		return
	print("PASS: supplied movie started with original audio stream")
	started_at = Time.get_ticks_msec()
func _process(_delta: float) -> void:
	if doc == null: return
	if doc.status.text == "生命仍在继续。":
		print("PASS: supplied movie finished in %.2f wall-clock seconds" % [(Time.get_ticks_msec() - started_at) / 1000.0])
		print("RESULT: 3 real-time supplied-video checks, 0 failures")
		get_tree().quit()
	elif Time.get_ticks_msec() - started_at > 25000:
		push_error("FAIL: supplied video timeout, position %.2f" % doc.player.stream_position)
		get_tree().quit(1)
