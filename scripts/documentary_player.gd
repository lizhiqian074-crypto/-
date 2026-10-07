extends Control
@export_file("*.ogv") var video_path = ""
var player: VideoStreamPlayer
var status: Label
var return_button: Button

func _ready() -> void:
	theme = ArchiveUI.theme()
	ArchiveUI.full(self)
	ArchiveUI.shade(self, Color("#080e0b"))
	var column = VBoxContainer.new()
	ArchiveUI.margin(self, 60).add_child(column)
	column.add_child(ArchiveUI.label("毛冠鹿生命档案", 42))
	column.add_child(ArchiveUI.label("HIDDEN WILDLIFE ARCHIVE   /   DOCUMENTARY", 18, ArchiveUI.GOLD))
	player = VideoStreamPlayer.new()
	player.name = "VideoStreamPlayer"
	player.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player.expand = true
	player.finished.connect(finish)
	# VideoStreamPlayer expands to its container: explicit aspect ratio is required.
	var aspect = AspectRatioContainer.new()
	aspect.name = "VideoAspect"
	aspect.ratio = 16.0 / 9.0
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(aspect)
	aspect.add_child(player)
	status = ArchiveUI.label("", 25, ArchiveUI.MUTED)
	status.name = "Status"
	column.add_child(status)
	var row = HBoxContainer.new()
	column.add_child(row)
	return_button = ArchiveUI.button("返回观察", func(): GameManager.go_to("Game"))
	row.add_child(return_button)
	row.add_child(ArchiveUI.button("返回档案库", func(): GameManager.go_to("Home")))
	row.add_child(ArchiveUI.button("重新播放", replay))
	if not SaveManager.data.documentary_generated:
		status.text = "这段生命档案仍在整理中。"
		return
	var path = video_path if not video_path.is_empty() else AssetCatalog.path_for("documentary")
	if ResourceLoader.exists(path):
		player.stream = load(path) as VideoStream
	if player.stream == null:
		status.text = "纪录片资源未找到。请导入本地 OGV 视频。"
	else:
		status.text = "生命的片刻，正在展开。"
		player.play()

func finish() -> void:
	status.text = "生命仍在继续。"

func replay() -> void:
	if player.stream != null and SaveManager.data.documentary_generated:
		player.play()
		status.text = "生命的片刻，正在展开。"
