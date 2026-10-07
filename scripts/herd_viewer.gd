extends Control
var herd: Node
var list: VBoxContainer
var owns_pause = false
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = ArchiveUI.theme()
	ArchiveUI.full(self)
	ArchiveUI.shade(self, Color(0.03,0.07,0.05,0.96))
	var column = VBoxContainer.new()
	ArchiveUI.margin(self,70).add_child(column)
	column.add_child(ArchiveUI.label("林间生命",42))
	column.add_child(ArchiveUI.label("每一次停留，都在改变彼此的关系。",22,ArchiveUI.MUTED))
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	column.add_child(ArchiveUI.button("继续观察",close))
	hide()
func open() -> void:
	owns_pause = not get_tree().paused
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	for animal in herd.animals:
		if not animal.visible: continue
		var panel = PanelContainer.new()
		panel.add_theme_stylebox_override("panel",ArchiveUI.box(Color("#1c3025")))
		list.add_child(panel)
		var content = VBoxContainer.new()
		panel.add_child(content)
		content.add_child(ArchiveUI.label(animal.display_name + "  /  " + animal.mind.personality_text(),29))
		content.add_child(ArchiveUI.label("此刻：" + animal.mind.mood + "    对你：" + animal.mind.attitude() + "    好感 %.0f / 100" % animal.mind.player_affinity,22))
		var relationships: Array[String] = []
		for other in herd.animals:
			if other == animal or not other.visible: continue
			var value = animal.mind.affinity_to(other.animal_id)
			relationships.append(other.display_name + "：" + ("亲近" if value >= 65 else "熟悉" if value >= 45 else "初识" if value >= 25 else "疏远") + "（%.0f）" % value)
		content.add_child(ArchiveUI.label("同伴关系  ·  " + "    ".join(relationships),19,ArchiveUI.MUTED))
		var recollection = "仍在认识这片森林。"
		if not animal.mind.memories.is_empty():
			var latest: Dictionary = animal.mind.memories.back()
			var phrases = {"startled":"记得你曾靠近或突然移动，暂时更谨慎。", "calm_observation":"记得你安静地陪伴过。", "habitat_help":"记得林下食源得到照料。", "friendly_contact":"记得与同伴安静相处。", "new_companion":"记得第一次认识新的伙伴。", "crowded":"记得同伴曾靠得过近。"}
			recollection = phrases.get(latest.kind,"仍在认识这片森林。")
		content.add_child(ArchiveUI.label(recollection,19,ArchiveUI.GOLD))
	show()
func close() -> void:
	hide()
	if owns_pause: get_tree().paused = false
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
