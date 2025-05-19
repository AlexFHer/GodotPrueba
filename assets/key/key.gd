extends Area3D

@export var KeyPickupAudio: AudioStreamPlayer3D;

func take_key() -> void:
	PlayerInventory.add_key()
	KeyPickupAudio.play()
	await KeyPickupAudio.finished
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		take_key()
