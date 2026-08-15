## 正式包配置回归：四平台预设、移动端图标与 GLB 贴图嵌入策略。
extends Node

const PRESET_NAMES := ["macOS", "Windows Desktop", "Android", "iOS"]
const INCLUDE_FILTER := "OFL-1.1.txt,THIRD_PARTY_NOTICES.md"
const EXCLUDE_FILTER := "tests/*,assets/glb/shop_scene_tmp*,assets/glb/shop_scene_floor_coral_mint.png,assets/icons/app/*"
const ICON_SIZES := [40, 58, 60, 76, 80, 87, 114, 120, 128, 136, 152, 167, 180, 192, 1024]


func _ready() -> void:
	var presets := _read_text("res://export_presets.cfg")
	assert(not presets.is_empty(), "export_presets.cfg missing")
	for preset_name in PRESET_NAMES:
		assert(presets.contains('name="%s"' % preset_name), "missing export preset: " + preset_name)
	assert(presets.count("script_export_mode=2") == PRESET_NAMES.size(), "scripts must compile in every export")
	assert(presets.count('include_filter="%s"' % INCLUDE_FILTER) == PRESET_NAMES.size(), "third-party notices must ship in every export")
	assert(presets.count('exclude_filter="%s"' % EXCLUDE_FILTER) == PRESET_NAMES.size(), "resource exclusions diverged")
	assert(presets.contains('package/unique_name="com.milkteahouse.game"'))
	assert(presets.contains("architectures/arm64-v8a=true"))
	assert(presets.contains("architectures/armeabi-v7a=false"))
	assert(presets.contains('application/app_store_team_id="9AP4GA8W53"'))
	assert(presets.contains('application/bundle_identifier="com.milkteahouse.game"'))
	assert(presets.contains('icons/app_store_1024x1024="res://assets/icons/app/icon_1024.png"'))
	# 1.0 首发版本号（D8）：所有预设统一 1.0.0，不允许回退到 0.x。
	assert(presets.count('short_version="1.0.0"') + presets.count('version/name="1.0.0"') >= 3,
		"shipping version strings must read 1.0.0")
	assert(not presets.contains("0.1.0"), "stale 0.1.0 version strings must not ship")

	var ofl := _read_text("res://OFL-1.1.txt")
	assert(ofl.begins_with("Copyright 2021-2026 LXGW"), "LXGW copyright notice missing")
	assert(ofl.contains("Copyright 2020 The Klee Project Authors"), "Klee copyright notice missing")
	assert(ofl.contains("[ADDITIONAL PERMISSION]"), "LXGW additional permission missing")
	assert(ofl.contains("SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007"), "wrong OFL version")
	assert(ofl.contains("PERMISSION & CONDITIONS"), "OFL conditions missing")
	assert(ofl.contains("TERMINATION"), "OFL termination clause missing")
	assert(ofl.contains("THE FONT SOFTWARE IS PROVIDED \"AS IS\""), "OFL disclaimer missing")
	var notices := _read_text("res://THIRD_PARTY_NOTICES.md")
	assert(notices.contains("LXGW WenKai / 霞鹜文楷"), "font notice missing")
	assert(notices.contains("res://assets/fonts/LXGWWenKai-Regular.ttf"), "runtime font path missing from notice")
	assert(notices.contains("OFL-1.1.txt"), "font notice must link the complete license")

	assert(bool(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false)))
	assert(int(ProjectSettings.get_setting("display/window/handheld/orientation", -1)) == 4,
		"mobile exports must allow both landscape orientations")
	assert(String(ProjectSettings.get_setting("application/config/icon", "")) == "res://assets/icons/app/icon_1024.png")
	var translations: PackedStringArray = ProjectSettings.get_setting("internationalization/locale/translations", PackedStringArray())
	assert(translations.has("res://localization/ui.en.translation"), "English translation resource missing from project")
	assert(translations.has("res://localization/ui.zh_CN.translation"), "Chinese translation resource missing from project")
	assert(FileAccess.file_exists("res://localization/ui.csv"), "translation source CSV missing")
	var shop_import := _read_text("res://assets/glb/shop_scene.glb.import")
	assert(shop_import.contains("gltf/embedded_image_handling=2"), "shop GLB must embed Basis Universal textures")

	for size in ICON_SIZES:
		var path := "res://assets/icons/app/icon_%d.png" % size
		assert(FileAccess.file_exists(path), "missing app icon: " + path)
		var texture := load(path) as Texture2D
		assert(texture != null, "app icon failed to load: " + path)
		assert(texture.get_width() == size and texture.get_height() == size, "wrong app icon dimensions: " + path)
	var master_icon := (load("res://assets/icons/app/icon_1024.png") as Texture2D).get_image()
	assert(master_icon.get_format() == Image.FORMAT_RGB8, "App Store icon must be opaque RGB")

	print("[EXPORT_CONFIG] passed presets=4 compiled_scripts=true notices=4 exclusions=4 android=arm64 ios_icons=%d basisu=true locales=2" % ICON_SIZES.size())
	Sfx.stop_all()
	await get_tree().process_frame
	get_tree().quit()


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "failed to read: " + path)
	var content := file.get_as_text()
	file.close()
	return content
