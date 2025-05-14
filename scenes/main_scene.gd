extends Control

var level: int = 1
@onready var video_player_1 = $Room
@onready var video_player_2 = $Transition
@onready var video_player_3 = $Book
@onready var start_button = $Start/Start_Button

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(str("res://scenes/LvL 1.tscn"))

func _on_settings_pressed() -> void:
	$CenterContainer/MainButtons.visible = false
	$CenterContainer/SettingsMenu.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_back_pressed() -> void:
	$CenterContainer/MainButtons.visible = true
	$CenterContainer/SettingsMenu.visible = false

func _on_full_screen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func _on_main_vol_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value)

func _on_start_button_down() -> void:
	start_button.disabled = true
	start_button.visible = false
	video_player_1.stop()
	video_player_1.visible = false
	video_player_2.visible = true
	video_player_2.play()
	video_player_2.connect("finished", Callable(self, "_on_video_2_finished"))

func _on_video_2_finished():
	video_player_2.stop()
	video_player_2.visible = false
	video_player_3.visible = true
	video_player_3.loop = true
	video_player_3.play()
	$CenterContainer/MainButtons.visible = true
