extends Control
var start_button: Button
var logo: TextureRect
func _ready() -> void:
	theme = ArchiveUI.theme()
	ArchiveUI.full(self)
	var backdrop = ColorRect.new()
	backdrop.name = "ForestBackdrop"
	var material = ShaderMaterial.new()
	material.shader = load("res://shaders/start_forest.gdshader")
	backdrop.material = material
	add_child(backdrop)
	ArchiveUI.full(backdrop)
	var layout = VBoxContainer.new()
	layout.name = "StartLayout"
	ArchiveUI.margin(self, 60).add_child(layout)
	var eyebrow = ArchiveUI.label("HIDDEN WILDLIFE ARCHIVE   /   生命档案计划", 19, ArchiveUI.GOLD)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(eyebrow)
	var center = CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(center)
	var image = AssetCatalog.resource("game_logo") as Texture2D
	# Also accept the simple English slot or a logo placed at the asset root.
	if image == null:
		for path in ["res://assets/ui/game_logo.png", "res://assets/游戏标题.png"]:
			if ResourceLoader.exists(path):
				image = load(path) as Texture2D
				break
	if image:
		logo = ArchiveUI.image(image, Vector2(970, 560))
		logo.name = "GameLogo"
		center.add_child(logo)
	else:
		var words = VBoxContainer.new()
		center.add_child(words)
		var title = ArchiveUI.label("隐秘生命档案", 82)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.add_child(title)
		var subtitle = ArchiveUI.label("Hidden Wildlife Archive", 30, ArchiveUI.GOLD)
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.add_child(subtitle)
	var tagline = ArchiveUI.label("林间万物，自有故事。
在这里，静静见证生命。", 26, ArchiveUI.PAPER)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(tagline)
	var buttons = CenterContainer.new()
	layout.add_child(buttons)
	var row = HBoxContainer.new()
	buttons.add_child(row)
	start_button = ArchiveUI.button("开启生命档案   →", func(): GameManager.go_to("Home"))
	start_button.custom_minimum_size = Vector2(330, 70)
	row.add_child(start_button)
	row.add_child(ArchiveUI.button("退出", func(): get_tree().quit()))
	var footer = ArchiveUI.label("一片森林 · 各自生活 · 偶然相遇", 18, ArchiveUI.MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(footer)
