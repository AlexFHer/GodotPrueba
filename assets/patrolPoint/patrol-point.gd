class_name PatrolPoint extends Area3D

signal patrolPointReached()

func _on_body_entered(body:Node3D) -> void:
	print(body.name);
	print(body.get_groups())
	if body.is_in_group("CanPatrol"):
		patrolPointReached.emit()
