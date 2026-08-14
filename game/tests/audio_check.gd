## 音频身份回归：资产、总线、独立音量、场景路由和并发回收。
extends Node

const EXPECTED_SFX := [
	"bad", "coin", "combo", "customer_arrive", "customer_leave", "discover",
	"lab_stir", "pour_milk", "pour_tea", "seal", "select", "serve", "shake",
	"staff_alert", "staff_wake", "sugar", "topping", "ui_close", "ui_open",
]
const EXPECTED_MUSIC := ["menu", "day", "night", "campaign"]


func _ready() -> void:
	GameState.test_mode = true
	GameState.settings = {
		"sound_volume": 0.65,
		"sfx_volume": 0.65,
		"music_volume": 0.40,
		"reduced_motion": false,
	}
	Sfx.apply_settings()

	for sfx_name in EXPECTED_SFX:
		assert(Sfx.has_sfx(sfx_name), "缺少音效：%s" % sfx_name)
	for music_name in EXPECTED_MUSIC:
		assert(Sfx.has_music(music_name), "缺少音乐：%s" % music_name)
	assert(AudioServer.get_bus_index("Music") >= 0)
	assert(AudioServer.get_bus_index("SFX") >= 0)
	assert(is_equal_approx(Sfx.bus_volume_linear("Music"), 0.40))
	assert(is_equal_approx(Sfx.bus_volume_linear("SFX"), 0.65))
	assert(Sfx.music_player_count() == 2)

	for music_name in EXPECTED_MUSIC:
		Sfx.play_music(music_name)
		assert(Sfx.current_music == music_name)

	# 在静音总线下实际创建播放器，验证爆发操作不会超过 12 路且会自动回收。
	GameState.test_mode = false
	GameState.settings["music_volume"] = 0.0
	GameState.settings["sfx_volume"] = 0.0
	Sfx.apply_settings()
	Sfx.stop_all()
	Sfx.play_music("menu")
	await get_tree().process_frame
	assert(Sfx.playing_music_count() == 1)
	Sfx.play_music("day")
	await get_tree().create_timer(1.0, true).timeout
	assert(Sfx.current_music == "day")
	assert(Sfx.playing_music_count() == 1, "交叉淡入后应只保留一个音乐播放器")
	for sfx_name in EXPECTED_SFX:
		Sfx.play(sfx_name)
	assert(Sfx.active_effect_count() <= 12)
	assert(Sfx.active_effect_count() > 0)
	await get_tree().create_timer(2.0, true).timeout
	assert(Sfx.active_effect_count() == 0, "音效播放器未在播完后回收")

	GameState.test_mode = true
	GameState.settings["music_volume"] = 0.40
	GameState.settings["sfx_volume"] = 0.65
	Sfx.stop_all()
	assert(Sfx.current_music.is_empty())
	assert(Sfx.has_sfx("serve"), "stop_all 不应卸载缓存")
	assert(Sfx.has_music("night"), "stop_all 不应卸载音乐缓存")
	await get_tree().create_timer(0.5, true).timeout
	await get_tree().process_frame
	print("[AUDIO] passed sfx=%d music=%d buses=2 max_voices=12 cleanup=true" % [
		EXPECTED_SFX.size(), EXPECTED_MUSIC.size()])
	get_tree().quit()
