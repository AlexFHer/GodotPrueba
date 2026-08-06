class_name DialogueUI
extends Control

@export_range(1.0, 200.0, 1.0, "or_greater") var characters_per_second := 40.0

@onready var _prompt_root: Control = %PromptRoot
@onready var _prompt_badge: Label = %PromptBadge
@onready var _prompt_prefix: Label = %PromptPrefix
@onready var _prompt_suffix: Label = %PromptSuffix
@onready var _dialogue_root: Control = %DialogueRoot
@onready var _speaker_label: Label = %SpeakerLabel
@onready var _dialogue_text: RichTextLabel = %DialogueText
@onready var _continue_root: Control = %ContinueRoot
@onready var _continue_badge: Label = %ContinueBadge
@onready var _continue_prefix: Label = %ContinuePrefix
@onready var _continue_suffix: Label = %ContinueSuffix

var _is_revealing := false
var _reveal_progress := 0.0
var _target_character_count := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_translations()
	hide_prompt()
	hide_dialogue()
	set_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_apply_translations()


func _process(delta: float) -> void:
	if not _is_revealing:
		return

	_reveal_progress += delta * characters_per_second
	_dialogue_text.visible_characters = mini(floori(_reveal_progress), _target_character_count)
	if _dialogue_text.visible_characters >= _target_character_count:
		finish_typewriter()


func show_prompt() -> void:
	if not _dialogue_root.visible:
		_prompt_root.show()


func hide_prompt() -> void:
	_prompt_root.hide()


func show_dialogue() -> void:
	hide_prompt()
	_dialogue_root.show()


func hide_dialogue() -> void:
	_dialogue_root.hide()
	_continue_root.hide()
	_is_revealing = false
	set_process(false)


func show_line(line: DialogueLine) -> void:
	show_dialogue()
	var localized_speaker := tr(line.speaker)
	_speaker_label.text = localized_speaker
	_speaker_label.visible = not localized_speaker.strip_edges().is_empty()
	_dialogue_text.text = tr(line.text)
	_dialogue_text.visible_characters = 0
	_dialogue_text.scroll_to_line(0)
	_target_character_count = _dialogue_text.get_total_character_count()
	_reveal_progress = 0.0
	_continue_root.hide()
	_is_revealing = _target_character_count > 0
	set_process(_is_revealing)
	if not _is_revealing:
		finish_typewriter()


func is_revealing_text() -> bool:
	return _is_revealing


func finish_typewriter() -> void:
	_is_revealing = false
	_dialogue_text.visible_characters = -1
	_continue_root.show()
	set_process(false)


func set_action_badge(badge_text: String) -> void:
	_prompt_badge.text = badge_text
	_continue_badge.text = badge_text


func _apply_translations() -> void:
	_apply_input_template(tr(&"dialogue_prompt_talk"), _prompt_prefix, _prompt_suffix)
	_apply_input_template(tr(&"dialogue_prompt_continue"), _continue_prefix, _continue_suffix)


func _apply_input_template(template: String, prefix_label: Label, suffix_label: Label) -> void:
	const INPUT_PLACEHOLDER := "{input}"
	var placeholder_index := template.find(INPUT_PLACEHOLDER)
	if placeholder_index < 0:
		# Keep the badge useful even if a translator accidentally removes {input}.
		prefix_label.text = ""
		suffix_label.text = template.strip_edges()
	else:
		prefix_label.text = template.left(placeholder_index).strip_edges()
		suffix_label.text = template.substr(placeholder_index + INPUT_PLACEHOLDER.length()).strip_edges()

	prefix_label.visible = not prefix_label.text.is_empty()
	suffix_label.visible = not suffix_label.text.is_empty()
