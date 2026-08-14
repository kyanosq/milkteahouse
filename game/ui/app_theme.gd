## 全局 UI 主题：珊瑚薄荷色板（design/mockups/coral_mint）
## Coral=主按钮/当前选择，Mint=次级/成功，Cream=面板，Cocoa=文字
extends RefCounted

const CORAL := Color("FF6259")
const MINT := Color("27B9A7")
const CREAM := Color("FFF8ED")
const COCOA := Color("30201D")


static func build() -> Theme:
	var t := Theme.new()

	# 全局字体：霞鹜文楷（OFL 开源）；运行时文件由 assets_src/fonts 管线确定性子集化。
	var font: FontFile = load("res://assets/fonts/LXGWWenKai-Regular.ttf")
	if font:
		t.default_font = font
		t.default_font_size = 19

	# 按钮：珊瑚圆角（主操作）
	var btn := StyleBoxFlat.new()
	btn.bg_color = CORAL
	btn.set_corner_radius_all(12)
	btn.content_margin_left = 14
	btn.content_margin_right = 14
	btn.content_margin_top = 8
	btn.content_margin_bottom = 8
	var btn_h: StyleBoxFlat = btn.duplicate()
	btn_h.bg_color = Color("FF7B72")
	var btn_p: StyleBoxFlat = btn.duplicate()
	btn_p.bg_color = Color("E04A42")
	var btn_d: StyleBoxFlat = btn.duplicate()
	btn_d.bg_color = Color(0.72, 0.68, 0.64, 0.6)
	var btn_f: StyleBoxFlat = btn.duplicate()
	btn_f.bg_color = Color("FF756C")
	btn_f.set_border_width_all(4)
	# Cocoa against coral remains clearly visible on small screens and under
	# bright handheld lighting; the old mint-on-coral ring was only 1.2:1.
	btn_f.border_color = COCOA
	btn_f.shadow_size = 8
	btn_f.shadow_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.72)
	t.set_stylebox("normal", "Button", btn)
	t.set_stylebox("hover", "Button", btn_h)
	t.set_stylebox("pressed", "Button", btn_p)
	t.set_stylebox("disabled", "Button", btn_d)
	t.set_stylebox("focus", "Button", btn_f)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(state, "Button", COCOA)
	t.set_color("font_disabled_color", "Button", Color(COCOA.r, COCOA.g, COCOA.b, 0.48))

	# 面板：奶油卡片 + 软阴影
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.97)
	panel.set_corner_radius_all(14)
	panel.shadow_size = 6
	panel.shadow_color = Color(0.19, 0.13, 0.11, 0.22)
	panel.content_margin_left = 12
	panel.content_margin_right = 12
	panel.content_margin_top = 10
	panel.content_margin_bottom = 10
	t.set_stylebox("panel", "PanelContainer", panel)

	# 进度条（薄荷=正向反馈）
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.19, 0.13, 0.11, 0.25)
	pb_bg.set_corner_radius_all(6)
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = MINT
	pb_fill.set_corner_radius_all(6)
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill", "ProgressBar", pb_fill)

	# 输入框
	var le := StyleBoxFlat.new()
	le.bg_color = Color(1, 1, 1, 0.9)
	le.set_corner_radius_all(8)
	le.content_margin_left = 10
	le.content_margin_right = 10
	t.set_stylebox("normal", "LineEdit", le)
	t.set_color("font_color", "LineEdit", COCOA)

	# 文字：可可色
	t.set_color("font_color", "Label", COCOA)
	return t
