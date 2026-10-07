extends Node
## A real local archive is generated; the movie is the user's PREMADE video.
## No fake AI generation, network requests or altered video content.
signal documentary_ready
var last_error = ""
var archive_path = "user://hidden_wildlife_documentary.json"
func _ready() -> void:
	if OS.get_environment("HWA_TEST") == "1":
		archive_path = "user://hidden_wildlife_documentary_test.json"
func reset_archive() -> void:
	if FileAccess.file_exists(archive_path):
		DirAccess.remove_absolute(archive_path)
func generate() -> bool:
	last_error = ""
	if not GameManager.can_generate_documentary():
		last_error = "生命片段仍在整理中。"
		return false
	var video_path = AssetCatalog.path_for("documentary")
	if not ResourceLoader.exists(video_path) or not load(video_path) is VideoStream:
		last_error = "纪录片资源未找到，请检查本地 OGV 视频。"
		return false
	SaveManager.collecting_save.emit()
	var events: Array[String] = []
	for index in range(3):
		if GameManager.completed(GameManager.EVENT_IDS[index]): events.append(GameManager.TITLES[index])
	var archive = {"title":"毛冠鹿生命档案", "generated_at":Time.get_datetime_string_from_system(),
		"recorded_moments":events,"animals":SaveManager.data.animals.duplicate(true),
		"world_seconds":SaveManager.data.world_seconds,"video_path":video_path,
		"video_source":"user_provided_prerendered_video", "format_version":1}
	var file = FileAccess.open(archive_path + ".tmp",FileAccess.WRITE)
	if file == null:
		last_error = "无法保存生命档案，请检查用户目录权限。"
		return false
	file.store_string(JSON.stringify(archive,"	"))
	file.close()
	var error = DirAccess.rename_absolute(archive_path + ".tmp",archive_path)
	if error != OK:
		last_error = "生命档案保存失败：" + error_string(error)
		return false
	var was_generated: bool = SaveManager.data.documentary_generated
	SaveManager.data.documentary_generated = true
	if not SaveManager.save_data():
		SaveManager.data.documentary_generated = was_generated
		last_error = "纪录片进度保存失败。"
		return false
	GameManager.progress_changed.emit()
	documentary_ready.emit()
	return true
