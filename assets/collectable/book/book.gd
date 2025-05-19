extends Area3D

@export var bookPickupAudio: AudioStreamPlayer3D;

@onready var _model: Node3D = $Model;
@onready var _collision: CollisionShape3D = $CollisionShape3D

func _on_body_entered(body:Node3D) -> void:
  if body.is_in_group("MainPlayer"):
    CollectablesEmitterService.emitBooksPickedUp(1)
    remove_collsion()
    hide_mesh()
    bookPickupAudio.play()
    await bookPickupAudio.finished
    queue_free()

func remove_collsion() -> void:
  _collision.disabled = true

func hide_mesh() -> void:
  _model.visible = false
