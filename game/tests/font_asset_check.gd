## Runtime font package guard: import, common UI coverage, fallback and file budget.
extends Node

const FONT_PATH := "res://assets/fonts/LXGWWenKai-Regular.ttf"
const CRITICAL_COPY := "奶茶物语白天经营夜间研发评论家网红团单小满桃子阿澄窗口全屏暂停继续设置金币灵感话题完美连击MilkTeaStoryResearchShopUpgradesContractsStaff×○□△"


func _ready() -> void:
	GameState.test_mode = true
	var font := load(FONT_PATH) as FontFile
	assert(font != null, "runtime font failed to import")
	assert(font.allow_system_fallback, "player-entered names require system fallback")
	for character in CRITICAL_COPY:
		var codepoint := character.unicode_at(0)
		assert(font.has_char(codepoint), "missing critical glyph U+%04X" % codepoint)
	var file := FileAccess.open(FONT_PATH, FileAccess.READ)
	assert(file != null)
	var bytes := file.get_length()
	file.close()
	assert(bytes < 1024 * 1024, "runtime font exceeds 1 MiB budget")
	assert(bytes > 256 * 1024, "runtime font is suspiciously small")
	print("[FONT] passed critical_chars=%d system_fallback=true bytes=%d" % [
		CRITICAL_COPY.length(), bytes])
	Sfx.stop_all()
	await get_tree().process_frame
	get_tree().quit()
