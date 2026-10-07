extends Control
const ANIMALS = [
	["tufted_deer", "毛冠鹿", "Elaphodus cephalophus", "森林里的小隐士", "01"],
	["otter", "欧亚水獭", "Lutra lutra", "溪流间的自在旅人", "02"],
	["hog_badger", "猪獾", "Arctonyx collaris", "林下大地的探索者", "03"],
	["marten", "松貂", "Martes martes", "树影深处的轻盈来客", "04"]]
var details: Label
var enter_button: Button
var selected_animal = "tufted_deer"
var notice: Label
var cards: HBoxContainer

func _ready() -> void:
	theme = ArchiveUI.theme()
	ArchiveUI.full(self)
	ArchiveUI.shade(self, ArchiveUI.INK)
	var columns = VBoxContainer.new()
	columns.name = "ArchiveLayout"
	ArchiveUI.margin(self).add_child(columns)
	var top = HBoxContainer.new()
	columns.add_child(top)
	var eyebrow = ArchiveUI.label("H W A   /   自 然 生 命 档 案 库", 19, ArchiveUI.GOLD)
	eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(eyebrow)
	top.add_child(ArchiveUI.label("FIELD ARCHIVE     •     VOL. 01", 18, ArchiveUI.MUTED))
	columns.add_child(ArchiveUI.label("隐秘生命档案", 62))
	columns.add_child(ArchiveUI.label("Hidden Wildlife Archive", 27, ArchiveUI.GOLD))
	columns.add_child(ArchiveUI.label("观察那些未被记录的生命。", 24, ArchiveUI.MUTED))
	cards = HBoxContainer.new()
	cards.name = "AnimalCards"
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(cards)
	for animal in ANIMALS:
		add_card(animal)
	var panel = PanelContainer.new()
	panel.name = "AnimalDetails"
	panel.add_theme_stylebox_override("panel", ArchiveUI.box(Color("#1b3027"), Color("#455840")))
	columns.add_child(panel)
	var row = HBoxContainer.new()
	panel.add_child(row)
	details = ArchiveUI.label("毛冠鹿 · 森林里的小隐士
它独自行走、觅食、休息。你只需安静地停留，见证它的生活。", 23)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	enter_button = ArchiveUI.button("进入观察   →", enter_observation)
	enter_button.custom_minimum_size.x = 210
	row.add_child(enter_button)
	notice = ArchiveUI.label("离线生态观察   /   无需操控动物   /   生命仍在继续", 19, ArchiveUI.MUTED)
	columns.add_child(notice)

func add_card(animal: Array) -> void:
	var card = PanelContainer.new()
	card.name = animal[0]
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", ArchiveUI.box(Color("#1c3228"), Color("#47634c")))
	cards.add_child(card)
	var content = VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(content)
	content.add_child(ArchiveUI.label(animal[4] + "   /   SPECIES", 17, ArchiveUI.GOLD))
	var portrait = AssetCatalog.texture("portraits", animal[0])
	if portrait:
		content.add_child(ArchiveUI.image(portrait, Vector2(120, 170)))
	else:
		var placeholder = ArchiveUI.label("◇
头像尚未导入", 25, ArchiveUI.MUTED)
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		placeholder.custom_minimum_size.y = 160
		content.add_child(placeholder)
	content.add_child(ArchiveUI.label(animal[1], 33))
	content.add_child(ArchiveUI.label(animal[2], 16, ArchiveUI.MUTED))
	content.add_child(ArchiveUI.label(animal[3], 21))
	var open = animal[0] == "tufted_deer"
	content.add_child(ArchiveUI.button("档案可观察   ↗" if open else "档案尚未开放", select_animal.bind(animal[0])))
	card.mouse_entered.connect(func(): card.add_theme_stylebox_override("panel", ArchiveUI.box(Color("#263e30"), ArchiveUI.GOLD)))
	card.mouse_exited.connect(func(): card.add_theme_stylebox_override("panel", ArchiveUI.box(Color("#1c3228"), Color("#47634c"))))
	card.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			select_animal(animal[0]))

func select_animal(id: String) -> void:
	if id != "tufted_deer":
		notice.text = "该动物档案将在未来开放。"
		return
	selected_animal = id
	details.text = "毛冠鹿 · 森林里的小隐士
它独自行走、觅食、休息。你只需安静地停留，见证它的生活。"
	notice.text = "已记录生命片段：%d / 3" % GameManager.collected_count()

func enter_observation() -> void:
	GameManager.current_animal = selected_animal
	GameManager.go_to("Game")
