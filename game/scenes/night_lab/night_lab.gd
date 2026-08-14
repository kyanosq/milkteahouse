## 夜间研发室 · 珊瑚薄荷版（对齐 design/mockups/coral_mint/02-night-lab.png）
## 顶部四组原料货架（图标瓦片+珊瑚选中描边）/ 中央 3D 杯 / 右侧风味雷达 / 珊瑚大按钮
## 玩法逻辑与 RecipeLab 判定不变（night_check 回归接口保持兼容）
extends Control

const CupViewScene := preload("res://ui/cup_view.gd")
const NightLabBackdropScene := preload("res://ui/night_lab_backdrop.gd")
const AppTheme := preload("res://ui/app_theme.gd")
const FlavorRadarScene := preload("res://ui/flavor_radar.gd")
const UpgradePanelScene := preload("res://ui/upgrade_panel.gd")
const StaffPanelScene := preload("res://ui/staff_panel.gd")
const EndlessContractPanelScene := preload("res://ui/endless_contract_panel.gd")
const RecipeBookPanelScene := preload("res://ui/recipe_book_panel.gd")
const MenuBoardPanelScene := preload("res://ui/menu_board_panel.gd")
const NightSettlementPanelScene := preload("res://ui/night_settlement_panel.gd")
const PausePanelScene := preload("res://ui/pause_panel.gd")
const SafeFrameScene := preload("res://ui/safe_frame.gd")

const ATTEMPT_COST := 2
const INSP_BASE := 8
const ACTIVE_BUDGET_CAP := 16
const DARK_MENU_CAP := 3
const CORAL := Color("FF6259")
const MINT := Color("27B9A7")
const CREAM := Color("FFF8ED")
const INDIGO := Color("25324A")
const PLUM := Color("4B2948")
const GOLD := Color("D99A43")

const FEEDBACK_HIGH := {
	"aroma": "NIGHT_FEEDBACK_HIGH_AROMA",
	"sweet": "NIGHT_FEEDBACK_HIGH_SWEET",
	"rich": "NIGHT_FEEDBACK_HIGH_RICH",
	"fresh": "NIGHT_FEEDBACK_HIGH_FRESH",
	"chew": "NIGHT_FEEDBACK_HIGH_CHEW",
}
const FEEDBACK_LOW := {
	"aroma": "NIGHT_FEEDBACK_LOW_AROMA",
	"sweet": "NIGHT_FEEDBACK_LOW_SWEET",
	"rich": "NIGHT_FEEDBACK_LOW_RICH",
	"fresh": "NIGHT_FEEDBACK_LOW_FRESH",
	"chew": "NIGHT_FEEDBACK_LOW_CHEW",
}

var budget := 0
var pending_quality := 0

var cup_base: Variant = null
var cup_milk: Variant = null
var cup_tops: Array = []
var cup_sugar: Variant = null

var info_label: Label          # 顶部主药丸（第N天·研发室 | 灵感）
var book_label: Button         # 图鉴/暗方/检验中；点击打开完整图鉴
var menu_button: Button        # 次日主推菜单与热度
var result_label: Label        # 试喝反馈文本（night_check 读取）
var result_scroll: ScrollContainer
var radar: Control
var note_card: PanelContainer
var note_box: VBoxContainer
var name_row: HBoxContainer
var name_edit: LineEdit
var try_btn: Button
var cup_view: SubViewportContainer
var overlay: ColorRect
var upgrade_panel: UpgradePanel
var staff_panel: StaffPanel
var staff_button: Button
var contract_panel: EndlessContractPanel
var contract_button: Button
var recipe_book_panel: RecipeBookPanel
var menu_board_panel: MenuBoardPanel
var settings_panel: PausePanel
var selection_label: Label
var selection_title_label: Label
var brief_panel: PanelContainer
var brief_title_label: Label
var brief_body_label: Label
var tomorrow_contract_label: Label
var tomorrow_name_label: Label
var tomorrow_body_label: Label
var _tiles: Dictionary = {}    # sel_key -> {btn, on}
var ui_frame: SafeFrame
var _first_tile: Button
var _result_entries: Array[Dictionary] = []
var _note_state: Dictionary = {}


func _ready() -> void:
	GameState.phase = "night"
	MenuCatalog.ensure_normalized()
	ResearchBriefs.ensure_for_day()
	Sfx.play_music("night")
	InputPrompts.scheme_changed.connect(_on_input_scheme_changed)
	GameLocale.locale_changed.connect(_on_locale_changed)
	if GameState.night_budget_day == GameState.day and GameState.night_budget >= 0:
		budget = GameState.night_budget
	else:
		# 日间赚到的灵感/话题度先进持久库，每晚只装入至多
		# 16 点活跃预算（8 次试作）；没装入的部分不再被清零。
		var settled_buzz := maxi(0, GameState.buzz)
		GameState.buzz_traffic = settled_buzz
		GameState.buzz_traffic_day = GameState.day + 1
		GameState.inspiration = maxi(0, GameState.inspiration) + settled_buzz
		GameState.buzz = 0
		var free_budget := mini(ACTIVE_BUDGET_CAP,
			INSP_BASE + 2 * MenuCatalog.featured_items().size() \
			+ ResearchProgress.night_budget_bonus())
		var loadable := maxi(0, ACTIVE_BUDGET_CAP - free_budget)
		GameState.night_performance_remaining = mini(GameState.inspiration, loadable)
		GameState.inspiration -= GameState.night_performance_remaining
		budget = free_budget + GameState.night_performance_remaining
		_sync_budget()
		GameState.save_game()
	_build_ui()
	_refresh()
	_on_input_scheme_changed(InputPrompts.gamepad_mode)
	if MarketTests.has_settlement():
		_show_market_settlement.call_deferred(MarketTests.current())


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("game_pause"):
		if menu_board_panel != null and menu_board_panel.visible:
			menu_board_panel.hide_panel()
		elif recipe_book_panel != null and recipe_book_panel.visible:
			recipe_book_panel.hide_panel()
		elif contract_panel != null and contract_panel.visible:
			contract_panel.hide_panel()
		elif upgrade_panel != null and upgrade_panel.visible:
			upgrade_panel.hide_panel()
		elif staff_panel != null and staff_panel.visible:
			staff_panel.hide_panel()
		elif overlay != null and overlay.visible:
			return
		else:
			_toggle_settings()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- UI

func _tile_style(selected: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE if selected else Color(CREAM.r, CREAM.g, CREAM.b, 0.95)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(3 if selected else 1)
	sb.border_color = CORAL if selected else Color(0.19, 0.13, 0.11, 0.15)
	return sb


func _build_ui() -> void:
	theme = AppTheme.build()
	var bg: Control = NightLabBackdropScene.new()
	add_child(bg)
	# 轻微统一色罩；独立研发室模型本身已经完成夜间布光。
	var dim := ColorRect.new()
	dim.color = Color(INDIGO.r, INDIGO.g, INDIGO.b, 0.04)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	ui_frame = SafeFrameScene.new()
	add_child(ui_frame)

	# 顶部药丸
	var hud := HBoxContainer.new()
	hud.position = Vector2(14, 10)
	hud.add_theme_constant_override("separation", 10)
	ui_frame.add_child(hud)
	var p1 := PanelContainer.new()
	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 20)
	p1.add_child(info_label)
	hud.add_child(p1)
	var p2 := PanelContainer.new()
	book_label = Button.new()
	book_label.flat = true
	book_label.add_theme_font_size_override("font_size", 18)
	book_label.add_theme_color_override("font_color", AppTheme.COCOA)
	book_label.add_theme_color_override("font_hover_color", CORAL)
	book_label.add_theme_color_override("font_pressed_color", CORAL)
	book_label.add_theme_color_override("font_focus_color", AppTheme.COCOA)
	book_label.tooltip_text = GameLocale.text("RECIPE_BOOK_TITLE")
	book_label.pressed.connect(_open_recipe_book)
	p2.add_child(book_label)
	hud.add_child(p2)
	var p3 := PanelContainer.new()
	menu_button = Button.new()
	menu_button.flat = true
	menu_button.add_theme_font_size_override("font_size", 18)
	menu_button.add_theme_color_override("font_color", AppTheme.COCOA)
	menu_button.add_theme_color_override("font_hover_color", CORAL)
	menu_button.add_theme_color_override("font_pressed_color", CORAL)
	menu_button.add_theme_color_override("font_focus_color", AppTheme.COCOA)
	menu_button.tooltip_text = GameLocale.text("MENU_BOARD_TITLE")
	menu_button.pressed.connect(_open_menu_board)
	p3.add_child(menu_button)
	hud.add_child(p3)

	# 原料货架（四组）
	var shelf := HBoxContainer.new()
	shelf.position = Vector2(24, 62)
	shelf.add_theme_constant_override("separation", 14)
	ui_frame.add_child(shelf)
	_shelf_group(shelf, "茶底", GameData.unlocked(GameData.bases, GameState.day), "base")
	_shelf_group(shelf, "奶基", GameData.unlocked(GameData.milks, GameState.day), "milk")
	_shelf_group(shelf, "小料(≤2)", GameData.unlocked(GameData.toppings, GameState.day), "topping")
	_shelf_group(shelf, "糖度", GameData.sugar_levels, "sugar")
	_fit_shelf(shelf)

	# 明文复述当前配方，不要求玩家仅靠细描边或杯体颜色回忆选择。
	var selection_panel := PanelContainer.new()
	selection_panel.position = Vector2(24, 178)
	selection_panel.custom_minimum_size = Vector2(862, 60)
	var selection_style := StyleBoxFlat.new()
	selection_style.bg_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.96)
	selection_style.set_corner_radius_all(13)
	selection_style.set_border_width_all(2)
	selection_style.border_color = Color(MINT.r, MINT.g, MINT.b, 0.78)
	selection_style.content_margin_left = 16
	selection_style.content_margin_right = 16
	selection_style.content_margin_top = 8
	selection_style.content_margin_bottom = 8
	selection_panel.add_theme_stylebox_override("panel", selection_style)
	ui_frame.add_child(selection_panel)
	var selection_box := VBoxContainer.new()
	selection_box.add_theme_constant_override("separation", 2)
	selection_panel.add_child(selection_box)
	selection_title_label = Label.new()
	selection_title_label.text = GameLocale.text("NIGHT_CURRENT_RECIPE")
	selection_title_label.add_theme_font_size_override("font_size", 14)
	selection_title_label.add_theme_color_override("font_color", MINT)
	selection_box.add_child(selection_title_label)
	selection_label = Label.new()
	selection_label.add_theme_font_size_override("font_size", 17)
	selection_box.add_child(selection_label)

	# 短期研究单：在不遮挡中央杯体的左侧空区，把长期图鉴拆成当晚可执行的一步。
	brief_panel = PanelContainer.new()
	brief_panel.position = Vector2(24, 246)
	brief_panel.custom_minimum_size = Vector2(390, 66)
	ui_frame.add_child(brief_panel)
	var brief_box := VBoxContainer.new()
	brief_box.add_theme_constant_override("separation", 2)
	brief_panel.add_child(brief_box)
	brief_title_label = Label.new()
	brief_title_label.add_theme_font_size_override("font_size", 14)
	brief_box.add_child(brief_title_label)
	brief_body_label = Label.new()
	brief_body_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	brief_body_label.add_theme_font_size_override("font_size", 16)
	brief_box.add_child(brief_body_label)

	# 夜间投资前先告诉玩家明天会发生什么，让升级选择有上下文。
	var tomorrow := DailyEvents.next_event(GameState.day)
	var preview := PanelContainer.new()
	preview.position = Vector2(24, 526)
	preview.custom_minimum_size = Vector2(390, 104)
	var preview_accent := Color(String(tomorrow["color"]))
	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.96)
	preview_style.set_corner_radius_all(14)
	preview_style.set_border_width_all(2)
	preview_style.border_color = Color(preview_accent.r, preview_accent.g, preview_accent.b, 0.72)
	preview_style.content_margin_left = 14
	preview_style.content_margin_right = 14
	preview_style.content_margin_top = 9
	preview_style.content_margin_bottom = 9
	preview.add_theme_stylebox_override("panel", preview_style)
	ui_frame.add_child(preview)
	var preview_box := VBoxContainer.new()
	preview_box.add_theme_constant_override("separation", 2)
	preview.add_child(preview_box)
	var preview_title := Label.new()
	preview_title.text = "明日经营预告"
	preview_title.add_theme_font_size_override("font_size", 14)
	preview_title.add_theme_color_override("font_color", preview_accent)
	preview_box.add_child(preview_title)
	tomorrow_name_label = Label.new()
	tomorrow_name_label.text = String(tomorrow["name"])
	tomorrow_name_label.add_theme_font_size_override("font_size", 21)
	preview_box.add_child(tomorrow_name_label)
	tomorrow_body_label = Label.new()
	tomorrow_body_label.text = String(tomorrow["challenge"])
	tomorrow_body_label.custom_minimum_size = Vector2(360, 0)
	tomorrow_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tomorrow_body_label.add_theme_font_size_override("font_size", 14)
	tomorrow_body_label.modulate = Color(AppTheme.COCOA.r, AppTheme.COCOA.g, AppTheme.COCOA.b, 0.68)
	preview_box.add_child(tomorrow_body_label)
	tomorrow_contract_label = Label.new()
	tomorrow_contract_label.add_theme_font_size_override("font_size", 14)
	tomorrow_contract_label.add_theme_color_override("font_color", CORAL)
	preview_box.add_child(tomorrow_contract_label)

	# 中央 3D 杯
	cup_view = CupViewScene.new()
	cup_view.position = Vector2(455, 250)
	ui_frame.add_child(cup_view)

	# 左侧配方便签卡（发现/命名时出现）
	note_card = PanelContainer.new()
	note_card.position = Vector2(150, 320)
	note_card.custom_minimum_size = Vector2(270, 0)
	note_card.visible = false
	note_box = VBoxContainer.new()
	note_box.add_theme_constant_override("separation", 8)
	note_card.add_child(note_box)
	ui_frame.add_child(note_card)

	# 右侧：风味雷达（夜靛面板）+ 反馈文本（奶油气泡）
	var radar_panel := PanelContainer.new()
	radar_panel.position = Vector2(915, 210)
	var rp_sb := StyleBoxFlat.new()
	rp_sb.bg_color = Color(INDIGO.r, INDIGO.g, INDIGO.b, 0.95)
	rp_sb.set_corner_radius_all(16)
	rp_sb.content_margin_left = 10
	rp_sb.content_margin_right = 10
	rp_sb.content_margin_top = 26
	rp_sb.content_margin_bottom = 10
	radar_panel.add_theme_stylebox_override("panel", rp_sb)
	radar = FlavorRadarScene.new()
	radar.custom_minimum_size = Vector2(320, 280)
	radar_panel.add_child(radar)
	ui_frame.add_child(radar_panel)
	var radar_tag := _tag("风味反馈", CORAL)
	radar_tag.position = Vector2(1010, 196)
	ui_frame.add_child(radar_tag)

	var fb_panel := PanelContainer.new()
	fb_panel.position = Vector2(915, 545)
	fb_panel.custom_minimum_size = Vector2(340, 100)
	result_scroll = ScrollContainer.new()
	result_scroll.custom_minimum_size = Vector2(316, 76)
	result_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	result_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	fb_panel.add_child(result_scroll)
	result_label = Label.new()
	result_label.custom_minimum_size = Vector2(292, 0)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 17)
	_set_result("NIGHT_WELCOME")
	result_scroll.add_child(result_label)
	ui_frame.add_child(fb_panel)

	# 底部主按钮：试做一杯（珊瑚大按钮）/ 收工睡觉（奶油）
	try_btn = Button.new()
	try_btn.text = GameLocale.text("NIGHT_TRY", [ATTEMPT_COST])
	try_btn.custom_minimum_size = Vector2(300, 62)
	try_btn.position = Vector2(490, 636)
	try_btn.add_theme_font_size_override("font_size", 24)
	try_btn.pressed.connect(_on_try)
	ui_frame.add_child(try_btn)
	var sleep_btn := Button.new()
	sleep_btn.text = "收工睡觉"
	sleep_btn.custom_minimum_size = Vector2(180, 54)
	sleep_btn.position = Vector2(1064, 644)
	var sl_sb := StyleBoxFlat.new()
	sl_sb.bg_color = CREAM
	sl_sb.set_corner_radius_all(12)
	sl_sb.content_margin_left = 14
	sl_sb.content_margin_right = 14
	sl_sb.content_margin_top = 8
	sl_sb.content_margin_bottom = 8
	sleep_btn.add_theme_stylebox_override("normal", sl_sb)
	sleep_btn.add_theme_color_override("font_color", AppTheme.COCOA)
	sleep_btn.pressed.connect(_on_sleep)
	ui_frame.add_child(sleep_btn)

	# 命名行（挂在便签卡里使用）
	name_row = HBoxContainer.new()
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "给新品起个名字…"
	name_edit.custom_minimum_size = Vector2(160, 40)
	name_row.add_child(name_edit)
	var shelf_btn := Button.new()
	shelf_btn.text = "上架新品"
	shelf_btn.pressed.connect(_on_shelf)
	name_row.add_child(shelf_btn)
	note_box.add_child(name_row)
	name_row.visible = false

	# 金币成长入口与夜间研发并列：玩家能在下一天营业前明确投资效率。
	var upgrade_btn := Button.new()
	upgrade_btn.text = "店铺升级"
	upgrade_btn.custom_minimum_size = Vector2(180, 54)
	upgrade_btn.position = Vector2(24, 644)
	_style_secondary_action(upgrade_btn)
	upgrade_btn.pressed.connect(_open_upgrades)
	ui_frame.add_child(upgrade_btn)
	staff_button = Button.new()
	staff_button.custom_minimum_size = Vector2(236, 54)
	staff_button.position = Vector2(214, 644)
	_style_secondary_action(staff_button)
	staff_button.pressed.connect(_open_staff)
	ui_frame.add_child(staff_button)
	_refresh_staff_button()
	contract_button = Button.new()
	contract_button.custom_minimum_size = Vector2(248, 54)
	contract_button.position = Vector2(802, 644)
	_style_secondary_action(contract_button)
	contract_button.pressed.connect(_open_contracts)
	ui_frame.add_child(contract_button)

	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)

	upgrade_panel = UpgradePanelScene.new()
	ui_frame.add_child(upgrade_panel)
	staff_panel = StaffPanelScene.new()
	staff_panel.roster_changed.connect(_refresh_staff_button)
	ui_frame.add_child(staff_panel)
	contract_panel = EndlessContractPanelScene.new()
	contract_panel.contract_changed.connect(_on_contract_changed)
	ui_frame.add_child(contract_panel)
	recipe_book_panel = RecipeBookPanelScene.new()
	recipe_book_panel.target_changed.connect(_on_research_target_changed)
	ui_frame.add_child(recipe_book_panel)
	menu_board_panel = MenuBoardPanelScene.new()
	menu_board_panel.menu_changed.connect(_on_featured_menu_changed)
	ui_frame.add_child(menu_board_panel)
	_refresh_contract_button()

	var settings_btn := Button.new()
	settings_btn.text = "设置"
	settings_btn.position = Vector2(1168, 10)
	settings_btn.custom_minimum_size = Vector2(98, 46)
	settings_btn.pressed.connect(_toggle_settings)
	ui_frame.add_child(settings_btn)
	settings_panel = PausePanelScene.new()
	settings_panel.resume_requested.connect(_close_settings)
	settings_panel.menu_requested.connect(_return_to_menu)
	ui_frame.add_child(settings_panel)


func _open_upgrades() -> void:
	if menu_board_panel.visible:
		menu_board_panel.hide_panel()
	if recipe_book_panel.visible:
		recipe_book_panel.hide_panel()
	if staff_panel.visible:
		staff_panel.hide_panel()
	if contract_panel.visible:
		contract_panel.hide_panel()
	upgrade_panel.show_panel()


func _open_staff() -> void:
	if GameState.day < StaffCatalog.UNLOCK_DAY:
		return
	if upgrade_panel.visible:
		upgrade_panel.hide_panel()
	if menu_board_panel.visible:
		menu_board_panel.hide_panel()
	if recipe_book_panel.visible:
		recipe_book_panel.hide_panel()
	if contract_panel.visible:
		contract_panel.hide_panel()
	staff_panel.show_panel()


func _open_contracts() -> void:
	if not EndlessContracts.is_unlocked(GameState.day):
		return
	if upgrade_panel.visible:
		upgrade_panel.hide_panel()
	if staff_panel.visible:
		staff_panel.hide_panel()
	if menu_board_panel.visible:
		menu_board_panel.hide_panel()
	if recipe_book_panel.visible:
		recipe_book_panel.hide_panel()
	contract_panel.show_panel()


func _open_recipe_book() -> void:
	if menu_board_panel.visible:
		menu_board_panel.hide_panel()
	if upgrade_panel.visible:
		upgrade_panel.hide_panel()
	if staff_panel.visible:
		staff_panel.hide_panel()
	if contract_panel.visible:
		contract_panel.hide_panel()
	recipe_book_panel.show_panel()


func _open_menu_board() -> void:
	if recipe_book_panel.visible:
		recipe_book_panel.hide_panel()
	if upgrade_panel.visible:
		upgrade_panel.hide_panel()
	if staff_panel.visible:
		staff_panel.hide_panel()
	if contract_panel.visible:
		contract_panel.hide_panel()
	menu_board_panel.show_panel()


func _on_featured_menu_changed() -> void:
	_refresh()


func _on_research_target_changed(_recipe_id: String) -> void:
	_refresh()


func _on_contract_changed() -> void:
	_refresh_contract_button()
	_refresh()


func _refresh_staff_button() -> void:
	if staff_button == null:
		return
	staff_button.disabled = GameState.day < StaffCatalog.UNLOCK_DAY
	if GameState.day < StaffCatalog.UNLOCK_DAY:
		staff_button.text = GameLocale.text("NIGHT_STAFF_LOCKED", [StaffCatalog.UNLOCK_DAY])
	elif StaffCatalog.has_staff():
		staff_button.text = GameLocale.text("NIGHT_STAFF_REST_NEXT", [GameLocale.staff_name(StaffCatalog.current()), GameState.day + 1]) \
			if StaffCatalog.rests_on(GameState.day + 1) else GameLocale.text("NIGHT_STAFF_CURRENT", [GameLocale.staff_name(StaffCatalog.current())])
	else:
		staff_button.text = GameLocale.text("NIGHT_STAFF_HIRE")


func _refresh_contract_button() -> void:
	if contract_button == null:
		return
	contract_button.visible = EndlessContracts.is_unlocked(GameState.day)
	if not contract_button.visible:
		return
	var active := EndlessContracts.active_for_day(GameState.day + 1)
	contract_button.text = GameLocale.text("NIGHT_CONTRACT_ACTIVE", [String(active.get("short_name", active.get("name", GameLocale.text("NIGHT_SIGNED"))))]) \
		if not active.is_empty() else GameLocale.text("NIGHT_CONTRACT_CHOOSE")


func _toggle_settings() -> void:
	if settings_panel.visible:
		_close_settings()
	else:
		settings_panel.show_panel(false, "night")
		get_tree().paused = true


func _close_settings() -> void:
	get_tree().paused = false
	settings_panel.hide_panel()


func _return_to_menu() -> void:
	get_tree().paused = false
	if GameState.has_save():
		GameState.load_save()
	else:
		GameState.reset_progress()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


## 货架超宽时整体缩放：后期解锁再多也不会被屏幕右缘裁掉
func _fit_shelf(shelf: HBoxContainer) -> void:
	await get_tree().process_frame
	if not is_instance_valid(shelf):
		return
	var max_w := get_viewport_rect().size.x - shelf.position.x * 2.0
	if shelf.size.x > max_w and shelf.size.x > 0.0:
		shelf.scale = Vector2.ONE * (max_w / shelf.size.x)


func _tag(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(9)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", AppTheme.COCOA)
	p.add_child(l)
	return p


func _style_secondary_action(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.96)
	normal.set_corner_radius_all(12)
	normal.set_border_width_all(2)
	normal.border_color = Color(CORAL.r, CORAL.g, CORAL.b, 0.78)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(CORAL.r, CORAL.g, CORAL.b, 0.13)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(CORAL.r, CORAL.g, CORAL.b, 0.23)
	var focus: StyleBoxFlat = normal.duplicate()
	focus.set_border_width_all(4)
	focus.border_color = AppTheme.COCOA
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, AppTheme.COCOA)


func _shelf_group(shelf: HBoxContainer, title: String, items: Array, kind: String) -> void:
	var group := PanelContainer.new()
	var g_sb := StyleBoxFlat.new()
	g_sb.bg_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.94)
	g_sb.set_corner_radius_all(14)
	g_sb.content_margin_left = 8
	g_sb.content_margin_right = 8
	g_sb.content_margin_top = 6
	g_sb.content_margin_bottom = 6
	group.add_theme_stylebox_override("panel", g_sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	group.add_child(v)
	var tag := _tag(title, MINT)
	tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(tag)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	for item in items:
		var display_name := GameLocale.ingredient_name(item)
		var short_name := GameLocale.ingredient_short_name(item)
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(56, 56)
		btn.tooltip_text = GameLocale.text("NIGHT_SELECT_TOOLTIP", [display_name])
		var icon_path := "res://assets/icons/%s.png" % String(item.get("id", ""))
		if ResourceLoader.exists(icon_path):
			btn.icon = load(icon_path)
			btn.add_theme_constant_override("icon_max_width", 44)
		else:
			btn.text = short_name.left(2)
		btn.add_theme_stylebox_override("normal", _tile_style(false))
		btn.add_theme_stylebox_override("hover", _tile_style(false))
		btn.add_theme_stylebox_override("pressed", _tile_style(true))
		btn.add_theme_color_override("font_color", AppTheme.COCOA)
		btn.pressed.connect(_on_tile.bind(kind, item))
		if _first_tile == null:
			_first_tile = btn
		cell.add_child(btn)
		var lbl := Label.new()
		lbl.text = short_name
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", AppTheme.COCOA)
		cell.add_child(lbl)
		row.add_child(cell)
		_tiles[_sel_key(kind, item)] = {"btn": btn, "label": lbl, "on": false, "name": display_name, "item": item, "has_icon": ResourceLoader.exists(icon_path)}
	shelf.add_child(group)


func _on_input_scheme_changed(gamepad: bool) -> void:
	if gamepad and is_instance_valid(_first_tile):
		_first_tile.call_deferred("grab_focus")


func _sel_key(kind: String, item: Dictionary) -> String:
	return kind + "/" + String(item.get("id", str(item.get("value", ""))))


func _set_tile(kind: String, item: Variant, on: bool) -> void:
	if item == null:
		return
	var t: Variant = _tiles.get(_sel_key(kind, item))
	if t != null:
		t["on"] = on
		t["btn"].add_theme_stylebox_override("normal", _tile_style(on))
		t["btn"].add_theme_stylebox_override("hover", _tile_style(on))
		t["btn"].tooltip_text = GameLocale.text("NIGHT_SELECTED_TOOLTIP" if on else "NIGHT_SELECT_TOOLTIP", [String(t["name"])])


# ---------------------------------------------------------------- 选料

func _on_tile(kind: String, item: Dictionary) -> void:
	_invalidate_pending_shelf()
	Sfx.play("select", 0.96 if kind == "sugar" else 1.0)
	Haptics.play("tap")
	match kind:
		"base":
			_on_base(item)
		"milk":
			_on_milk(item)
		"topping":
			_on_topping(item)
		"sugar":
			_on_sugar(item)


func _on_base(item: Dictionary) -> void:
	_set_tile("base", cup_base, false)
	cup_base = item
	_set_tile("base", cup_base, true)
	_refresh()


func _on_milk(item: Dictionary) -> void:
	_set_tile("milk", cup_milk, false)
	cup_milk = item
	_set_tile("milk", cup_milk, true)
	_refresh()


func _on_topping(item: Dictionary) -> void:
	for t in cup_tops:
		if t["id"] == item["id"]:
			cup_tops.erase(t)
			_set_tile("topping", item, false)
			_refresh()
			return
	if cup_tops.size() < 2:
		cup_tops.append(item)
		_set_tile("topping", item, true)
	_refresh()


func _on_sugar(item: Dictionary) -> void:
	_set_tile("sugar", cup_sugar, false)
	cup_sugar = item
	_set_tile("sugar", cup_sugar, true)
	_refresh()


## 上架记录的公式必须与试做得分的那杯一致。改料后旧分数即失效，
## 防止旧高分搭配新配方被登记为高价爆款（也可被当作刷分漏洞）。
func _invalidate_pending_shelf() -> void:
	if pending_quality <= 0:
		return
	pending_quality = 0
	if String(_note_state.get("kind", "")) == "shelf":
		note_card.visible = false
		_note_state.clear()


func _refresh() -> void:
	if cup_view:
		cup_view.update_cup(cup_base, cup_milk, cup_tops, cup_sugar, 0.0, false)
	try_btn.text = GameLocale.text("NIGHT_TRY", [ATTEMPT_COST])
	info_label.text = GameLocale.text("NIGHT_HUD", [GameState.day, budget, GameState.inspiration])
	info_label.tooltip_text = GameLocale.text("NIGHT_BUDGET_TOOLTIP", [ACTIVE_BUDGET_CAP])
	book_label.text = GameLocale.text("NIGHT_BOOK", [
		GameState.discovered.size(), GameData.recipes.size(),
		GameState.dark_discovered.size(), GameData.dark_recipes.size(),
		GameState.tests.size()])
	book_label.tooltip_text = GameLocale.text("RECIPE_BOOK_TITLE")
	menu_button.text = GameLocale.text("NIGHT_MENU_PILL", [
		MenuCatalog.featured_items().size(), MenuCatalog.FEATURED_LIMIT,
		MenuCatalog.hot_featured_count()])
	menu_button.tooltip_text = GameLocale.text("MENU_BOARD_TITLE")
	var target_name := RecipeJournal.target_display_name()
	selection_title_label.text = GameLocale.text("NIGHT_CURRENT_RECIPE") if target_name.is_empty() \
		else GameLocale.text("NIGHT_CURRENT_RECIPE_TARGET", [target_name])
	var topping_names: Array[String] = []
	for topping in cup_tops:
		topping_names.append(GameLocale.ingredient_name(topping))
	var topping_text := GameLocale.text("NIGHT_NO_TOPPINGS") if topping_names.is_empty() else GameLocale.text("LIST_SEPARATOR").join(topping_names)
	selection_label.text = GameLocale.text("NIGHT_SELECTION", [
		GameLocale.ingredient_name(cup_base) if cup_base != null else GameLocale.text("NIGHT_BASE_UNSELECTED"),
		GameLocale.ingredient_name(cup_milk) if cup_milk != null else GameLocale.text("NIGHT_MILK_UNSELECTED"),
		topping_text,
		GameLocale.ingredient_name(cup_sugar) if cup_sugar != null else GameLocale.text("NIGHT_SUGAR_UNSELECTED")])
	if tomorrow_contract_label != null:
		var tomorrow_contract := EndlessContracts.active_for_day(GameState.day + 1)
		tomorrow_contract_label.text = (GameLocale.text("NIGHT_TOMORROW_CONTRACT", [
			String(tomorrow_contract.get("short_name", tomorrow_contract.get("name", ""))),
			String(tomorrow_contract.get("target_text", ""))])) if not tomorrow_contract.is_empty() \
			else (GameLocale.text("NIGHT_TOMORROW_UNSIGNED") if EndlessContracts.is_unlocked(GameState.day) else "")
	if brief_panel != null:
		var brief_complete := ResearchBriefs.is_complete()
		var brief_accent := MINT if brief_complete else GOLD
		var brief_style := StyleBoxFlat.new()
		brief_style.bg_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.96)
		brief_style.set_corner_radius_all(13)
		brief_style.set_border_width_all(2)
		brief_style.border_color = Color(brief_accent.r, brief_accent.g, brief_accent.b, 0.82)
		brief_style.content_margin_left = 14
		brief_style.content_margin_right = 14
		brief_style.content_margin_top = 7
		brief_style.content_margin_bottom = 7
		brief_panel.add_theme_stylebox_override("panel", brief_style)
		brief_title_label.text = ResearchBriefs.title()
		brief_title_label.add_theme_color_override("font_color", brief_accent)
		brief_body_label.text = ResearchBriefs.description()
		brief_body_label.tooltip_text = brief_body_label.text
	try_btn.disabled = budget < ATTEMPT_COST


# ---------------------------------------------------------------- 便签卡

func _localized_arg(kind: String, value: Variant) -> Dictionary:
	return {"_locale_kind": kind, "value": value}


func _resolve_result_arg(arg: Variant) -> Variant:
	if not arg is Dictionary or not arg.has("_locale_kind"):
		return arg
	var value: Variant = arg.get("value")
	match String(arg["_locale_kind"]):
		"ingredient":
			return GameLocale.ingredient_name(value)
		"recipe":
			return GameLocale.recipe_name(RecipeJournal.recipe(String(value)))
		"affinity":
			return GameLocale.affinity_note(value)
		"rank":
			return ResearchProgress.rank_name(String(value))
		"slot":
			return GameLocale.slot_name(String(value))
		"grade":
			return _grade(int(value))
		"tier":
			return GameLocale.tier_name(String(value))
		"text":
			return GameLocale.text(String(value))
		"brief":
			return ResearchBriefs.objective_text(value)
		"dark_menu":
			return GameState.dark_menu_name(value)
	return value


func _append_result(key: String, args: Array = []) -> void:
	_result_entries.append({"key": key, "args": args})


func _set_result(key: String, args: Array = []) -> void:
	_result_entries.clear()
	_append_result(key, args)
	_render_result_entries()


func _render_result_entries() -> void:
	if result_label == null:
		return
	var lines: Array[String] = []
	for entry in _result_entries:
		var args: Array = []
		for arg in entry.get("args", []):
			args.append(_resolve_result_arg(arg))
		lines.append(GameLocale.text(String(entry["key"]), args))
	result_label.text = "\n".join(lines)


func _show_note_state(state: Dictionary) -> void:
	_note_state = state.duplicate(true)
	_render_note_state()


func _render_note_state() -> void:
	if _note_state.is_empty():
		return
	match String(_note_state.get("kind", "")):
		"legend", "dark":
			var recipe := RecipeJournal.recipe(String(_note_state["recipe_id"]))
			if recipe.is_empty():
				return
			var dark := String(_note_state["kind"]) == "dark"
			_show_note(GameLocale.recipe_name(recipe), GameLocale.text("NIGHT_DARK_LEGEND") \
				if dark else GameLocale.text("NIGHT_LEGENDARY_TIER", [GameLocale.tier_name(String(recipe["tier"]))]),
				PLUM if dark else CORAL, GameLocale.recipe_description(recipe))
		"shelf":
			var score := int(_note_state.get("score", 0))
			_show_note(GameLocale.text("NIGHT_NAME_NEW"), GameLocale.text("NIGHT_SHELF_READY", [score]), MINT,
				GameLocale.text("NIGHT_NAME_INSTRUCTION"), true)

func _show_note(title: String, chip_text: String, chip_color: Color, body: String,
		with_naming := false) -> void:
	# name_row is persistent state. Keep it parented (hidden when unused) so the
	# scene owns and frees it; detaching it here leaked its controls and text RIDs.
	if name_row.get_parent() != note_box:
		note_box.add_child(name_row)
	for c in note_box.get_children():
		if c != name_row:
			c.queue_free()
	var chip := _tag(chip_text, chip_color)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	note_box.add_child(chip)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 22)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_box.add_child(t)
	if body != "":
		var b := Label.new()
		b.text = body
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(240, 0)
		b.add_theme_font_size_override("font_size", 15)
		note_box.add_child(b)
	name_row.visible = with_naming
	note_box.move_child(name_row, note_box.get_child_count() - 1)
	note_card.visible = true


# ---------------------------------------------------------------- 试做（判定逻辑不变）

func _on_try() -> void:
	if budget < ATTEMPT_COST:
		Haptics.play("warning")
		return
	if cup_base == null or cup_milk == null or cup_sugar == null:
		_set_result("NIGHT_INCOMPLETE")
		Haptics.play("warning")
		return
	_consume_budget(ATTEMPT_COST)
	_sync_budget()
	note_card.visible = false
	_note_state.clear()
	cup_view.play_shake()
	Sfx.play("lab_stir")
	Haptics.play("confirm")

	var cup := {"base": cup_base, "milk": cup_milk, "toppings": cup_tops, "sugar": cup_sugar}
	_result_entries.clear()

	var fl: Dictionary = RecipeLab.compute_flavor(cup)
	var cup_score: Dictionary = RecipeLab.score_cup(fl["flavor"], fl["triggered"])
	radar.set_values(fl["flavor"])
	for rule in fl["triggered"]:
		_append_result("NIGHT_SYNERGY" if rule["type"] == "synergy" else "NIGHT_CLASH", [
			_localized_arg("affinity", rule.duplicate(true))])

	var pair_result := ResearchProgress.record_pair(String(cup_base["id"]), String(cup_milk["id"]))
	if bool(pair_result.get("new", false)):
		var pairing: Dictionary = pair_result.get("rating", {})
		_append_result("NIGHT_PAIR_DISCOVERED", [
			_localized_arg("ingredient", cup_base), _localized_arg("ingredient", cup_milk),
			_localized_arg("rank", String(pairing.get("rank", "neutral")))])
		if bool(pair_result.get("complete", false)):
			_grant_budget(ResearchProgress.NIGHT_MASTERY_BONUS)
			_sync_budget()
			_append_result("NIGHT_PAIR_MASTERY", [ResearchProgress.NIGHT_MASTERY_BONUS])

	var m: Dictionary = RecipeLab.match_recipe(cup, GameData.recipes)
	var dm: Dictionary = RecipeLab.match_recipe(cup, GameData.dark_recipes)

	if m["hit"] != null:
		var r: Dictionary = m["hit"]
		MenuCatalog.register_legend(r)
		if r["id"] in GameState.discovered:
			_append_result("NIGHT_RECIPE_REPEAT", [_localized_arg("recipe", String(r["id"]))])
		else:
			GameState.discovered.append(r["id"])
			Sfx.play("discover")
			Haptics.play("discover")
			_append_result("NIGHT_RECIPE_DISCOVERED", [_localized_arg("recipe", String(r["id"]))])
			_show_note_state({"kind": "legend", "recipe_id": String(r["id"])})
		if RecipeJournal.complete_if_target(String(r["id"]), false):
			_append_result("NIGHT_TARGET_COMPLETE", [_localized_arg("recipe", String(r["id"]))])
	elif dm["hit"] != null:
		var r: Dictionary = dm["hit"]
		var dark_candidate := MenuCatalog.dark_candidate_for_legend(String(r["id"]))
		var already_listed := false
		for entry in GameState.dark_menu:
			if entry is Dictionary and MenuCatalog.dark_item_id(entry) == MenuCatalog.dark_item_id(dark_candidate):
				already_listed = true
				break
		if r["id"] in GameState.dark_discovered:
			_append_result("NIGHT_DARK_REPEAT", [_localized_arg("recipe", String(r["id"]))])
			if not already_listed:
				_offer_dark_candidate(dark_candidate)
		else:
			GameState.dark_discovered.append(r["id"])
			GameState.buzz += int(r["buzz"])
			Sfx.play("discover", 0.6)
			Haptics.play("discover")
			_append_result("NIGHT_DARK_DISCOVERED", [int(r["buzz"])])
			if MenuCatalog.install_dark_candidate(dark_candidate, -1, false):
				_append_result("NIGHT_DARK_ADDED")
			else:
				_append_result("NIGHT_DARK_FULL", [DARK_MENU_CAP])
				_offer_dark_candidate(dark_candidate)
			_show_note_state({"kind": "dark", "recipe_id": String(r["id"])})
		if RecipeJournal.complete_if_target(String(r["id"]), false):
			_append_result("NIGHT_TARGET_COMPLETE", [_localized_arg("recipe", String(r["id"]))])
	else:
		var sc: Dictionary = cup_score
		var score: int = sc["score"]
		if sc["worst_dim"] != "":
			var hi: int = int(GameData.balance_bands[sc["worst_dim"]][1])
			var over: bool = int(fl["flavor"][sc["worst_dim"]]) > hi
			_append_result("NIGHT_FLAVOR_FEEDBACK", [
				_localized_arg("text", FEEDBACK_HIGH[sc["worst_dim"]] if over else FEEDBACK_LOW[sc["worst_dim"]])])
		else:
			_append_result("NIGHT_FEEDBACK_BALANCED")
		if m["near"] == "sugar":
			_append_result("NIGHT_CLUE_SUGAR")
		elif m["near"] != "":
			_append_result("NIGHT_CLUE_SLOT", [_localized_arg("slot", String(m["near"]))])
		if 75 <= score and score < RecipeLab.SHELF_SCORE:
			_append_result("NIGHT_CLUE_CLOSE")
		if dm["near"] != "":
			_append_result("NIGHT_DARK_HINT")
		_append_result("NIGHT_QUALITY_SCORE", [_localized_arg("grade", score), score])

		if score >= RecipeLab.SHELF_SCORE:
			pending_quality = score
			Haptics.play("success")
			_show_note_state({"kind": "shelf", "score": score})
		elif score < RecipeLab.DARK_SCORE:
			Sfx.play("bad")
			Haptics.play("warning")
			var topping_ids: Array = []
			for topping in cup_tops:
				topping_ids.append(String(topping["id"]))
			var dark_entry := MenuCatalog.dark_candidate_for_trial(
				String(cup_base["id"]), String(cup_milk["id"]), topping_ids,
				int(cup_sugar["value"]), score)
			if MenuCatalog.install_dark_candidate(dark_entry, -1, false):
				GameState.buzz += 1
				_append_result("NIGHT_DARK_MENU_ADDED", [_localized_arg("dark_menu", dark_entry)])
			else:
				_append_result("NIGHT_DARK_MENU_DISCARD")
				_offer_dark_candidate(dark_entry)

	var used: Array = [cup_base["id"], cup_milk["id"]]
	for t in cup_tops:
		used.append(t["id"])
	GameState.gain_xp(used)
	var brief_result := ResearchBriefs.record_trial(String(cup_base["id"]), String(cup_milk["id"]), used, int(cup_score["score"]))
	if bool(brief_result.get("completed", false)):
		var brief_reward := int(brief_result.get("reward", 0))
		_grant_budget(brief_reward)
		_sync_budget()
		Sfx.play("combo", 1.12)
		Haptics.play("success")
		_append_result("LAB_BRIEF_REWARD", [brief_reward,
			_localized_arg("brief", brief_result.get("brief", {}).duplicate(true))])
	GameState.save_game()
	_render_result_entries()
	_scroll_feedback_to_end.call_deferred()
	_refresh()


func _offer_dark_candidate(candidate: Dictionary) -> void:
	if candidate.is_empty() or menu_board_panel == null:
		return
	# A full menu becomes an immediate, informed replacement decision. The
	# candidate formula is shown beside all three live slots; nothing is silently
	# discarded and no arbitrary slot is overwritten.
	menu_board_panel.call_deferred("show_dark_candidate", candidate)


func _scroll_feedback_to_end() -> void:
	await get_tree().process_frame
	if result_scroll != null:
		var bar := result_scroll.get_v_scroll_bar()
		result_scroll.scroll_vertical = roundi(bar.max_value)


func _grade(score: int) -> String:
	if score >= RecipeLab.SHELF_SCORE:
		return GameLocale.text("NIGHT_GRADE_EXCELLENT")
	if score >= 60:
		return GameLocale.text("NIGHT_GRADE_GOOD")
	if score >= RecipeLab.DARK_SCORE:
		return GameLocale.text("NIGHT_GRADE_MEDIOCRE")
	return GameLocale.text("NIGHT_GRADE_FAILED")


func _on_shelf() -> void:
	if pending_quality <= 0:
		return
	var recipe_name := name_edit.text.strip_edges()
	if recipe_name.is_empty():
		return
	var topping_ids: Array[String] = []
	for topping in cup_tops:
		topping_ids.append(String(topping["id"]))
	GameState.tests.append({
		"name": recipe_name, "quality": pending_quality, "scores": [],
		"base": String(cup_base["id"]), "milk": String(cup_milk["id"]),
		"toppings": topping_ids, "sugar": int(cup_sugar["value"]),
	})
	GameState.save_game()
	Sfx.play("coin")
	Haptics.play("confirm")
	name_edit.text = ""
	note_card.visible = false
	_note_state.clear()
	_set_result("NIGHT_MARKET_TEST_STARTED", [recipe_name])
	_refresh()


# ---------------------------------------------------------------- 收工 → 检验结算 → 次日

func _on_sleep() -> void:
	_bank_unspent_performance()
	var settlement := MarketTests.advance()
	GameState.save_game()
	_refresh()
	_show_market_settlement(settlement)


func _show_market_settlement(settlement: Dictionary) -> void:
	for child in overlay.get_children():
		child.queue_free()
	var panel: NightSettlementPanel = NightSettlementPanelScene.new()
	panel.continue_requested.connect(_next_day)
	overlay.add_child(panel)
	panel.show_results(GameState.day, settlement)
	overlay.visible = true


func _next_day() -> void:
	GameState.night_budget = -1
	GameState.night_budget_day = 0
	GameState.night_performance_remaining = 0
	GameState.market_settlement = {}
	if GameState.day >= 14 and not GameState.campaign_claimed:
		GameState.finalize_campaign()
		get_tree().change_scene_to_file("res://scenes/campaign_summary/campaign_summary.tscn")
		return
	GameState.day += 1
	GameState.phase = "day"
	# 先标记开店快照再存档：无论玩家是否在日中写过存档，恢复当天都能回滚。
	GameState.mark_day_open()
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/day_shop/day_shop.tscn")


func _sync_budget() -> void:
	GameState.night_budget = maxi(0, budget)
	GameState.night_budget_day = GameState.day


func _consume_budget(amount: int) -> void:
	var safe_amount := mini(maxi(0, amount), budget)
	# 每晚的保底/菜单/研究加成先支付试作；只有它们不够时，
	# 才消耗从持久库装入的灵感。即时奖励也会被视为当晚临时预算。
	var temporary_available := maxi(0, budget - GameState.night_performance_remaining)
	var performance_cost := maxi(0, safe_amount - temporary_available)
	GameState.night_performance_remaining = maxi(0,
		GameState.night_performance_remaining - performance_cost)
	budget -= safe_amount


func _grant_budget(amount: int) -> void:
	var safe_amount := maxi(0, amount)
	var active_reward := mini(safe_amount, maxi(0, ACTIVE_BUDGET_CAP - budget))
	budget += active_reward
	# 同一杯可能同时完成研究单和相性图鉴。超出活跃上限的
	# 奖励直接留存，不会因上限而消失。
	GameState.inspiration += safe_amount - active_reward


func _bank_unspent_performance() -> void:
	# 收工可因结算重进而被再次调用；先清记录使退回幂等。
	var returned := mini(maxi(0, GameState.night_performance_remaining), budget)
	GameState.night_performance_remaining = 0
	GameState.inspiration += returned
	budget -= returned
	_sync_budget()


func _on_locale_changed(_locale: String) -> void:
	for tile in _tiles.values():
		var display_name := GameLocale.ingredient_name(tile["item"])
		var short_name := GameLocale.ingredient_short_name(tile["item"])
		tile["name"] = display_name
		tile["label"].text = short_name
		if not bool(tile["has_icon"]):
			tile["btn"].text = short_name.left(2)
		tile["btn"].tooltip_text = GameLocale.text("NIGHT_SELECTED_TOOLTIP" if bool(tile["on"]) else "NIGHT_SELECT_TOOLTIP", [display_name])
	var tomorrow := DailyEvents.next_event(GameState.day)
	if tomorrow_name_label != null:
		tomorrow_name_label.text = String(tomorrow["name"])
		tomorrow_body_label.text = String(tomorrow["challenge"])
	_refresh_staff_button()
	_refresh_contract_button()
	_refresh()
	_render_result_entries()
	if note_card != null and note_card.visible:
		_render_note_state()
