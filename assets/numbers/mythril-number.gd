extends Node3D

@export var model: Node3D

func _process(delta: float) -> void:
	# Find the player node by group
	var player = get_tree().get_nodes_in_group("MainPlayer")[0]
	if player == null:
		return
	
	# look at player
	var direction = (player.global_transform.origin - global_transform.origin).normalized()
	var newRotation = Vector3(0, direction.x, direction.z).normalized()
	model.look_at(player.global_transform.origin, Vector3.UP)
	# Rotate the model to face the player
	model.rotation = newRotation
	# Rotate the model to face the player
	model.rotation_degrees = Vector3(0, rotation.y, 0)
	# Rotate the model to face the player
