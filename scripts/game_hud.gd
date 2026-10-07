extends Control
signal collection_requested
var postcard_button: Button
var documentary_button: Button
var debug_label: Label
var notice: Label
var animal: AnimalAgent
var events: Node
var pause_panel: Control
var herd: Node
var herd_viewer: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = ArchiveUI.theme()
	ArchiveUI.full(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin = ArchiveUI.margin(self, 44)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	var top = HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	var title = ArchiveUI.label("隐秘生命档案
毛冠鹿   /   观察进行中", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	postcard_button = ArchiveUI.button("", func(): collection_requested.emit())
	top.add_child(ArchiveUI.button("林间生命",func(): herd_viewer.open()))
	top.add_child(postcard_button)
	debug_label = ArchiveUI.label("", 18, ArchiveUI.GOLD)
	column.add_child(debug_label)
	var spacer = Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	notice = ArchiveUI.label("", 21, ArchiveUI.GOLD)
	column.add_child(notice)
	var bottom = HBoxContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(bottom)
	var hint = ArchiveUI.label("WASD / Q E 移动   ·   右键环顾   ·   ESC 暂停", 18, ArchiveUI.PAPER)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(hint)
	documentary_button = ArchiveUI.button("", func(): GameManager.go_to("DocumentaryGenerator"))
	bottom.add_child(ArchiveUI.button("照料栖地",help_habitat))
	bottom.add_child(documentary_button)
	bottom.add_child(ArchiveUI.button("返回档案库", func(): GameManager.go_to("Home")))
	GameManager.progress_changed.connect(refresh)
	GameManager.documentary_unlocked.connect(func(): notice.text = "这段生命档案已经完整。")
	SaveManager.save_failed.connect(func(message): notice.text = message)
	refresh()
	build_pause()

func refresh() -> void:
	postcard_button.text = "生命明信片  %d/3" % GameManager.collected_count()
	documentary_button.disabled = not GameManager.can_generate_documentary()
	documentary_button.text = "查看生命纪录片" if SaveManager.data.documentary_generated else "生成生命纪录片"

func _process(_delta: float) -> void:
	debug_label.visible = is_instance_valid(events) and events.debug_mode
	if debug_label.visible and is_instance_valid(animal):
		debug_label.text = "DEBUG  %s  |  饥饿 %.0f  能量 %.0f  警觉 %.0f  好奇 %.0f
F1 见面准备 · F2 探索 · F3 伙伴 · F4 清空存档" % [animal.state_name(), animal.hunger, animal.energy, animal.alertness, animal.curiosity]

func help_habitat() -> void:
	if is_instance_valid(herd) and herd.help_habitat():
		notice.text = "林下食源得到了照料，生命会作出自己的选择。"
	else:
		notice.text = "让这片栖地休息片刻。"

func build_pause() -> void:
	pause_panel = Control.new()
	add_child(pause_panel)
	ArchiveUI.full(pause_panel)
	ArchiveUI.shade(pause_panel)
	var center = CenterContainer.new()
	pause_panel.add_child(center)
	ArchiveUI.full(center)
	var column = VBoxContainer.new()
	center.add_child(column)
	column.add_child(ArchiveUI.label("片刻停留", 42))
	column.add_child(ArchiveUI.button("继续观察", resume))
	column.add_child(ArchiveUI.button("返回档案库", func(): GameManager.go_to("Home")))
	pause_panel.hide()

func resume() -> void:
	pause_panel.hide()
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if pause_panel.visible:
			resume()
		elif not get_tree().paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().paused = true
			pause_panel.show()
		get_viewport().set_input_as_handled()
