## 夜间市场检验结算：分阶段卡片、定级结果与减少动态兼容。
extends PanelContainer
class_name NightSettlementPanel

signal continue_requested

const CORAL := Color("FF6259")
const MINT := Color("27B9A7")
const CREAM := Color("FFF8ED")
const COCOA := Color("30201D")
const PLUM := Color("4B2948")
const GOLD := Color("D99A43")

var _title: Label
var _subtitle: Label
var _summary: Label
var _cards: GridContainer
var _footer: Label
var _continue: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	custom_minimum_size = Vector2(920, 570)
	size = custom_minimum_size
	get_viewport().size_changed.connect(_layout_center)
	_layout_center()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(CREAM.r, CREAM.g, CREAM.b, 0.99)
	panel_style.set_corner_radius_all(20)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(MINT.r, MINT.g, MINT.b, 0.72)
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	add_theme_stylebox_override("panel", panel_style)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	add_child(root)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 31)
	_title.add_theme_color_override("font_color", COCOA)
	header.add_child(_title)
	_summary = Label.new()
	_summary.add_theme_font_size_override("font_size", 16)
	# 16px 摘要小字不用 MINT（对白卡 2.45:1，P12-F4）：深可可保证 ≥4.5:1，
	# accent 保留在卡片描边与进度条上。
	_summary.add_theme_color_override("font_color", COCOA)
	header.add_child(_summary)
	_subtitle = Label.new()
	_subtitle.add_theme_font_size_override("font_size", 15)
	_subtitle.add_theme_color_override("font_color", Color(COCOA.r, COCOA.g, COCOA.b, 0.70))
	root.add_child(_subtitle)

	var rule := HSeparator.new()
	root.add_child(rule)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 360)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_cards = GridContainer.new()
	_cards.columns = 2
	_cards.add_theme_constant_override("h_separation", 12)
	_cards.add_theme_constant_override("v_separation", 12)
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_cards)

	_footer = Label.new()
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer.add_theme_font_size_override("font_size", 15)
	_footer.add_theme_color_override("font_color", Color(COCOA.r, COCOA.g, COCOA.b, 0.72))
	root.add_child(_footer)
	_continue = Button.new()
	_continue.custom_minimum_size = Vector2(0, 52)
	_continue.add_theme_font_size_override("font_size", 20)
	_continue.pressed.connect(func(): continue_requested.emit())
	root.add_child(_continue)


func show_results(day_number: int, settlement: Dictionary) -> void:
	_title.text = GameLocale.text("MARKET_SETTLEMENT_TITLE", [day_number])
	# 分档线明示（P5 试玩）：88/78/62 不再是隐藏规则。
	_subtitle.text = "%s  %s" % [GameLocale.text("MARKET_SETTLEMENT_SUBTITLE"),
		GameLocale.text("MARKET_SETTLEMENT_TIERS", [
			MarketTests.TIER_HIT, MarketTests.TIER_SIGNATURE, MarketTests.TIER_REGULAR])]
	var results: Array = settlement.get("results", [])
	var finished := 0
	for result in results:
		if String(result.get("outcome", "testing")) != "testing":
			finished += 1
	_summary.text = GameLocale.text("MARKET_SETTLEMENT_SUMMARY", [results.size(), finished]) \
		if bool(settlement.get("had_tests", false)) else GameLocale.text("MARKET_SETTLEMENT_SUMMARY_NONE")
	for child in _cards.get_children():
		child.free()
	_cards.columns = 1 if results.is_empty() else 2
	if results.is_empty():
		_cards.add_child(_empty_card())
	else:
		for result in results:
			_cards.add_child(_result_card(result))
	_footer.text = GameLocale.text("MARKET_SETTLEMENT_CAMPAIGN" if day_number >= 14 else "MARKET_SETTLEMENT_TOMORROW")
	_continue.text = GameLocale.text("NIGHT_VIEW_RATING") if day_number >= 14 else GameLocale.text("NIGHT_START_DAY", [day_number + 1])
	_animate_cards()
	_continue.grab_focus()


func _result_card(result: Dictionary) -> PanelContainer:
	var outcome := String(result.get("outcome", "testing"))
	var accent := _outcome_color(outcome)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(416, 164)
	card.set_meta("market_result_card", true)
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(14)
	style.set_border_width_all(2)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.78)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	card.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	box.add_child(header)
	var name := Label.new()
	name.text = String(result.get("name", ""))
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.tooltip_text = name.text
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.add_theme_font_size_override("font_size", 21)
	name.add_theme_color_override("font_color", COCOA)
	header.add_child(name)
	var score := Label.new()
	score.text = GameLocale.text("MARKET_SETTLEMENT_SCORE", [int(result.get("score", 0))])
	score.add_theme_font_size_override("font_size", 22)
	# 22px 分数不属 WCAG 大字（需 ≥24px 或粗体），accent 换深色（P12-F4）。
	score.add_theme_color_override("font_color", COCOA)
	header.add_child(score)
	var stage := int(result.get("stage", 1))
	var stage_label := Label.new()
	stage_label.text = GameLocale.text("MARKET_SETTLEMENT_STAGE", [stage, MarketTests.STAGES])
	stage_label.add_theme_font_size_override("font_size", 13)
	# 13px 阶段标签必须全对比（P12-F4）。
	stage_label.add_theme_color_override("font_color", COCOA)
	box.add_child(stage_label)
	# 配方行（P5 试玩）：事后能复盘“这是哪杯饮品”。
	# [P5-1 2026-08-17] MarketTests.advance() 的结果现随行 base/milk/toppings/sugar
	# （存档白名单同步保留）；旧内存字典缺配方时整行隐藏而不是渲染空原料名。
	if not String(result.get("base", "")).is_empty():
		var formula_label := Label.new()
		formula_label.text = GameLocale.text("MARKET_SETTLEMENT_FORMULA",
			[RecipeJournal.formula(result)])
		formula_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		formula_label.add_theme_font_size_override("font_size", 13)
		formula_label.add_theme_color_override("font_color", Color(COCOA.r, COCOA.g, COCOA.b, 0.66))
		box.add_child(formula_label)
	var progress := ProgressBar.new()
	progress.max_value = MarketTests.STAGES
	progress.value = stage
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(0, 9)
	box.add_child(progress)
	var outcome_label := Label.new()
	outcome_label.text = _outcome_text(result)
	outcome_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outcome_label.custom_minimum_size = Vector2(0, 38)
	outcome_label.add_theme_font_size_override("font_size", 14)
	outcome_label.add_theme_color_override("font_color", Color(COCOA.r, COCOA.g, COCOA.b, 0.76))
	box.add_child(outcome_label)
	return card


func _outcome_text(result: Dictionary) -> String:
	var outcome := String(result.get("outcome", "testing"))
	var average := roundi(float(result.get("average", 0.0)))
	match outcome:
		"hit":
			var price := int(result.get("price", 0))
			return GameLocale.text("MARKET_SETTLEMENT_HIT", [average,
				price if price > 0 else int(MenuCatalog.PRICE_STANDARD["爆款"])])
		"signature":
			var price := int(result.get("price", 0))
			return GameLocale.text("MARKET_SETTLEMENT_SIGNATURE", [average,
				price if price > 0 else int(MenuCatalog.PRICE_STANDARD["招牌"])])
		"regular":
			var price := int(result.get("price", 0))
			return GameLocale.text("MARKET_SETTLEMENT_REGULAR", [average,
				price if price > 0 else int(MenuCatalog.PRICE_STANDARD["普通"])])
		"failed":
			var refund := int(result.get("refund", 0))
			return GameLocale.text("MARKET_SETTLEMENT_FAILED", [average,
				refund if refund > 0 else MarketTests.FAILURE_REFUND])
	return GameLocale.text("MARKET_SETTLEMENT_TESTING", [average, _trend_text(int(result.get("trend", 0)))])


func _trend_text(trend: int) -> String:
	if trend > 0:
		return GameLocale.text("MARKET_SETTLEMENT_TREND_UP", [trend])
	if trend < 0:
		return GameLocale.text("MARKET_SETTLEMENT_TREND_DOWN", [absi(trend)])
	return GameLocale.text("MARKET_SETTLEMENT_TREND_FLAT")


func _empty_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(852, 250)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MINT.r, MINT.g, MINT.b, 0.07)
	style.set_corner_radius_all(15)
	style.set_border_width_all(1)
	style.border_color = Color(MINT.r, MINT.g, MINT.b, 0.38)
	card.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = GameLocale.text("MARKET_SETTLEMENT_EMPTY")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(COCOA.r, COCOA.g, COCOA.b, 0.62))
	card.add_child(label)
	return card


func _outcome_color(outcome: String) -> Color:
	match outcome:
		"hit":
			return CORAL
		"signature":
			return MINT
		"regular":
			return GOLD
		"failed":
			return PLUM
	return MINT


func _animate_cards() -> void:
	if GameState.reduced_motion():
		return
	var tween := create_tween().set_parallel(true)
	var index := 0
	for card in _cards.get_children():
		card.modulate = Color(1, 1, 1, 0)
		card.scale = Vector2(0.985, 0.985)
		card.pivot_offset = card.custom_minimum_size * 0.5
		tween.tween_property(card, "modulate", Color.WHITE, 0.22).set_delay(index * 0.10)
		tween.tween_property(card, "scale", Vector2.ONE, 0.22).set_delay(index * 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		index += 1


func result_card_count() -> int:
	var count := 0
	for child in _cards.get_children():
		if child.has_meta("market_result_card"):
			count += 1
	return count


func confine_focus() -> void:
	_continue.grab_focus()


func _layout_center() -> void:
	var viewport_size := get_viewport_rect().size
	position = ((viewport_size - custom_minimum_size) * 0.5).floor()
