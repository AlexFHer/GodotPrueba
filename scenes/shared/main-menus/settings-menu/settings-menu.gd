extends Control

signal goBackDispatch

const LANGUAGES := ["es", "en"]

@onready var masterVolumeSlider: HSlider = %MasterVolumeSlider
@onready var musicVolumeSlider: HSlider = %MusicVolumeSlider
@onready var sfxVolumeSlider: HSlider = %SfxVolumeSlider
@onready var masterValueLabel: Label = %MasterValueLabel
@onready var musicValueLabel: Label = %MusicValueLabel
@onready var sfxValueLabel: Label = %SfxValueLabel
@onready var fullscreenCheck: CheckButton = %FullscreenCheck
@onready var languageButton: Button = %LanguageButton
@onready var backButton: Button = %BackButton

var _is_syncing_controls := false


func _ready() -> void:
	_sync_controls()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("circle") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()


func _sync_controls() -> void:
	_is_syncing_controls = true
	masterVolumeSlider.set_value_no_signal(GameSettings.master_volume)
	musicVolumeSlider.set_value_no_signal(GameSettings.music_volume)
	sfxVolumeSlider.set_value_no_signal(GameSettings.sfx_volume)
	fullscreenCheck.set_pressed_no_signal(GameSettings.fullscreen)
	languageButton.text = tr(GameSettings.language)
	_update_volume_label(masterValueLabel, GameSettings.master_volume)
	_update_volume_label(musicValueLabel, GameSettings.music_volume)
	_update_volume_label(sfxValueLabel, GameSettings.sfx_volume)
	_is_syncing_controls = false


func _on_master_volume_changed(value: float) -> void:
	_update_volume_label(masterValueLabel, value)
	if not _is_syncing_controls:
		GameSettings.set_master_volume(value)


func _on_music_volume_changed(value: float) -> void:
	_update_volume_label(musicValueLabel, value)
	if not _is_syncing_controls:
		GameSettings.set_music_volume(value)


func _on_sfx_volume_changed(value: float) -> void:
	_update_volume_label(sfxValueLabel, value)
	if not _is_syncing_controls:
		GameSettings.set_sfx_volume(value)


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if not _is_syncing_controls:
		GameSettings.set_fullscreen(toggled_on)


func _on_language_button_pressed() -> void:
	var current_index := LANGUAGES.find(GameSettings.language)
	var next_index := (current_index + 1) % LANGUAGES.size()
	GameSettings.set_language(LANGUAGES[next_index])
	languageButton.text = tr(GameSettings.language)


func _on_back_button_pressed() -> void:
	_go_back()


func _on_visibility_changed() -> void:
	if visible and is_node_ready():
		_sync_controls()
		masterVolumeSlider.grab_focus()


func _go_back() -> void:
	GameSettings.save()
	goBackDispatch.emit()


func _update_volume_label(label: Label, value: float) -> void:
	label.text = "%d%%" % roundi(value * 100.0)
