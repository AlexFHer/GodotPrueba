class_name Baby extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body is MainPlayer:
		queue_free()
