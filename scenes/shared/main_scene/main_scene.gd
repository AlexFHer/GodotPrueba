extends Control

var level: int = 1
@onready var video_player_1 = $Room
@onready var video_player_2 = $Transition
@onready var video_player_3 = $Book
@onready var start_button = $Start/Start_Button
@onready var play_button = $CenterContainer/MainButtons/PlayButton
@onready var otherPage = $OtherPage
@onready var settings_button = $CenterContainer/MainButtons/SettingsButton
@onready var exit_button = $CenterContainer/MainButtons/ExitButton
@onready var back_button = $CenterContainer/SettingsMenu/BackButton
@onready var fullscreen_check = $CenterContainer/SettingsMenu/FullScreenCheck
@onready var volume_slider = $CenterContainer/SettingsMenu/MainVolSlider
@onready var language_button = $CenterContainer/SettingsMenu/LanguageButton

func _ready():
	start_button.focus_mode = Control.FOCUS_ALL
	start_button.grab_focus()
	play_button.focus_mode = Control.FOCUS_ALL
	settings_button.focus_mode = Control.FOCUS_ALL
	exit_button.focus_mode = Control.FOCUS_ALL
	back_button.focus_mode = Control.FOCUS_ALL
	fullscreen_check.focus_mode = Control.FOCUS_ALL
	volume_slider.focus_mode = Control.FOCUS_ALL
	language_button.focus_mode = Control.FOCUS_ALL
	fullscreen_check.set_pressed_no_signal(GameSettings.fullscreen)
	volume_slider.set_value_no_signal(GameSettings.master_volume)
	_update_language_button()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_language_button()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level1/LvL 1.tscn")

func _on_settings_pressed() -> void:
	$CenterContainer/MainButtons.visible = false
	$OtherPage.visible = false
	$CenterContainer/SettingsMenu.visible = true
	back_button.grab_focus()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_back_pressed() -> void:
	$CenterContainer/MainButtons.visible = true
	$OtherPage.visible = true
	$CenterContainer/SettingsMenu.visible = false
	play_button.grab_focus()

func _on_full_screen_toggled(toggled_on: bool) -> void:
	GameSettings.set_fullscreen(toggled_on)

func _on_main_vol_slider_value_changed(value: float) -> void:
	GameSettings.set_master_volume(value)

func _on_language_button_pressed() -> void:
	var current_index := GameSettings.SUPPORTED_LANGUAGES.find(GameSettings.language)
	var next_index := (current_index + 1) % GameSettings.SUPPORTED_LANGUAGES.size()
	GameSettings.set_language(GameSettings.SUPPORTED_LANGUAGES[next_index])
	_update_language_button()

func _update_language_button() -> void:
	language_button.text = tr(GameSettings.language)

func _on_start_button_down() -> void:
	start_button.disabled = true
	start_button.visible = false
	video_player_1.stop()
	video_player_1.visible = false
	video_player_2.visible = true
	video_player_2.play()
	if not video_player_2.is_connected("finished", Callable(self, "_on_video_2_finished")):
		video_player_2.connect("finished", Callable(self, "_on_video_2_finished"))

func _on_video_2_finished():
	video_player_2.stop()
	video_player_2.visible = false
	video_player_3.visible = true
	video_player_3.loop = true
	video_player_3.play()
	$CenterContainer/MainButtons.visible = true
	$OtherPage.visible = true
	play_button.grab_focus()
