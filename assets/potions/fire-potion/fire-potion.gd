extends PotionBase

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		PlayerPotions.addPotion(potionType);
		queue_free()
