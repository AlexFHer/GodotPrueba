extends PotionBase

@export var potionPickupAudio: AudioStreamPlayer3D;

func _on_pick_up() -> void:
	PlayerPotions.addPotion(potionType);
	potionPickupAudio.play()
	await potionPickupAudio.finished
	queue_free()


func _on_body_entered(body:Node3D) -> void:
	_on_pick_up()
