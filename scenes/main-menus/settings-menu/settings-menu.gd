extends Control

@onready var languageButton: Button = %LanguageButton

signal goBackDispatch;

const LANGUAGES = ["es", "en"];
var currentLang = "en";

func _ready() -> void:
	languageButton.text = currentLang;

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("circle"):
		goBackDispatch.emit()

func _on_language_button_pressed() -> void:
	var index = LANGUAGES.find(currentLang)
	if index == -1:
		return
	
	var next_index = (index + 1) % LANGUAGES.size()
	var nextLanguage = LANGUAGES[next_index]
	_changeLanguage(nextLanguage)

func _changeLanguage(newLang: String) -> void:
	currentLang = newLang;
	languageButton.text = newLang;
	TranslationServer.set_locale(newLang);

func _on_language_button_visibility_changed() -> void:
	if visible:
		_on_visible()
	
func _on_visible() -> void:
	languageButton.grab_focus();
