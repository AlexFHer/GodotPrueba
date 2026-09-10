extends Node

const SETTINGS_SCRIPT := preload("res://shared/scripts/settings_manager.gd")
const EXPECTED_EUSKARA := {
	&"jump_potion_ui_text": "Jauzia",
	&"speed_potion_ui_text": "Abiadura",
	&"fire_potion_ui_text": "Sua",
	&"ui_play_button": "Jokatu",
	&"ui_resume_button": "Jarraitu",
	&"ui_settings_button": "Ezarpenak",
	&"ui_quit_button": "Irten",
	&"ui_main_menu_button": "Menu nagusia",
	&"ui_pause_title": "Pausatuta",
	&"ui_settings_title": "Ezarpenak",
	&"ui_master_volume": "Bolumen nagusia",
	&"ui_music_volume": "Musika",
	&"ui_sfx_volume": "Efektuak",
	&"ui_fullscreen": "Pantaila osoa",
	&"ui_language": "Hizkuntza",
	&"ui_back_button": "Atzera",
	&"ui_press_start": "SAKATU START",
	&"es": "Gaztelania",
	&"en": "Ingelesa",
	&"eu": "Euskara",
	&"dialogue_prompt_talk": "Sakatu {input} hitz egiteko",
	&"dialogue_prompt_continue": "Sakatu {input} jarraitzeko",
	&"npc_pocima_name": "Edabea",
	&"npc_pocima_intro_1": "Aizu, lagun",
	&"npc_pocima_intro_2": "Goiko kutxa ezkutu magiko batez estalita dagoela dirudi. Bilatu hura irekitzeko moduren bat.",
}

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if not ".localization-test-user" in OS.get_user_data_dir():
		push_error("Refusing to test against real user settings. Set isolated APPDATA first.")
		get_tree().quit(1)
		return

	_check(GameSettings.DEFAULT_LANGUAGE == "eu", "Euskara must be the default language")
	_check(GameSettings.language == "eu", "Fresh settings must start in Euskara")
	_check(GameSettings.SUPPORTED_LANGUAGES == ["eu", "es", "en"], "Supported language order must start with Euskara")

	_check(TranslationServer.get_loaded_locales().has("eu"), "Euskara translation resource must be loaded")
	TranslationServer.set_locale("eu")
	for key: StringName in EXPECTED_EUSKARA:
		_check(String(TranslationServer.translate(key)) == EXPECTED_EUSKARA[key], "Unexpected Euskara translation for %s" % key)

	GameSettings.set_language("es")
	GameSettings.save()
	var reloaded_settings: Node = SETTINGS_SCRIPT.new()
	get_tree().root.add_child(reloaded_settings)
	_check(reloaded_settings.language == "es", "An existing saved language choice must be preserved")
	reloaded_settings.queue_free()

	print("LOCALIZATION TEST: %d failures" % failures)
	get_tree().quit(1 if failures else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
