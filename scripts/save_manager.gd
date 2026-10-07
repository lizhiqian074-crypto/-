extends Node
## Versioned local JSON. Writes are atomic, and no credentials/network are used.
signal save_failed(message: String)
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
	var result = {"version": 1, "documentary_unlocked": false}
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
	# Only accept booleans, enforce ordered narrative and derive film unlock.
	var previous = true
	for prefix in PREFIXES:
		var completed = parsed.get(prefix + "_completed", false) == true and previous
		data[prefix + "_completed"] = completed
		data[prefix + "_postcard_unlocked"] = completed
		previous = completed
	data.documentary_unlocked = previous

func save_data() -> bool:
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
	data = defaults()
	save_data()
