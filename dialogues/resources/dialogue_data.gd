@tool
class_name DialogueData extends Resource

@export var lines: Array[DialogueLine] = []


func is_empty() -> bool:
	return lines.is_empty()


func is_valid() -> bool:
	return get_validation_errors().is_empty()


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()

	if lines.is_empty():
		errors.append("Dialogue must contain at least one line.")
		return errors

	for index in lines.size():
		var line := lines[index]
		if line == null:
			errors.append("Dialogue line %d is missing." % (index + 1))
			continue

		for line_error in line.get_validation_errors():
			errors.append("Dialogue line %d: %s" % [index + 1, line_error])

	return errors
