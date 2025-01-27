extends Area3D

signal torch_light_state_change

var isLighted = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("FireBall"):
		light();

func light() -> void:
	isLighted = true
	torch_light_state_change.emit(true)
