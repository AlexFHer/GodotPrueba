extends Area3D

func _on_body_entered(body:Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		if body.has_method("get_hit"):
			body.get_hit()
		if body.has_method("get_to_checkpoint"):
			body.get_to_checkpoint()
