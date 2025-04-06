extends Control

var level: int = 1

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(str("res://scenes/LvL 1.tscn"))
	

func _on_settings_pressed() -> void:
	$CenterContainer/MainButtons.visible = false;
	$CenterContainer/SettingsMenu.visible = true;

func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	$CenterContainer/MainButtons.visible = true;
	$CenterContainer/SettingsMenu.visible = false;

func _on_full_screen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else: 
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


func _on_main_vol_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value)
