extends Area3D

@export var bookPickupAudio: AudioStreamPlayer3D;

func _on_body_entered(body:Node3D) -> void:
  if body.is_in_group("MainPlayer"):
    CollectablesEmitterService.emitBooksPickedUp(1)
  bookPickupAudio.play()
  await bookPickupAudio.finished
  queue_free()


