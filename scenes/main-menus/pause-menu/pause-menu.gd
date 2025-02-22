extends Control

@onready var resumeButton: Button = %ResumeButton;

signal exitPauseMenu;

var isPauseMenuVisible := false;


func _init() -> void:
	visible = false;

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start"):
		togglePauseState();
	
	if event.is_action_pressed("circle"):
		if isPauseMenuVisible:
			hidePauseMenu();
			resumeGame();

func togglePauseState() -> void:
	if isPauseMenuVisible:
		hidePauseMenu();
		resumeGame();
	else:
		showPauseMenu();
		pauseGame();

func pauseGame() -> void:
	get_tree().paused = true;

func resumeGame() -> void:
	get_tree().paused = false;

func showPauseMenu() -> void:
	visible = true;
	isPauseMenuVisible = true;
	resumeButton.grab_focus();

func hidePauseMenu() -> void:
	visible = false;
	isPauseMenuVisible = false;

func _on_resume_button_pressed() -> void:
	togglePauseState();

func _on_quit_button_pressed() -> void:
	get_tree().quit();
