extends Control
signal postcard_selected(id: String)
var slots: HBoxContainer
var owns_pause = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = ArchiveUI.theme()
	ArchiveUI.full(self)
	ArchiveUI.shade(self, Color(0.025, 0.065, 0.045, 0.95))
	var column = VBoxContainer.new()
	ArchiveUI.margin(self, 90).add_child(column)
	column.add_child(ArchiveUI.label("生命明信片", 42))
	column.add_child(ArchiveUI.label("安静收藏，那些偶然与生命相遇的片刻。", 23, ArchiveUI.MUTED))
	slots = HBoxContainer.new()
	slots.name = "PostcardSlots"
	slots.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(slots)
	column.add_child(ArchiveUI.button("返回观察", close))
	hide()

func open() -> void:
	owns_pause = not get_tree().paused
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for child in slots.get_children():
		slots.remove_child(child)
		child.queue_free()
	for index in range(3):
		var id: String = GameManager.EVENT_IDS[index]
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", ArchiveUI.box(Color("#20372a")))
		slots.add_child(panel)
		var column = VBoxContainer.new()
		panel.add_child(column)
		var unlocked = GameManager.completed(id)
		if unlocked and AssetCatalog.texture("postcards", id):
			column.add_child(ArchiveUI.image(AssetCatalog.texture("postcards", id), Vector2(100, 160)))
		else:
			var placeholder = ArchiveUI.label("图片待导入" if unlocked else "尚未记录", 26, ArchiveUI.MUTED)
			placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
			placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			column.add_child(placeholder)
		column.add_child(ArchiveUI.label(GameManager.TITLES[index], 27))
		var view = ArchiveUI.button("查看原图" if unlocked else "尚未记录", func(): postcard_selected.emit(id))
		view.disabled = not unlocked
		column.add_child(view)
	show()

func close() -> void:
	hide()
	if owns_pause:
		get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
