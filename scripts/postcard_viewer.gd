extends Control
signal closed
var image: TextureRect
var missing: Label
var current_id = ""
var owns_pause = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = ArchiveUI.theme()
	ArchiveUI.full(self)
	ArchiveUI.shade(self)
	var column = VBoxContainer.new()
	column.name = "PostcardLayout"
	ArchiveUI.margin(self, 90).add_child(column)
	image = ArchiveUI.image(null, Vector2(200, 200))
	image.name = "PostcardImage"
	column.add_child(image)
	missing = ArchiveUI.label("", 28)
	missing.name = "MissingResource"
	missing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	missing.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(missing)
	var row = CenterContainer.new()
	column.add_child(row)
	row.add_child(ArchiveUI.button("继续观察", close))
	hide()

func show_postcard(id: String) -> void:
	current_id = id
	owns_pause = not get_tree().paused
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	image.texture = AssetCatalog.texture("postcards", id)
	image.visible = image.texture != null
	missing.visible = image.texture == null
	var index = GameManager.EVENT_IDS.find(id)
	missing.text = "「%s」
明信片资源尚未导入。" % GameManager.TITLES[index]
	show()
	# Original image only. No overlays, cropping, decorations or animations.

func close() -> void:
	hide()
	if owns_pause:
		get_tree().paused = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
