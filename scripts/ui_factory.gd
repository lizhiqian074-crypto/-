class_name ArchiveUI
extends RefCounted
const INK = Color("#10241f")
const PAPER = Color("#ebe6d6")
const MUTED = Color("#9baea0")
const GOLD = Color("#c7b985")

static func box(color: Color, border: Color = Color.TRANSPARENT, radius: int = 12) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style

static func theme() -> Theme:
	var result = Theme.new()
	var font_path = "res://assets/fonts/ArchiveSans.otf"
	if ResourceLoader.exists(font_path):
		result.default_font = load(font_path)
	result.default_font_size = 23
	result.set_color("font_color", "Label", PAPER)
	result.set_color("font_color", "Button", PAPER)
	result.set_color("font_disabled_color", "Button", MUTED)
	result.set_stylebox("normal", "Button", box(Color("#22372d"), Color("#56705a")))
	result.set_stylebox("hover", "Button", box(Color("#344b3c"), GOLD))
	result.set_stylebox("pressed", "Button", box(Color("#46583f"), GOLD))
	result.set_stylebox("disabled", "Button", box(Color("#182c24"), Color("#32483b")))
	result.set_stylebox("focus", "Button", box(Color(0,0,0,0), GOLD))
	result.set_constant("separation", "VBoxContainer", 20)
	result.set_constant("separation", "HBoxContainer", 24)
	return result

static func full(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func label(text: String, size: int = 23, color: Color = PAPER) -> Label:
	var node = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	return node

static func button(text: String, action: Callable) -> Button:
	var node = Button.new()
	node.text = text
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.pressed.connect(action)
	return node

static func image(texture: Texture2D, size: Vector2) -> TextureRect:
	var node = TextureRect.new()
	node.texture = texture
	node.custom_minimum_size = size
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func margin(parent: Control, amount: int = 64) -> MarginContainer:
	var node = MarginContainer.new()
	node.name = "LayoutMargin"
	parent.add_child(node)
	full(node)
	for side in ["left", "top", "right", "bottom"]:
		node.add_theme_constant_override("margin_" + side, amount)
	return node

static func shade(parent: Control, color: Color = Color(0, 0, 0, 0.76)) -> ColorRect:
	var node = ColorRect.new()
	node.name = "Dimmer"
	node.color = color
	parent.add_child(node)
	full(node)
	return node
