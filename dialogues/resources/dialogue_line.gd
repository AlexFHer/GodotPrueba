@tool
class_name DialogueLine extends Resource

@export var speaker: String = ""
@export_multiline var text: String = ""
## Optional non-positional clip played once when this line is shown.
@export var voice_stream: AudioStream


func is_valid() -> bool:
	return not text.strip_edges().is_empty()


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()

	if text.strip_edges().is_empty():
		errors.append("Dialogue text cannot be empty.")

	return errors
