extends AnimatableBody3D

var active := false

signal active_changed()

func activate() -> void:
	active = true

func get_hit() -> void:
	if !active:
		activate()

func _on_lever_animation_finished() -> void:
	active_changed.emit()
