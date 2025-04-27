extends Area3D

@export var value = 1
@export var coinPickupAudio: AudioStreamPlayer3D;
@export var mesh: Node3D;

func _on_body_entered(body:Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		CollectablesEmitterService.emitMithrilPickedUp(value)
		hide_mesh();
		coinPickupAudio.play()
		await coinPickupAudio.finished
		queue_free()

func hide_mesh():
	mesh.visible = false
