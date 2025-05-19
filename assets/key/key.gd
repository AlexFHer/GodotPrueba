extends Area3D

@export var KeyPickupAudio: AudioStreamPlayer3D;

@onready var _model: Node3D = $Model
@onready var _collision: CollisionShape3D = $CollisionShape3D

func take_key() -> void:
	PlayerInventory.add_key()
	KeyPickupAudio.play()
	remove_collsion()
	hide_mesh()
	await KeyPickupAudio.finished
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		take_key()

func remove_collsion() -> void:
	_collision.disabled = true 

func hide_mesh() -> void:
	_model.visible = false
