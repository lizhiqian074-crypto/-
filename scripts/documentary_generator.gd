extends Control
var generate_button: Button
var view_button: Button
var status: Label
var summary: Label
func _ready() -> void:
	theme = ArchiveUI.theme()
	ArchiveUI.full(self)
	ArchiveUI.shade(self,Color("#0c1c15"))
	var column = VBoxContainer.new()
	ArchiveUI.margin(self,70).add_child(column)
	column.add_child(ArchiveUI.label("生成生命纪录片",46))
	column.add_child(ArchiveUI.label("从你见证的片刻，整理一份生命档案。",24,ArchiveUI.GOLD))
	var center = CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(center)
	var row = HBoxContainer.new()
	center.add_child(row)
	var poster = AssetCatalog.resource("documentary_poster") as Texture2D
	if poster: row.add_child(ArchiveUI.image(poster,Vector2(760,420)))
	var words = VBoxContainer.new()
	words.custom_minimum_size.x = 580
	row.add_child(words)
	words.add_child(ArchiveUI.label("毛冠鹿 · 林间的独立生命",31))
	summary = ArchiveUI.label("",22)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(summary)
	words.add_child(ArchiveUI.label("影片使用你提供的预制纪录片。
本地档案记录本次观察的片段与关系。",20,ArchiveUI.MUTED))
	status = ArchiveUI.label("",24,ArchiveUI.GOLD)
	column.add_child(status)
	var buttons = HBoxContainer.new()
	column.add_child(buttons)
	generate_button = ArchiveUI.button("生成生命纪录片",generate)
	buttons.add_child(generate_button)
	view_button = ArchiveUI.button("观看纪录片",func(): GameManager.go_to("DocumentaryPlayer"))
	buttons.add_child(view_button)
	buttons.add_child(ArchiveUI.button("返回观察",func(): GameManager.go_to("Game")))
	buttons.add_child(ArchiveUI.button("返回档案库",func(): GameManager.go_to("Home")))
	refresh()
func refresh() -> void:
	var names: Array[String] = []
	for id in SaveManager.data.animals:
		if SaveManager.data.animals[id].get("observed",false):
			names.append(str(SaveManager.data.animals[id].get("name",id)))
	summary.text = "已见证生命片段：%d / 3
林间生命：%s

%s" % [GameManager.collected_count(), "、".join(names) if not names.is_empty() else "等待初次观察", "演示模式：可以随时整理纪录片。" if AssetCatalog.config.get("documentary_demo_access",true) else "集齐三张明信片后可整理完整档案。"]
	view_button.disabled = not SaveManager.data.documentary_generated
	generate_button.disabled = not GameManager.can_generate_documentary()
	generate_button.text = "重新整理生命档案" if SaveManager.data.documentary_generated else "生成生命纪录片"
	status.text = "纪录片已准备好。" if SaveManager.data.documentary_generated else "等待你开启这份档案。"
func generate() -> void:
	if DocumentaryArchive.generate():
		refresh()
		status.text = "生命档案已生成，点击观看纪录片。"
	else:
		status.text = DocumentaryArchive.last_error
