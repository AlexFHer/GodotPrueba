extends PotionBase

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("MainPlayer"):
		print("potion type", potionType)
		PlayerPotions.addPotion(potionType);
		queue_free()
