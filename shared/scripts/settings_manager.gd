extends Node

const SETTINGS_PATH := "user://saves/settings.cfg"
const AUDIO_SECTION := "audio"
const DISPLAY_SECTION := "display"
const LANGUAGE_SECTION := "language"
const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const SUPPORTED_LANGUAGES := ["es", "en"]
const SAVE_DELAY_SECONDS := 0.25

var master_volume := 1.0
var music_volume := 1.0
var sfx_volume := 1.0
var fullscreen := false
var language := "en"

var _save_timer: Timer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_save_timer()
	language = _get_default_language()
	fullscreen = _is_window_fullscreen()
	var settings_loaded := _load_settings()
	_apply_audio_settings()
	TranslationServer.set_locale(language)
	if settings_loaded:
		_apply_fullscreen()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume(MASTER_BUS, master_volume)
	_queue_save()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume(MUSIC_BUS, music_volume)
	_queue_save()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume(SFX_BUS, sfx_volume)
	_queue_save()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_fullscreen()
	_queue_save()


func set_language(locale: String) -> void:
	if not SUPPORTED_LANGUAGES.has(locale):
		return
	language = locale
	TranslationServer.set_locale(language)
	_queue_save()


func save() -> void:
	if _save_timer != null:
		_save_timer.stop()

	var config := ConfigFile.new()
	config.set_value(AUDIO_SECTION, "master_volume", master_volume)
	config.set_value(AUDIO_SECTION, "music_volume", music_volume)
	config.set_value(AUDIO_SECTION, "sfx_volume", sfx_volume)
	config.set_value(DISPLAY_SECTION, "fullscreen", fullscreen)
	config.set_value(LANGUAGE_SECTION, "locale", language)

	var error := config.save(SETTINGS_PATH)
	if error != OK:
		GameLog.error("Failed to save settings: %s" % error_string(error))


func _create_save_timer() -> void:
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DELAY_SECONDS
	_save_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_save_timer.timeout.connect(save)
	add_child(_save_timer)


func _queue_save() -> void:
	if _save_timer != null:
		_save_timer.start()


func _load_settings() -> bool:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return false
	if error != OK:
		GameLog.warn("Failed to load settings: %s" % error_string(error))
		return false

	master_volume = clampf(
		float(config.get_value(AUDIO_SECTION, "master_volume", master_volume)),
		0.0,
		1.0
	)
	music_volume = clampf(
		float(config.get_value(AUDIO_SECTION, "music_volume", music_volume)),
		0.0,
		1.0
	)
	sfx_volume = clampf(
		float(config.get_value(AUDIO_SECTION, "sfx_volume", sfx_volume)),
		0.0,
		1.0
	)
	fullscreen = bool(config.get_value(DISPLAY_SECTION, "fullscreen", fullscreen))
	var saved_language := String(config.get_value(LANGUAGE_SECTION, "locale", language))
	if SUPPORTED_LANGUAGES.has(saved_language):
		language = saved_language
	return true


func _apply_audio_settings() -> void:
	_set_bus_volume(MASTER_BUS, master_volume)
	_set_bus_volume(MUSIC_BUS, music_volume)
	_set_bus_volume(SFX_BUS, sfx_volume)


func _set_bus_volume(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		GameLog.warn("Audio bus not found: %s" % bus_name)
		return
	AudioServer.set_bus_volume_linear(bus_index, value)


func _apply_fullscreen() -> void:
	if DisplayServer.get_name().to_lower() == "headless":
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		if fullscreen
		else DisplayServer.WINDOW_MODE_MAXIMIZED
	)


func _is_window_fullscreen() -> bool:
	if DisplayServer.get_name().to_lower() == "headless":
		return false
	var mode := DisplayServer.window_get_mode()
	return (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)


func _get_default_language() -> String:
	var locale := TranslationServer.get_locale().left(2).to_lower()
	return locale if SUPPORTED_LANGUAGES.has(locale) else "en"
