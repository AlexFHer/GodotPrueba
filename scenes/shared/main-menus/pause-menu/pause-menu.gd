extends Control

@onready var pauseMenuControls: Control = %"Pause menu controls"
@onready var settingsMenuControls: Control = %"Settings menu";

func _init() -> void:
	_set_self_visibility(false);

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		_set_self_visibility(true)
		_showPauseMenu();
		_pauseGame();

func _set_self_visibility(newVisibility: bool) -> void:
	visible = newVisibility

func _pauseGame() -> void:
	get_tree().paused = true;

func _resumeGame() -> void:
	get_tree().paused = false;

func _showPauseMenu() -> void:
	pauseMenuControls.visible = true;
	pauseMenuControls.process_mode = Node.PROCESS_MODE_ALWAYS;
	_hideSettingsMenu()

func _hidePauseMenu() -> void:
	pauseMenuControls.visible = false;
	pauseMenuControls.process_mode = Node.PROCESS_MODE_DISABLED;

func _showSettingsMenu() -> void:
	settingsMenuControls.visible = true;
	settingsMenuControls.process_mode = Node.PROCESS_MODE_ALWAYS;
	_hidePauseMenu();

func _hideSettingsMenu() -> void:
	settingsMenuControls.visible = false;
	settingsMenuControls.process_mode = Node.PROCESS_MODE_DISABLED;

func _on_pause_menu_controls_resume_button_clicked() -> void:
	_hidePauseMenu();
	_resumeGame();

func _on_settings_button_pressed() -> void:
	_hideSettingsMenu();
	_showSettingsMenu();

func _on_settings_menu_go_back_dispatch() -> void:
	_hideSettingsMenu();
	_showPauseMenu();
