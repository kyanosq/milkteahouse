## 全局音频导演：原创场景音乐、分步骤反馈音效、双总线混音和安全并发控制。
extends Node

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const MAX_EFFECTS := 12
const CROSSFADE_SECONDS := 0.8
const SILENT_DB := -60.0

const SFX_NAMES := [
	"bad", "coin", "combo", "customer_arrive", "customer_leave", "discover",
	"lab_stir", "pour_milk", "pour_tea", "seal", "select", "serve", "shake",
	"staff_alert", "staff_wake", "sugar", "topping", "ui_close", "ui_open",
]
const MUSIC_PATHS := {
	"menu": "res://assets/music/menu_teahouse.ogg",
	"day": "res://assets/music/day_coral_market.ogg",
	"night": "res://assets/music/night_mint_lab.ogg",
	"campaign": "res://assets/music/campaign_cup_of_stars.ogg",
}
const COOLDOWNS_MS := {
	"shake": 70,
	"select": 45,
	"topping": 70,
	"coin": 90,
	"customer_arrive": 120,
}
const DUCKING := {
	"bad": [0.38, 0.46],
	"discover": [0.72, 0.58],
	"combo": [0.48, 0.48],
	"staff_alert": [0.42, 0.44],
}

var current_music := ""

var _sfx_streams: Dictionary = {}
var _music_streams: Dictionary = {}
var _music_players: Array[AudioStreamPlayer] = []
var _effect_players: Array[AudioStreamPlayer] = []
var _last_play_ms: Dictionary = {}
var _active_deck := -1
var _music_fade: Tween
var _duck_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	_load_streams()
	_build_music_decks()
	apply_settings()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)


func _load_streams() -> void:
	for sfx_name in SFX_NAMES:
		var path := "res://assets/sfx/%s.wav" % sfx_name
		if ResourceLoader.exists(path):
			_sfx_streams[sfx_name] = load(path)
	for music_name in MUSIC_PATHS:
		var path: String = MUSIC_PATHS[music_name]
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream is AudioStreamOggVorbis:
				stream.loop = true
			_music_streams[music_name] = stream


func _build_music_decks() -> void:
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "MusicDeck%d" % (i + 1)
		player.bus = MUSIC_BUS
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.volume_db = SILENT_DB
		add_child(player)
		_music_players.append(player)


func apply_settings() -> void:
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = null
	_set_bus_linear(MUSIC_BUS, GameState.music_volume())
	_set_bus_linear(SFX_BUS, GameState.sfx_volume())


func _set_bus_linear(bus_name: String, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var level := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(index, level <= 0.0001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.0001)))


func play_music(music_name: String) -> void:
	if not _music_streams.has(music_name):
		return
	if current_music == music_name:
		return
	current_music = music_name
	if GameState.test_mode:
		return
	if _music_players.size() < 2:
		_build_music_decks()
	apply_settings()
	var next_deck := 0 if _active_deck == 1 else 1
	var incoming := _music_players[next_deck]
	var outgoing: AudioStreamPlayer = _music_players[_active_deck] if _active_deck >= 0 else null
	if _music_fade != null and _music_fade.is_valid():
		_music_fade.kill()
	var stream: AudioStream = _music_streams[music_name]
	incoming.stop()
	incoming.stream = stream
	incoming.volume_linear = 0.0
	incoming.play()
	_music_fade = create_tween().set_parallel(true)
	_music_fade.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_music_fade.tween_property(incoming, "volume_linear", 1.0, CROSSFADE_SECONDS)
	if outgoing != null and outgoing.playing:
		_music_fade.tween_property(outgoing, "volume_linear", 0.0, CROSSFADE_SECONDS)
		_music_fade.finished.connect(_finish_crossfade.bind(outgoing, incoming), CONNECT_ONE_SHOT)
	_active_deck = next_deck


func _finish_crossfade(outgoing: AudioStreamPlayer, incoming: AudioStreamPlayer) -> void:
	if is_instance_valid(outgoing) and outgoing != incoming:
		outgoing.stop()
		outgoing.stream = null


func play(sfx_name: String, pitch: float = 1.0) -> void:
	if GameState.test_mode or not _sfx_streams.has(sfx_name):
		return
	var now := Time.get_ticks_msec()
	var cooldown := int(COOLDOWNS_MS.get(sfx_name, 0))
	if cooldown > 0 and now - int(_last_play_ms.get(sfx_name, -cooldown)) < cooldown:
		return
	_last_play_ms[sfx_name] = now
	_prune_effects()
	while _effect_players.size() >= MAX_EFFECTS:
		_discard_effect(_effect_players[0])
	var player := AudioStreamPlayer.new()
	player.name = "Sfx_%s" % sfx_name
	player.bus = SFX_BUS
	player.stream = _sfx_streams[sfx_name]
	player.pitch_scale = clampf(pitch, 0.5, 2.0)
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	_effect_players.append(player)
	player.finished.connect(_on_effect_finished.bind(player), CONNECT_ONE_SHOT)
	player.play()
	if DUCKING.has(sfx_name):
		var duck: Array = DUCKING[sfx_name]
		duck_music(float(duck[0]), float(duck[1]))


func duck_music(duration: float, amount: float = 0.45) -> void:
	if GameState.test_mode:
		return
	var index := AudioServer.get_bus_index(MUSIC_BUS)
	if index < 0 or GameState.music_volume() <= 0.0001:
		return
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	var base_db := linear_to_db(GameState.music_volume())
	var duck_db := linear_to_db(maxf(GameState.music_volume() * clampf(amount, 0.1, 1.0), 0.0001))
	AudioServer.set_bus_volume_db(index, duck_db)
	_duck_tween = create_tween()
	_duck_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_duck_tween.tween_interval(maxf(duration, 0.05))
	_duck_tween.tween_method(_set_music_bus_db, duck_db, base_db, 0.24)


func _set_music_bus_db(value: float) -> void:
	var index := AudioServer.get_bus_index(MUSIC_BUS)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, value)


func _prune_effects() -> void:
	for player in _effect_players.duplicate():
		if not is_instance_valid(player) or player.is_queued_for_deletion():
			_effect_players.erase(player)


func _discard_effect(player: AudioStreamPlayer) -> void:
	_effect_players.erase(player)
	if is_instance_valid(player):
		player.stop()
		player.stream = null
		player.queue_free()


func _on_effect_finished(player: AudioStreamPlayer) -> void:
	_effect_players.erase(player)
	if is_instance_valid(player):
		player.stream = null
		player.queue_free()


func stop_all() -> void:
	if _music_fade != null and _music_fade.is_valid():
		_music_fade.kill()
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()
	for player in _effect_players.duplicate():
		_discard_effect(player)
	_effect_players.clear()
	for player in _music_players.duplicate():
		if is_instance_valid(player):
			player.stop()
			player.stream = null
			player.free()
	_music_players.clear()
	_active_deck = -1
	current_music = ""
	apply_settings()


## Exported-build smoke path: release audio first, then release the full scene from
## this persistent autoload before quitting. This avoids false leak warnings caused
## by the engine's hard --quit-after switch while remaining unreachable in play.
func finish_export_smoke() -> void:
	await get_tree().process_frame
	stop_all()
	var scene := get_tree().current_scene
	if is_instance_valid(scene):
		scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("[EXPORT_SMOKE] clean startup/shutdown")
	get_tree().quit()


func has_sfx(sfx_name: String) -> bool:
	return _sfx_streams.has(sfx_name)


func has_music(music_name: String) -> bool:
	return _music_streams.has(music_name)


func active_effect_count() -> int:
	_prune_effects()
	return _effect_players.size()


func music_player_count() -> int:
	return _music_players.size()


func playing_music_count() -> int:
	var count := 0
	for player in _music_players:
		if is_instance_valid(player) and player.playing:
			count += 1
	return count


func bus_volume_linear(bus_name: String) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0 or AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))
