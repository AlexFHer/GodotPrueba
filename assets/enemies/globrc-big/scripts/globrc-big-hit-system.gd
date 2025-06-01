extends Area3D

signal got_hit()

func get_hit() -> void:
	got_hit.emit()