extends Control

@onready var resumeButton: Button = %ResumeButton;

signal resumeButtonClicked()

func _on_visibility_changed() -> void:
	if visible:
		_on_visible();

func _on_visible() -> void:
	resumeButton.grab_focus()

func _on_resume_button_pressed() -> void:
	resumeButtonClicked.emit()

func _on_main_menu_button_pressed() -> void:
	get_tree().quit()
