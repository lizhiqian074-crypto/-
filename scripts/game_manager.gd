extends Node
signal progress_changed
signal documentary_unlocked
var current_animal = "tufted_deer"
const EVENT_IDS = ["FIRST_MEETING", "FIRST_EXPLORATION", "NEW_COMPANION"]
const TITLES = ["第一次见面", "第一次探索", "新的朋友"]

func completed(id: String) -> bool:
	var index = EVENT_IDS.find(id)
	return index >= 0 and SaveManager.data.get(SaveManager.PREFIXES[index] + "_completed", false)

func collected_count() -> int:
	var count = 0
	for id in EVENT_IDS:
		if completed(id):
			count += 1
	return count

func record_event(id: String, queue_postcard: bool = false) -> bool:
	var index = EVENT_IDS.find(id)
	if index < 0 or completed(id):
		return false
	var prefix = SaveManager.PREFIXES[index]
	SaveManager.data[prefix + "_completed"] = true
	SaveManager.data[prefix + "_postcard_unlocked"] = true
	if queue_postcard and not SaveManager.data.pending_postcards.has(id):
		SaveManager.data.pending_postcards.append(id)
	var was_unlocked: bool = SaveManager.data.documentary_unlocked
	SaveManager.data.documentary_unlocked = collected_count() == 3
	SaveManager.save_data()
	progress_changed.emit()
	if SaveManager.data.documentary_unlocked and not was_unlocked:
		documentary_unlocked.emit()
	return true

func can_generate_documentary() -> bool:
	return bool(AssetCatalog.config.get("documentary_demo_access", true)) or bool(SaveManager.data.documentary_unlocked)

func go_to(scene_name: String) -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/" + scene_name + ".tscn")

func reset_save() -> void:
	SaveManager.reset_save()
	DocumentaryArchive.reset_archive()
	progress_changed.emit()
