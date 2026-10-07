extends Node
## Versioned local JSON. Writes are atomic, and no credentials/network are used.
signal save_failed(message: String)
signal collecting_save
var reset_epoch = 0
const EVENTS = ["FIRST_MEETING", "FIRST_EXPLORATION", "NEW_COMPANION"]
const PREFIXES = ["first_meeting", "first_exploration", "new_companion"]
var save_path = "user://hidden_wildlife_save.json"
var data: Dictionary = {}

func _ready() -> void:
	# The test runner never touches the player's actual save.
	if OS.get_environment("HWA_TEST") == "1":
		save_path = "user://hidden_wildlife_test.json"
	load_save()

func defaults() -> Dictionary:
	var result = {"version": 3, "documentary_unlocked": false, "documentary_generated": false, "animals": {}, "world_seconds": 0.0, "habitat": {}, "visited_explore_areas": [], "pending_postcards": []}
	for prefix in PREFIXES:
		result[prefix + "_completed"] = false
		result[prefix + "_postcard_unlocked"] = false
	return result

func load_save() -> void:
	data = defaults()
	if not FileAccess.file_exists(save_path):
		save_data()
		return
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		save_failed.emit("无法读取存档；本次使用空白进度。")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		# Preserve damaged data for inspection; never silently discard it.
		DirAccess.copy_absolute(save_path, save_path + ".damaged")
		push_warning("存档损坏，已保留 .damaged 副本。")
		return
	# Events are independent. Preserve friends/exploration even without a meeting.
	var all_completed = true
	for prefix in PREFIXES:
		var completed = parsed.get(prefix + "_completed", false) == true
		data[prefix + "_completed"] = completed
		data[prefix + "_postcard_unlocked"] = completed
		all_completed = all_completed and completed
	data.documentary_unlocked = all_completed
	if parsed.get("visited_explore_areas") is Array:
		for area in parsed.visited_explore_areas:
			if area is String and not data.visited_explore_areas.has(area): data.visited_explore_areas.append(area)
	if parsed.get("pending_postcards") is Array:
		for id in parsed.pending_postcards:
			if id in EVENTS and not data.pending_postcards.has(id): data.pending_postcards.append(id)
	data.documentary_generated = parsed.get("documentary_generated", false) == true
	if parsed.get("animals") is Dictionary:
		data.animals = parsed.animals.duplicate(true)
	if parsed.get("habitat") is Dictionary:
		data.habitat = parsed.habitat.duplicate(true)
	var time = parsed.get("world_seconds",0)
	if (time is float or time is int) and is_finite(float(time)):
		data.world_seconds = maxf(0,float(time))

func save_data() -> bool:
	collecting_save.emit()
	var file = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		save_failed.emit("存档写入失败，请检查用户目录权限。")
		return false
	file.store_string(JSON.stringify(data, "	"))
	file.close()
	var error = DirAccess.rename_absolute(save_path + ".tmp", save_path)
	if error != OK:
		save_failed.emit("存档替换失败：" + error_string(error))
	return error == OK

func reset_save() -> void:
	reset_epoch += 1
	data = defaults()
	save_data()
